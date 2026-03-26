import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/auth/controllers/auth_controller.dart';
import 'package:app_saku_rapi/features/budget/controllers/budget_controller.dart';
import 'package:app_saku_rapi/features/budget/models/budget_model.dart';
import 'package:app_saku_rapi/features/budget/view/widgets/budget_group_card.dart';
import 'package:app_saku_rapi/features/budget/view/widgets/budget_summary_card.dart';
import 'package:app_saku_rapi/features/notification/controllers/budget_alert_checker.dart';
import 'package:app_saku_rapi/features/notification/controllers/notification_controller.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:app_saku_rapi/global/widgets/main_shell_page.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:app_saku_rapi/global/widgets/saku_empty_state.dart';
import 'package:app_saku_rapi/global/widgets/saku_error_state.dart';
import 'package:app_saku_rapi/global/widgets/saku_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// Halaman anggaran / budgeting (tab ketiga bottom nav).
///
/// Menampilkan ringkasan gauge, tab berdasarkan period type,
/// dan daftar budget dengan parent-child grouping.
class BudgetPage extends ConsumerStatefulWidget {
  const BudgetPage({super.key});

  @override
  ConsumerState<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends ConsumerState<BudgetPage>
    with TickerProviderStateMixin {
  static const _budgetTabIndex = 2;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final status = ref.read(budgetControllerProvider).status;
      if (status == BudgetStatus.initial) {
        ref.read(budgetControllerProvider.notifier).loadBudgets();
      }

      // Listen budget state → check budget alerts after load.
      ref.listenManual(budgetControllerProvider, (prev, next) {
        if (prev?.status != BudgetStatus.loaded &&
            next.status == BudgetStatus.loaded) {
          _checkBudgetAlerts(next);
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  /// Cek budget alerts setelah budget list berhasil di-load.
  void _checkBudgetAlerts(BudgetState budgetState) {
    final checker = ref.read(budgetAlertCheckerProvider);
    final budgetAlertEnabled = ref.read(isBudgetAlertEnabledProvider);
    final l10n = context.l10n;

    checker.checkBudgets(
      budgetState: budgetState,
      budgetAlertEnabled: budgetAlertEnabled,
      l10n: l10n,
    );
  }

  void _syncTabController(List<BudgetPeriodType> types) {
    final currentLength = _tabController?.length ?? 0;
    if (currentLength != types.length) {
      _tabController?.dispose();
      if (types.isNotEmpty) {
        _tabController = TabController(length: types.length, vsync: this);
        _tabController!.addListener(() {
          if (!_tabController!.indexIsChanging) {
            final type = types[_tabController!.index];
            ref
                .read(budgetControllerProvider.notifier)
                .setSelectedPeriodType(type);
          }
        });
      } else {
        _tabController = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final budgetState = ref.watch(budgetControllerProvider);
    final periodTypes = ref.watch(budgetAvailablePeriodTypesProvider);

    // Sync tab controller when period types change
    _syncTabController(periodTypes);

    // Auto-refresh saat kembali ke tab Budget
    ref.listen<int>(currentTabIndexProvider, (prev, next) {
      if (next == _budgetTabIndex && prev != _budgetTabIndex) {
        ref.read(budgetControllerProvider.notifier).refresh();
      }
    });

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        title: Text(
          l10n.budgetTitle,
          style: TextStyleConstants.h6.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          _WalletFilterButton(),
          SizedBox(width: 8.w),
        ],
        bottom: periodTypes.length > 1 && _tabController != null
            ? PreferredSize(
                preferredSize: Size.fromHeight(40.h),
                child: _PeriodTabBar(
                  controller: _tabController!,
                  types: periodTypes,
                ),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(budgetControllerProvider.notifier).refresh(),
        child: _buildBody(budgetState, periodTypes),
      ),
    );
  }

  Widget _buildBody(
    BudgetState budgetState,
    List<BudgetPeriodType> periodTypes,
  ) {
    final l10n = context.l10n;

    switch (budgetState.status) {
      case BudgetStatus.initial:
      case BudgetStatus.loading:
        return const Center(child: SakuLoadingIndicator());

      case BudgetStatus.error:
        return Center(
          child: SakuErrorState(
            message: budgetState.errorMessage ?? '',
            onRetry: () =>
                ref.read(budgetControllerProvider.notifier).loadBudgets(),
          ),
        );

      case BudgetStatus.loaded:
        final filteredBudgets = ref.watch(budgetFilteredListProvider);
        if (filteredBudgets.isEmpty && budgetState.budgets.isEmpty) {
          return _buildEmptyState(l10n);
        }

        if (periodTypes.length > 1 && _tabController != null) {
          return TabBarView(
            controller: _tabController,
            children: periodTypes
                .map(
                  (type) => _BudgetPeriodList(
                    periodType: type,
                    onAdd: () => _openBudgetForm(null),
                    onTapBudget: (b) => _navigateToDetail(b),
                    onNavigateCompleted: () => _navigateToCompleted(),
                  ),
                )
                .toList(),
          );
        }

        // Single or no period type
        return _BudgetPeriodList(
          periodType: periodTypes.isNotEmpty ? periodTypes.first : null,
          onAdd: () => _openBudgetForm(null),
          onTapBudget: (b) => _navigateToDetail(b),
          onNavigateCompleted: () => _navigateToCompleted(),
        );
    }
  }

  Widget _buildEmptyState(dynamic l10n) {
    return ListView(
      children: [
        SizedBox(height: 80.h),
        SakuEmptyState(
          icon: FontAwesomeIcons.chartPie,
          title: l10n.budgetEmpty,
          message: l10n.budgetEmptyHint,
        ),
        SizedBox(height: 24.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w),
          child: SakuButton(
            text: l10n.budgetAdd,
            onPressed: () => _openBudgetForm(null),
          ),
        ),
      ],
    );
  }

  // ───────────────── Navigation ─────────────────

  void _navigateToDetail(BudgetModel budget) {
    context.push(AppRouter.budgetDetail, extra: budget);
  }

  void _navigateToCompleted() {
    context.push(AppRouter.budgetCompleted);
  }

  Future<void> _openBudgetForm(BudgetModel? existing) async {
    final result = await context.push<dynamic>(
      AppRouter.budgetForm,
      extra: existing,
    );

    if (result == null || !mounted) return;

    final data = result as Map<String, dynamic>;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final l10n = context.l10n;
    final controller = ref.read(budgetControllerProvider.notifier);
    final periodType =
        data['periodType'] as BudgetPeriodType? ?? BudgetPeriodType.monthly;

    if (existing == null) {
      await _handleCreate(data, user.id, controller, l10n, periodType);
    } else {
      final updateResult = await controller.updateBudget(
        existing: existing,
        categoryId: data['categoryId'] as String,
        walletId: data['walletId'] as String?,
        amount: data['amount'] as double,
        startDate: data['startDate'] as DateTime,
        endDate: data['endDate'] as DateTime,
        isRecurring: data['isRecurring'] as bool,
        periodType: periodType,
      );

      if (!mounted) return;
      if (updateResult.isSuccess()) {
        context.showAppAlert(
          l10n.budgetSuccessEdit,
          alertType: AlertTypeEnum.success,
        );
      } else {
        final (message, _, _, _) = updateResult.dataError()!;
        context.showAppAlert(message, alertType: AlertTypeEnum.error);
      }
    }
  }

  Future<void> _handleCreate(
    Map<String, dynamic> data,
    String userId,
    BudgetController controller,
    dynamic l10n,
    BudgetPeriodType periodType,
  ) async {
    final categoryId = data['categoryId'] as String;
    final walletId = data['walletId'] as String?;
    final amount = data['amount'] as double;
    final startDate = data['startDate'] as DateTime;
    final endDate = data['endDate'] as DateTime;
    final isRecurring = data['isRecurring'] as bool;

    final duplicateId = await controller.findDuplicateBudgetId(
      categoryId: categoryId,
      walletId: walletId,
      startDate: startDate,
      endDate: endDate,
    );

    if (!mounted) return;

    if (duplicateId != null) {
      final categoryName = data['categoryName'] as String? ?? '';
      final walletName = data['walletName'] as String? ?? l10n.budgetFilterAll;

      final confirmed = await context.showConfirmDialog(
        title: l10n.budgetDuplicateTitle,
        message: l10n.budgetDuplicateMessage(categoryName, walletName),
        confirmLabel: l10n.budgetDuplicateReplace,
        cancelLabel: l10n.budgetDuplicateKeep,
      );

      if (confirmed != true || !mounted) return;

      final replaceResult = await controller.replaceBudget(
        oldBudgetId: duplicateId,
        userId: userId,
        categoryId: categoryId,
        walletId: walletId,
        amount: amount,
        startDate: startDate,
        endDate: endDate,
        isRecurring: isRecurring,
        periodType: periodType,
      );

      if (!mounted) return;
      if (replaceResult.isSuccess()) {
        context.showAppAlert(
          l10n.budgetSuccessAdd,
          alertType: AlertTypeEnum.success,
        );
      } else {
        final (message, _, _, _) = replaceResult.dataError()!;
        context.showAppAlert(message, alertType: AlertTypeEnum.error);
      }
    } else {
      final createResult = await controller.createBudget(
        userId: userId,
        categoryId: categoryId,
        walletId: walletId,
        amount: amount,
        startDate: startDate,
        endDate: endDate,
        isRecurring: isRecurring,
        periodType: periodType,
      );

      if (!mounted) return;
      if (createResult.isSuccess()) {
        context.showAppAlert(
          l10n.budgetSuccessAdd,
          alertType: AlertTypeEnum.success,
        );
      } else {
        final (message, _, _, _) = createResult.dataError()!;
        context.showAppAlert(message, alertType: AlertTypeEnum.error);
      }
    }
  }
}

// ═══════════════════════════════════════════════════
// Period Tab Bar
// ═══════════════════════════════════════════════════

class _PeriodTabBar extends StatelessWidget {
  const _PeriodTabBar({required this.controller, required this.types});

  final TabController controller;
  final List<BudgetPeriodType> types;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return TabBar(
      controller: controller,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelColor: colors.primary,
      unselectedLabelColor: colors.textSecondary,
      indicatorColor: colors.primary,
      labelStyle: TextStyleConstants.b2.copyWith(fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyleConstants.b2,
      tabs: types.map((t) => Tab(text: _periodLabel(t, context))).toList(),
    );
  }

  String _periodLabel(BudgetPeriodType type, BuildContext context) {
    final l10n = context.l10n;
    return switch (type) {
      BudgetPeriodType.weekly => l10n.budgetTabWeekly,
      BudgetPeriodType.monthly => l10n.budgetTabMonthly,
      BudgetPeriodType.quarterly => l10n.budgetTabQuarterly,
      BudgetPeriodType.yearly => l10n.budgetTabYearly,
      BudgetPeriodType.custom => l10n.budgetTabCustom,
    };
  }
}

// ═══════════════════════════════════════════════════
// Budget Period List (content of each tab)
// ═══════════════════════════════════════════════════

class _BudgetPeriodList extends ConsumerWidget {
  const _BudgetPeriodList({
    this.periodType,
    required this.onAdd,
    required this.onTapBudget,
    required this.onNavigateCompleted,
  });

  final BudgetPeriodType? periodType;
  final VoidCallback onAdd;
  final void Function(BudgetModel) onTapBudget;
  final VoidCallback onNavigateCompleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final allBudgets = ref.watch(budgetFilteredListProvider);

    // Filter by period type
    final budgets = periodType != null
        ? allBudgets.where((b) => b.periodType == periodType).toList()
        : allBudgets;

    // Group budgets by parent-child
    final groups = _buildGroups(budgets);

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      children: [
        SizedBox(height: 8.h),

        // Summary Card
        const BudgetSummaryCard(),
        SizedBox(height: 20.h),

        // Add Budget Button
        SakuButton(text: l10n.budgetAdd, onPressed: onAdd),
        SizedBox(height: 20.h),

        // Budget Groups
        if (groups.isNotEmpty) ...[
          Text(
            l10n.budgetActiveBudgets,
            style: TextStyleConstants.h7.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          ...groups.map(
            (group) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: BudgetGroupCard(group: group, onTap: onTapBudget),
            ),
          ),
        ] else ...[
          SizedBox(height: 20.h),
          SakuEmptyState(
            icon: FontAwesomeIcons.chartPie,
            title: l10n.budgetEmpty,
            message: l10n.budgetEmptyHint,
          ),
        ],

        SizedBox(height: 16.h),

        // Link to Completed Budgets Page
        InkWell(
          onTap: onNavigateCompleted,
          borderRadius: BorderRadius.circular(8.r),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.clockRotateLeft,
                  size: 14.w,
                  color: colors.textSecondary,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    l10n.budgetCompletedTitle,
                    style: TextStyleConstants.b1.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                FaIcon(
                  FontAwesomeIcons.chevronRight,
                  size: 12.w,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 24.h),
      ],
    );
  }

  /// Group budgets by parent-child category relationships.
  List<BudgetGroup> _buildGroups(List<BudgetModel> budgets) {
    final groups = <BudgetGroup>[];
    final usedIds = <String>{};

    // Find parent budgets (category.parentId == null)
    final parents = budgets.where((b) => b.category?.parentId == null);

    for (final parent in parents) {
      usedIds.add(parent.id);

      // Find children: budgets whose category.parentId == parent's categoryId
      final children = budgets
          .where(
            (b) =>
                b.id != parent.id && b.category?.parentId == parent.categoryId,
          )
          .toList();
      for (final c in children) {
        usedIds.add(c.id);
      }

      groups.add(BudgetGroup(parent: parent, children: children));
    }

    // Remaining budgets that weren't grouped (child without parent budget)
    for (final b in budgets) {
      if (!usedIds.contains(b.id)) {
        groups.add(BudgetGroup(parent: b));
      }
    }

    return groups;
  }
}

// ═══════════════════════════════════════════════════
// Wallet Filter Button (AppBar Action)
// ═══════════════════════════════════════════════════

class _WalletFilterButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final wallets = ref.watch(walletListProvider);
    final budgetState = ref.watch(budgetControllerProvider);
    final selectedWalletId = budgetState.walletFilter;

    final selectedLabel = selectedWalletId == null
        ? l10n.budgetFilterAll
        : wallets.where((w) => w.id == selectedWalletId).firstOrNull?.name ??
              l10n.budgetFilterAll;

    return PopupMenuButton<String?>(
      onSelected: (walletId) {
        ref.read(budgetControllerProvider.notifier).setWalletFilter(walletId);
      },
      offset: Offset(0, 40.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      color: colors.surface,
      itemBuilder: (context) => [
        PopupMenuItem<String?>(
          value: null,
          child: Row(
            children: [
              FaIcon(
                FontAwesomeIcons.wallet,
                size: 14.w,
                color: selectedWalletId == null
                    ? colors.primary
                    : colors.textSecondary,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  l10n.budgetFilterAll,
                  style: TextStyleConstants.b2.copyWith(
                    color: selectedWalletId == null
                        ? colors.primary
                        : colors.textPrimary,
                    fontWeight: selectedWalletId == null
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (selectedWalletId == null)
                FaIcon(
                  FontAwesomeIcons.check,
                  size: 12.w,
                  color: colors.primary,
                ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        ...wallets.map(
          (wallet) => PopupMenuItem<String?>(
            value: wallet.id,
            child: Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.wallet,
                  size: 14.w,
                  color: selectedWalletId == wallet.id
                      ? colors.primary
                      : colors.textSecondary,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    wallet.name,
                    style: TextStyleConstants.b2.copyWith(
                      color: selectedWalletId == wallet.id
                          ? colors.primary
                          : colors.textPrimary,
                      fontWeight: selectedWalletId == wallet.id
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (selectedWalletId == wallet.id)
                  FaIcon(
                    FontAwesomeIcons.check,
                    size: 12.w,
                    color: colors.primary,
                  ),
              ],
            ),
          ),
        ),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: selectedWalletId != null
              ? colors.primary.withValues(alpha: 0.1)
              : colors.surfaceVariant,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: selectedWalletId != null
                ? colors.primary.withValues(alpha: 0.3)
                : colors.border.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.filter,
              size: 12.w,
              color: selectedWalletId != null
                  ? colors.primary
                  : colors.textSecondary,
            ),
            SizedBox(width: 6.w),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 100.w),
              child: Text(
                selectedLabel,
                style: TextStyleConstants.label2.copyWith(
                  color: selectedWalletId != null
                      ? colors.primary
                      : colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 4.w),
            FaIcon(
              FontAwesomeIcons.chevronDown,
              size: 10.w,
              color: selectedWalletId != null
                  ? colors.primary
                  : colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
