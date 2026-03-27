import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/debt_loan/controllers/debt_loan_controller.dart';
import 'package:app_saku_rapi/features/debt_loan/models/debt_loan_summary_model.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:app_saku_rapi/global/widgets/saku_empty_state.dart';
import 'package:app_saku_rapi/global/widgets/saku_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// Halaman utama list hutang/piutang.
///
/// Dua tab:
/// - "Untuk Dibayar" (debt) — hutang yang harus dilunasi
/// - "Untuk Diterima" (loan) — piutang yang harus diterima
///
/// Masing-masing tab menampilkan list per kontak,
/// dikelompokkan menjadi Belum Lunas dan Lunas.
class DebtLoanPage extends ConsumerStatefulWidget {
  const DebtLoanPage({super.key});

  @override
  ConsumerState<DebtLoanPage> createState() => _DebtLoanPageState();
}

class _DebtLoanPageState extends ConsumerState<DebtLoanPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  /// Tab index: 0 = debt, 1 = loan.
  String get _currentType => _tabController.index == 0 ? 'debt' : 'loan';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Load data for initial tab.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(debtLoanControllerProvider.notifier).loadSummary('debt');
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    ref.read(debtLoanControllerProvider.notifier).loadSummary(_currentType);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          l10n.debtLoanTitle,
          style: TextStyleConstants.h6.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [_DebtLoanWalletFilter(currentType: _currentType)],
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: colors.primary,
          labelStyle: TextStyleConstants.label1.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyleConstants.label1,
          tabs: [
            Tab(text: l10n.debtLoanTabToPay),
            Tab(text: l10n.debtLoanTabToReceive),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DebtLoanListView(type: 'debt'),
          _DebtLoanListView(type: 'loan'),
        ],
      ),
    );
  }
}

// ───────────────── List View ─────────────────

class _DebtLoanListView extends ConsumerWidget {
  const _DebtLoanListView({required this.type});
  final String type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(debtLoanControllerProvider);
    final l10n = context.l10n;
    final colors = context.colors;

    if (state.status == DebtLoanStatus.loading) {
      return const Center(child: SakuLoadingIndicator());
    }

    if (state.status == DebtLoanStatus.error) {
      return Center(
        child: SakuEmptyState(
          message: state.errorMessage ?? '',
          icon: FontAwesomeIcons.triangleExclamation,
        ),
      );
    }

    if (state.summaries.isEmpty) {
      return SakuEmptyState(
        message: l10n.debtLoanEmpty,
        icon: FontAwesomeIcons.handshake,
      );
    }

    final unpaid = state.unpaid;
    final paid = state.paid;

    // Build flat list with section headers.
    final items = <_ListItem>[];

    if (unpaid.isNotEmpty) {
      final totalRemaining = unpaid.fold(0.0, (s, e) => s + e.remaining);
      items.add(
        _ListItem.header(
          type == 'debt' ? l10n.debtLoanUnpaid : l10n.debtLoanUnpaid,
          totalRemaining,
          type,
          colors,
        ),
      );
      for (final summary in unpaid) {
        items.add(_ListItem.person(summary));
      }
    }

    if (paid.isNotEmpty) {
      final totalPaid = paid.fold(0.0, (s, e) => s + e.totalPrincipal);
      items.add(_ListItem.header(l10n.debtLoanPaid, totalPaid, type, colors));
      for (final summary in paid) {
        items.add(_ListItem.person(summary));
      }
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item.isHeader) {
          return _SectionHeader(
            label: item.headerLabel!,
            amount: item.headerAmount!,
            type: type,
          );
        }
        return _DebtLoanPersonTile(summary: item.summary!, type: type);
      },
    );
  }
}

// ───────────────── List Item Model ─────────────────

class _ListItem {
  const _ListItem._({this.headerLabel, this.headerAmount, this.summary});

  final String? headerLabel;
  final double? headerAmount;
  final DebtLoanSummaryModel? summary;

  bool get isHeader => headerLabel != null;

  factory _ListItem.header(
    String label,
    double amount,
    String type,
    dynamic colors,
  ) {
    return _ListItem._(headerLabel: label, headerAmount: amount);
  }

  factory _ListItem.person(DebtLoanSummaryModel summary) {
    return _ListItem._(summary: summary);
  }
}

// ───────────────── Section Header ─────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.amount,
    required this.type,
  });

  final String label;
  final double amount;
  final String type;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typeColor = type == 'debt' ? colors.debt : colors.loan;
    final prefix = type == 'debt' ? '+' : '-';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      color: colors.surfaceVariant,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyleConstants.label2.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '$prefix${amount.toCurrency()}',
            style: TextStyleConstants.label1.copyWith(
              color: typeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────── Person Tile ─────────────────

class _DebtLoanPersonTile extends StatelessWidget {
  const _DebtLoanPersonTile({required this.summary, required this.type});

  final DebtLoanSummaryModel summary;
  final String type;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final typeColor = type == 'debt' ? colors.debt : colors.loan;
    final prefix = type == 'debt' ? '+' : '-';

    return InkWell(
      onTap: () {
        context.push(
          AppRouter.debtLoanPerson,
          extra: {'withPerson': summary.withPerson, 'type': type},
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 20.r,
              backgroundColor: typeColor.withValues(alpha: 0.12),
              child: Text(
                summary.withPerson.isNotEmpty
                    ? summary.withPerson[0].toUpperCase()
                    : '?',
                style: TextStyleConstants.h7.copyWith(
                  color: typeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 12.w),

            // Name + count
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.withPerson,
                    style: TextStyleConstants.b1.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    l10n.debtLoanTransactionCount(summary.transactionCount),
                    style: TextStyleConstants.label2.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$prefix${summary.remaining.toCurrency()}',
                  style: TextStyleConstants.b2.copyWith(
                    color: typeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  l10n.debtLoanRemaining,
                  style: TextStyleConstants.label2.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────── Wallet Filter ─────────────────

class _DebtLoanWalletFilter extends ConsumerWidget {
  const _DebtLoanWalletFilter({required this.currentType});
  final String currentType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final wallets = ref.watch(walletListProvider);
    final state = ref.watch(debtLoanControllerProvider);
    final selectedWalletId = state.selectedWalletId;

    return PopupMenuButton<String?>(
      onSelected: (walletId) {
        ref
            .read(debtLoanControllerProvider.notifier)
            .setWalletFilter(walletId, currentType);
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
                  l10n.debtLoanAllWallets,
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
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: FaIcon(
          FontAwesomeIcons.filter,
          size: 16.w,
          color: selectedWalletId != null ? colors.primary : colors.textPrimary,
        ),
      ),
    );
  }
}
