import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/debt_status_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/debt_loan/controllers/debt_loan_person_controller.dart';
import 'package:app_saku_rapi/features/debt_loan/models/debt_loan_transaction_model.dart';
import 'package:app_saku_rapi/features/debt_loan/models/settlement_history_argument.dart';
import 'package:app_saku_rapi/features/debt_loan/view/widgets/debt_loan_person_shimmer.dart';
import 'package:app_saku_rapi/features/debt_loan/view/widgets/debt_loan_settlement_sheet.dart';
import 'package:app_saku_rapi/global/widgets/saku_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Halaman daftar transaksi hutang/piutang dengan satu orang tertentu.
///
/// Menampilkan:
/// - Summary (total income, expense)
/// - List transaksi grouped by date
/// - Tombol pelunasan/penerimaan
class DebtLoanPersonPage extends ConsumerStatefulWidget {
  const DebtLoanPersonPage({super.key, this.withPerson, required this.type});

  final String? withPerson;
  final String type;

  @override
  ConsumerState<DebtLoanPersonPage> createState() => _DebtLoanPersonPageState();
}

class _DebtLoanPersonPageState extends ConsumerState<DebtLoanPersonPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(
            debtLoanPersonControllerProvider((
              widget.withPerson,
              widget.type,
            )).notifier,
          )
          .loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final state = ref.watch(
      debtLoanPersonControllerProvider((widget.withPerson, widget.type)),
    );

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(l10n.debtLoanPersonTitle), centerTitle: false),
      body: _buildBody(context, state),
      // Settlement FAB — only when there are unpaid transactions.
      floatingActionButton: state.totalRemaining > 0
          ? FloatingActionButton.extended(
              onPressed: () => _showSettlementSheet(context, state),
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              icon: FaIcon(
                widget.type == 'debt'
                    ? FontAwesomeIcons.moneyBillTransfer
                    : FontAwesomeIcons.handHoldingDollar,
                size: 18.w,
              ),
              label: Text(
                widget.type == 'debt'
                    ? l10n.debtLoanPayDebt
                    : l10n.debtLoanCollectLoan,
                style: TextStyleConstants.label1.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBody(BuildContext context, DebtLoanPersonState state) {
    final l10n = context.l10n;

    if (state.status == DebtLoanPersonStatus.loading) {
      return const DebtLoanPersonShimmer();
    }

    if (state.status == DebtLoanPersonStatus.error) {
      return Center(
        child: SakuEmptyState(
          message: state.errorMessage ?? '',
          icon: FontAwesomeIcons.triangleExclamation,
        ),
      );
    }

    if (state.transactions.isEmpty) {
      return SakuEmptyState(
        message: l10n.debtLoanEmptyPerson,
        icon: FontAwesomeIcons.fileLines,
      );
    }

    return ListView(
      padding: EdgeInsets.only(bottom: 80.h),
      children: [
        // ─── Result count ───
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
          child: Text(
            l10n.debtLoanPersonResult(state.transactions.length),
            style: TextStyleConstants.label2.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ),

        // ─── Summary card ───
        _PersonSummaryCard(state: state, type: widget.type),

        SizedBox(height: 8.h),

        // ─── Grouped transactions ───
        ..._buildGroupedList(context, state),
      ],
    );
  }

  List<Widget> _buildGroupedList(
    BuildContext context,
    DebtLoanPersonState state,
  ) {
    final grouped = <String, List<DebtLoanTransactionModel>>{};

    for (final tx in state.transactions) {
      final key = DateFormat('yyyy-MM-dd').format(tx.date);
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    final widgets = <Widget>[];
    for (final entry in grouped.entries) {
      final date = DateTime.parse(entry.key);
      widgets.add(
        _DateHeader(date: date, type: widget.type, transactions: entry.value),
      );
      for (final tx in entry.value) {
        widgets.add(
          _DebtLoanTransactionTile(
            transaction: tx,
            type: widget.type,
            onSettlement: tx.remaining > 0
                ? () => _showSettlementForTransaction(context, tx)
                : null,
            onTap:
                tx.status == DebtStatusEnum.paid ||
                    tx.status == DebtStatusEnum.partial
                ? () => _navigateToSettlementHistory(context, tx)
                : null,
          ),
        );
      }
    }
    return widgets;
  }

  void _showSettlementSheet(BuildContext context, DebtLoanPersonState state) {
    // Find the first unpaid transaction for quick settlement.
    final unpaidTxs = state.transactions.where((t) => t.remaining > 0).toList();
    if (unpaidTxs.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => DebtLoanSettlementSheet(
        transactions: unpaidTxs,
        type: widget.type,
        withPerson: widget.withPerson,
        onSuccess: () {
          // Reload after settlement.
          ref
              .read(
                debtLoanPersonControllerProvider((
                  widget.withPerson,
                  widget.type,
                )).notifier,
              )
              .loadTransactions();
        },
      ),
    );
  }

  void _navigateToSettlementHistory(
    BuildContext context,
    DebtLoanTransactionModel tx,
  ) {
    context
        .push(
          AppRouter.settlementHistory,
          extra: SettlementHistoryArgument(
            referenceTransactionId: tx.id,
            originalAmount: tx.totalAmount,
            withPerson: tx.withPerson ?? '',
            type: widget.type,
          ),
        )
        .then((_) {
          // Reload after returning — settlements may have been edited/deleted.
          ref
              .read(
                debtLoanPersonControllerProvider((
                  widget.withPerson,
                  widget.type,
                )).notifier,
              )
              .loadTransactions();
        });
  }

  void _showSettlementForTransaction(
    BuildContext context,
    DebtLoanTransactionModel tx,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => DebtLoanSettlementSheet(
        transactions: [tx],
        type: widget.type,
        withPerson: widget.withPerson,
        onSuccess: () {
          ref
              .read(
                debtLoanPersonControllerProvider((
                  widget.withPerson,
                  widget.type,
                )).notifier,
              )
              .loadTransactions();
        },
      ),
    );
  }
}

// ───────────────── Summary Card ─────────────────

class _PersonSummaryCard extends StatelessWidget {
  const _PersonSummaryCard({required this.state, required this.type});

  final DebtLoanPersonState state;
  final String type;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final typeColor = type == 'debt' ? colors.debt : colors.loan;

    return Padding(
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
                state.totalSettled.toCurrency(),
                style: TextStyleConstants.b2.copyWith(
                  color: colors.income,
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
                '+${state.totalPrincipal.toCurrency()}',
                style: TextStyleConstants.b2.copyWith(
                  color: typeColor,
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
                '-${state.totalRemaining.toCurrency()}',
                style: TextStyleConstants.b1.copyWith(
                  color: colors.expense,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────── Date Header ─────────────────

class _DateHeader extends StatelessWidget {
  const _DateHeader({
    required this.date,
    required this.type,
    required this.transactions,
  });

  final DateTime date;
  final String type;
  final List<DebtLoanTransactionModel> transactions;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typeColor = type == 'debt' ? colors.debt : colors.loan;
    final prefix = type == 'debt' ? '+' : '-';
    final dayTotal = transactions.fold(0.0, (s, t) => s + t.totalAmount);
    final locale = context.locale.languageCode;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      color: colors.surfaceVariant,
      child: Row(
        children: [
          // Date number
          Text(
            DateFormat('dd', locale).format(date),
            style: TextStyleConstants.h5.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 8.w),
          // Day name + month/year
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
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Day total
          Text(
            '$prefix${dayTotal.toCurrency()}',
            style: TextStyleConstants.b2.copyWith(
              color: typeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────── Transaction Tile ─────────────────

class _DebtLoanTransactionTile extends StatelessWidget {
  const _DebtLoanTransactionTile({
    required this.transaction,
    required this.type,
    this.onSettlement,
    this.onTap,
  });

  final DebtLoanTransactionModel transaction;
  final String type;
  final VoidCallback? onSettlement;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final typeColor = type == 'debt' ? colors.debt : colors.loan;
    final prefix = type == 'debt' ? '+' : '-';

    final statusLabel = switch (transaction.status) {
      DebtStatusEnum.paid => l10n.debtLoanStatusPaid,
      DebtStatusEnum.partial =>
        '${l10n.debtLoanStatusPaid} ${transaction.totalSettled.toCurrency()}',
      _ => l10n.debtLoanUnpaid,
    };

    final statusColor = switch (transaction.status) {
      DebtStatusEnum.paid => colors.success,
      DebtStatusEnum.partial => colors.warning,
      _ => colors.textSecondary,
    };

    return InkWell(
      onTap: onTap ?? onSettlement,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 4.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(width: 12.w),

            // Transaction info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.note ??
                        (type == 'debt'
                            ? l10n.transactionDebt
                            : l10n.transactionLoan),
                    style: TextStyleConstants.b2.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
                        transaction.walletName ?? '-',
                        style: TextStyleConstants.label2.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 1.h,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyleConstants.label3.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Amount + remaining
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$prefix${transaction.totalAmount.toCurrency()}',
                  style: TextStyleConstants.b2.copyWith(
                    color: typeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (transaction.remaining > 0) ...[
                  SizedBox(height: 2.h),
                  Text(
                    '${l10n.debtLoanStatusRemaining} ${transaction.remaining.toCurrency()}',
                    style: TextStyleConstants.label2.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
