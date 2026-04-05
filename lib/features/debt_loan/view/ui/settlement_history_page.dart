import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/debt_loan/controllers/settlement_history_controller.dart';
import 'package:app_saku_rapi/features/debt_loan/models/settlement_history_model.dart';
import 'package:app_saku_rapi/features/debt_loan/view/widgets/debt_loan_settlement_sheet.dart';
import 'package:app_saku_rapi/features/debt_loan/view/widgets/settlement_history_shimmer.dart';
import 'package:app_saku_rapi/global/widgets/saku_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

/// Halaman riwayat pelunasan untuk satu transaksi hutang/piutang.
///
/// Diakses dari tombol "DAFTAR TRANSAKSI" di halaman detail transaksi.
/// Menampilkan semua settlement yang merujuk ke transaksi asal.
class SettlementHistoryPage extends ConsumerStatefulWidget {
  const SettlementHistoryPage({
    super.key,
    required this.referenceTransactionId,
    required this.originalAmount,
    this.withPerson,
    required this.type,
  });

  final String referenceTransactionId;
  final double originalAmount;
  final String? withPerson;
  final String type; // 'debt' or 'loan'

  @override
  ConsumerState<SettlementHistoryPage> createState() =>
      _SettlementHistoryPageState();
}

class _SettlementHistoryPageState extends ConsumerState<SettlementHistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(
            settlementHistoryControllerProvider(
              widget.referenceTransactionId,
            ).notifier,
          )
          .loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final state = ref.watch(
      settlementHistoryControllerProvider(widget.referenceTransactionId),
    );

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(l10n.debtLoanPersonTitle), centerTitle: false),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, SettlementHistoryState state) {
    final l10n = context.l10n;
    final colors = context.colors;

    if (state.status == SettlementHistoryStatus.loading) {
      return const SettlementHistoryShimmer();
    }

    if (state.status == SettlementHistoryStatus.error) {
      return Center(
        child: SakuEmptyState(
          message: state.errorMessage ?? '',
          icon: FontAwesomeIcons.triangleExclamation,
        ),
      );
    }

    if (state.settlements.isEmpty) {
      return SakuEmptyState(
        message: l10n.debtLoanEmptyPerson,
        icon: FontAwesomeIcons.fileLines,
      );
    }

    // Calculate summary.
    final totalIncome = state.settlements
        .where((s) => s.type == 'income')
        .fold(0.0, (sum, s) => sum + s.totalAmount);
    final totalExpense = state.settlements
        .where((s) => s.type == 'expense')
        .fold(0.0, (sum, s) => sum + s.totalAmount);

    return ListView(
      children: [
        // ─── Count ───
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
          child: Text(
            l10n.debtLoanPersonResult(state.settlements.length),
            style: TextStyleConstants.label2.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),

        // ─── Summary ───
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.debtLoanPersonIncome,
                    style: TextStyleConstants.label2.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  Text(
                    totalIncome > 0
                        ? '+${totalIncome.toCurrency()}'
                        : totalIncome.toCurrency(),
                    style: TextStyleConstants.b2.copyWith(
                      color: totalIncome > 0
                          ? colors.income
                          : colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.debtLoanPersonExpense,
                    style: TextStyleConstants.label2.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  Text(
                    totalExpense > 0
                        ? '+${totalExpense.toCurrency()}'
                        : totalExpense.toCurrency(),
                    style: TextStyleConstants.b2.copyWith(
                      color: totalExpense > 0
                          ? colors.expense
                          : colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Divider(color: colors.border, height: 1),
              SizedBox(height: 4.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '-${(totalExpense > 0 ? totalExpense : totalIncome).toCurrency()}',
                    style: TextStyleConstants.b1.copyWith(
                      color: colors.expense,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 8.h),

        // ─── Grouped settlements ───
        ..._buildGroupedList(context, state),
      ],
    );
  }

  List<Widget> _buildGroupedList(
    BuildContext context,
    SettlementHistoryState state,
  ) {
    final grouped = <String, List<SettlementHistoryModel>>{};
    for (final s in state.settlements) {
      final key = DateFormat('yyyy-MM-dd').format(s.date);
      grouped.putIfAbsent(key, () => []).add(s);
    }

    final widgets = <Widget>[];
    final locale = context.locale.languageCode;

    for (final entry in grouped.entries) {
      final date = DateTime.parse(entry.key);
      final dayTotal = entry.value.fold(0.0, (sum, s) => sum + s.totalAmount);

      // Date header
      widgets.add(
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          color: context.colors.surfaceVariant,
          child: Row(
            children: [
              Text(
                DateFormat('dd', locale).format(date),
                style: TextStyleConstants.h5.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE', locale).format(date),
                      style: TextStyleConstants.label2.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      DateFormat('MMMM yyyy', locale).format(date),
                      style: TextStyleConstants.label2.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '-${dayTotal.toCurrency()}',
                style: TextStyleConstants.b2.copyWith(
                  color: context.colors.expense,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );

      // Settlement tiles
      for (final settlement in entry.value) {
        widgets.add(
          _SettlementTile(
            settlement: settlement,
            type: widget.type,
            onTap: () => _openEditSheet(settlement),
          ),
        );
      }
    }
    return widgets;
  }

  void _openEditSheet(SettlementHistoryModel settlement) {
    DebtLoanSettlementSheet.showEdit(
      context: context,
      settlement: settlement,
      originalAmount: widget.originalAmount,
      onSuccess: () {
        // Reload history after edit/delete.
        ref
            .read(
              settlementHistoryControllerProvider(
                widget.referenceTransactionId,
              ).notifier,
            )
            .loadHistory();
      },
    );
  }
}

// ───────────────── Settlement Tile ─────────────────

class _SettlementTile extends StatelessWidget {
  const _SettlementTile({
    required this.settlement,
    required this.type,
    this.onTap,
  });

  final SettlementHistoryModel settlement;
  final String type;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final isDebtPayment = settlement.type == 'expense';
    final color = isDebtPayment ? colors.expense : colors.income;

    final title = isDebtPayment
        ? l10n.debtLoanRepayment
        : l10n.debtLoanCollection;

    final subtitle = isDebtPayment
        ? l10n.debtLoanDebtPaymentDesc(
            settlement.withPerson ?? l10n.debtLoanSomeone,
          )
        : l10n.debtLoanLoanCollectionDesc(
            settlement.withPerson ?? l10n.debtLoanSomeone,
          );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Row(
          children: [
            // Icon
            CircleAvatar(
              radius: 18.r,
              backgroundColor: color.withValues(alpha: 0.12),
              child: FaIcon(
                isDebtPayment
                    ? FontAwesomeIcons.arrowRight
                    : FontAwesomeIcons.arrowLeft,
                size: 14.w,
                color: color,
              ),
            ),
            SizedBox(width: 12.w),

            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyleConstants.b2.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyleConstants.label2.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  if (settlement.walletName != null) ...[
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.wallet,
                          size: 10.w,
                          color: colors.textSecondary,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          settlement.walletName!,
                          style: TextStyleConstants.label2.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Amount
            Text(
              '-${settlement.totalAmount.toCurrency()}',
              style: TextStyleConstants.b2.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
