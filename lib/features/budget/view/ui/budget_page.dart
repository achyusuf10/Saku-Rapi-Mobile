import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/date_time_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/auth/controllers/auth_controller.dart';
import 'package:app_saku_rapi/features/budget/controllers/budget_controller.dart';
import 'package:app_saku_rapi/features/budget/models/budget_model.dart';
import 'package:app_saku_rapi/features/budget/view/widgets/budget_group_card.dart';
import 'package:app_saku_rapi/features/budget/view/widgets/budget_shimmer.dart';
import 'package:app_saku_rapi/features/budget/view/widgets/budget_summary_card.dart';
import 'package:app_saku_rapi/features/notification/controllers/budget_alert_checker.dart';
import 'package:app_saku_rapi/features/notification/controllers/notification_controller.dart';
import 'package:app_saku_rapi/global/widgets/main_shell_page.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:app_saku_rapi/global/widgets/saku_empty_state.dart';
import 'package:app_saku_rapi/global/widgets/saku_error_state.dart';
import 'package:app_saku_rapi/global/widgets/saku_wallet_filter_button.dart';
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
    final budgetAlert50Enabled = ref.read(isBudgetAlert50EnabledProvider);
    final l10n = context.l10n;

    checker.checkBudgets(
      budgetState: budgetState,
      budgetAlertEnabled: budgetAlertEnabled,
      budgetAlert50Enabled: budgetAlert50Enabled,
      l10n: l10n,
    );
  }

  void _syncTabController(List<String> types) {
    final currentLength = _tabController?.length ?? 0;
    if (currentLength != types.length) {
      _tabController?.dispose();
      if (types.isNotEmpty) {
        _tabController = TabController(length: types.length, vsync: this);
        _tabController!.addListener(() {
          if (!_tabController!.indexIsChanging) {
            final key = types[_tabController!.index];
            ref
                .read(budgetControllerProvider.notifier)
                .setSelectedPeriodKey(key);
          }
        });
        // Set initial selected period key to first tab
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(budgetControllerProvider.notifier)
              .setSelectedPeriodKey(types.first);
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
        title: Text(l10n.budgetTitle),
        centerTitle: false,
        actions: [
          SakuWalletFilterButton(
            selectedWalletId: budgetState.walletFilter,
            allLabel: l10n.budgetFilterAll,
            onSelected: (walletId) {
              ref
                  .read(budgetControllerProvider.notifier)
                  .setWalletFilter(walletId);
            },
          ),
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
      body: _buildBody(budgetState, periodTypes),
    );
  }

  Widget _buildBody(BudgetState budgetState, List<String> periodTypes) {
    final l10n = context.l10n;

    switch (budgetState.status) {
      case BudgetStatus.initial:
      case BudgetStatus.loading:
        return const BudgetShimmer();

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
                  (key) => _BudgetPeriodList(
                    periodKey: key,
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
          periodKey: periodTypes.isNotEmpty ? periodTypes.first : null,
          onAdd: () => _openBudgetForm(null),
          onTapBudget: (b) => _navigateToDetail(b),
          onNavigateCompleted: () => _navigateToCompleted(),
        );
    }
  }

  Widget _buildEmptyState(dynamic l10n) {
    return RefreshIndicator(
      onRefresh: () => ref.read(budgetControllerProvider.notifier).refresh(),
      child: ListView(
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
      ),
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
    final carryForward = data['carryForward'] as bool? ?? false;

    if (existing == null) {
      await _handleCreate(
        data,
        user.id,
        controller,
        l10n,
        periodType,
        carryForward,
      );
    } else {
      await _handleEdit(
        data,
        existing,
        controller,
        l10n,
        periodType,
        carryForward,
      );
    }
  }

  Future<void> _handleEdit(
    Map<String, dynamic> data,
    BudgetModel existing,
    BudgetController controller,
    dynamic l10n,
    BudgetPeriodType periodType,
    bool carryForward,
  ) async {
    final categoryId = data['categoryId'] as String;
    final walletId = data['walletId'] as String?;
    final amount = data['amount'] as double;
    final startDate = data['startDate'] as DateTime;
    final endDate = data['endDate'] as DateTime;
    final isRecurring = data['isRecurring'] as bool;

    // Check for duplicates on edit too
    final duplicateId = await controller.findDuplicateBudgetId(
      categoryId: categoryId,
      walletId: walletId,
      startDate: startDate,
      endDate: endDate,
    );

    if (!mounted) return;

    // If duplicate found and it's not the same budget
    if (duplicateId != null && duplicateId != existing.id) {
      final categoryName = data['categoryName'] as String? ?? '';
      final walletName = data['walletName'] as String? ?? l10n.budgetFilterAll;

      final confirmed = await context.showConfirmDialog(
        title: l10n.budgetDuplicateTitle,
        message: l10n.budgetDuplicateMessage(categoryName, walletName),
        confirmLabel: l10n.budgetDuplicateReplace,
        cancelLabel: l10n.budgetDuplicateKeep,
      );

      if (confirmed != true || !mounted) return;

      // Delete the other duplicate first, then update this one
      await controller.deleteBudget(duplicateId);
      if (!mounted) return;
    }

    final updateResult = await controller.updateBudget(
      existing: existing,
      categoryId: categoryId,
      walletId: walletId,
      amount: amount,
      startDate: startDate,
      endDate: endDate,
      isRecurring: isRecurring,
      periodType: periodType,
      carryForward: carryForward,
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

  Future<void> _handleCreate(
    Map<String, dynamic> data,
    String userId,
    BudgetController controller,
    dynamic l10n,
    BudgetPeriodType periodType,
    bool carryForward,
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
        carryForward: carryForward,
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
        carryForward: carryForward,
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
  final List<String> types;

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

  String _periodLabel(String key, BuildContext context) {
    final l10n = context.l10n;
    if (key == 'weekly') return l10n.budgetTabWeekly;
    if (key == 'monthly') return l10n.budgetTabMonthly;
    if (key == 'quarterly') return l10n.budgetTabQuarterly;
    if (key == 'yearly') return l10n.budgetTabYearly;
    // Custom: show date range label e.g. "10 Jan - 31 Jan"
    if (key.startsWith('custom_')) {
      final parts = key.split('_');
      if (parts.length == 3) {
        final start = DateTime.tryParse(parts[1]);
        final end = DateTime.tryParse(parts[2]);
        if (start != null && end != null) {
          return '${start.extToFormattedString(outputDateFormat: 'dd MMM')} - ${end.extToFormattedString(outputDateFormat: 'dd MMM')}';
        }
      }
    }
    return l10n.budgetTabCustom;
  }
}

// ═══════════════════════════════════════════════════
// Budget Period List (content of each tab)
// ═══════════════════════════════════════════════════

class _BudgetPeriodList extends ConsumerWidget {
  const _BudgetPeriodList({
    this.periodKey,
    required this.onAdd,
    required this.onTapBudget,
    required this.onNavigateCompleted,
  });

  final String? periodKey;
  final VoidCallback onAdd;
  final void Function(BudgetModel) onTapBudget;
  final VoidCallback onNavigateCompleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final allBudgets = ref.watch(budgetFilteredListProvider);
    final upcomingBudgets = ref.watch(budgetControllerProvider).upcomingBudgets;

    // Filter budgets by this tab's periodKey locally
    final budgets = periodKey != null
        ? allBudgets.where((b) {
            if (b.periodType == BudgetPeriodType.custom) {
              return 'custom_${b.startDate.toIso8601String().substring(0, 10)}_${b.endDate.toIso8601String().substring(0, 10)}' ==
                  periodKey;
            }
            return b.periodType.value == periodKey;
          }).toList()
        : allBudgets;

    // Group budgets by parent-child
    final groups = _buildGroups(budgets);

    return RefreshIndicator(
      onRefresh: () => ref.read(budgetControllerProvider.notifier).refresh(),
      child: ListView(
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

          // Upcoming Budgets
          if (upcomingBudgets.isNotEmpty) ...[
            SizedBox(height: 20.h),
            Text(
              l10n.budgetUpcomingBudgets,
              style: TextStyleConstants.h7.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: 12.h),
            ...upcomingBudgets.map(
              (budget) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: BudgetGroupCard(
                  group: BudgetGroup(parent: budget),
                  onTap: onTapBudget,
                ),
              ),
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
      ),
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
