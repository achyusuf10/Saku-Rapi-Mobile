import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/enums/debt_status_enum.dart';
import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/date_time_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/category/utils/category_icon_mapper.dart';
import 'package:app_saku_rapi/features/dashboard/controllers/dashboard_controller.dart';
import 'package:app_saku_rapi/features/debt_loan/controllers/settlement_history_controller.dart';
import 'package:app_saku_rapi/features/debt_loan/models/debt_loan_transaction_model.dart';
import 'package:app_saku_rapi/features/debt_loan/models/settlement_history_argument.dart';
import 'package:app_saku_rapi/features/debt_loan/models/settlement_history_model.dart';
import 'package:app_saku_rapi/features/debt_loan/view/widgets/debt_loan_settlement_sheet.dart';
import 'package:app_saku_rapi/features/history/controllers/history_controller.dart';
import 'package:app_saku_rapi/features/transaction/controllers/transaction_form_controller.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_item_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// Halaman detail transaksi.
///
/// Menerima [TransactionModel] via `GoRouter` extras.
/// Menampilkan semua field transaksi dan daftar item.
/// Tombol edit membuka [TransactionFormPage] dengan data yang ada.
/// Tombol hapus menghapus transaksi (dengan konfirmasi).
class TransactionDetailPage extends ConsumerWidget {
  const TransactionDetailPage({super.key, required this.transaction});

  final TransactionModel transaction;

  static Color _parseHexColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          l10n.transactionDetailTitle,
          style: TextStyleConstants.h6.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          // Edit button — regular transactions open form, settlements open edit sheet
          if (transaction.type != TransactionTypeEnum.adjustment)
            if (transaction.isSettlement)
              IconButton(
                icon: FaIcon(FontAwesomeIcons.penToSquare, size: 18.w),
                onPressed: () => _openSettlementEdit(context, ref),
              )
            else
              IconButton(
                icon: FaIcon(FontAwesomeIcons.penToSquare, size: 18.w),
                onPressed: () async {
                  final edited = await context.push<bool>(
                    AppRouter.transactionForm,
                    extra: transaction,
                  );
                  if (edited == true && context.mounted) {
                    context.pop(true);
                  }
                },
              ),
          // Delete button — settlements use dedicated RPC
          if (transaction.isSettlement)
            IconButton(
              icon: FaIcon(
                FontAwesomeIcons.trashCan,
                size: 18.w,
                color: colors.error,
              ),
              onPressed: () => _confirmDeleteSettlement(context, ref),
            )
          else
            IconButton(
              icon: FaIcon(
                FontAwesomeIcons.trashCan,
                size: 18.w,
                color: colors.error,
              ),
              onPressed: () => _confirmDelete(context, ref),
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        children: [
          // ─── Type badge + amount ───
          _HeaderCard(transaction: transaction),

          SizedBox(height: 16.h),

          // ─── Detail fields ───
          _DetailSection(
            label: l10n.transactionWallet,
            value: transaction.walletName ?? '-',
            icon: FontAwesomeIcons.wallet,
          ),

          if (transaction.type == TransactionTypeEnum.transfer)
            _DetailSection(
              label: l10n.transactionDestWallet,
              value: transaction.destinationWalletName ?? '-',
              icon: FontAwesomeIcons.arrowRightArrowLeft,
            ),

          _DetailSection(
            label: l10n.transactionDate,
            value: transaction.date.extToDateStringDDMMMMYYYY(),
            icon: FontAwesomeIcons.calendarDay,
          ),

          if (transaction.withPerson != null)
            _DetailSection(
              label: l10n.transactionWithPerson,
              value: transaction.withPerson!,
              icon: FontAwesomeIcons.userTie,
            ),

          if (transaction.merchantName != null)
            _DetailSection(
              label: l10n.transactionMerchant,
              value: transaction.merchantName!,
              icon: FontAwesomeIcons.store,
            ),

          if (transaction.note != null)
            _DetailSection(
              label: l10n.transactionNote,
              value: transaction.note!,
              icon: FontAwesomeIcons.noteSticky,
            ),

          if (transaction.dueDate != null)
            _DetailSection(
              label: l10n.transactionDueDate,
              value: transaction.dueDate!.extToDateStringDDMMMMYYYY(),
              icon: FontAwesomeIcons.clockRotateLeft,
            ),

          // ─── Single item: show category inline ───
          if (transaction.items.length == 1) ...[
            _DetailSection(
              label: l10n.transactionCategory,
              value: transaction.items.first.categoryName ?? '-',
              icon: transaction.items.first.categoryIcon != null
                  ? CategoryIconMapper.getIcon(
                      transaction.items.first.categoryIcon!,
                    )
                  : FontAwesomeIcons.layerGroup,
              iconColor: transaction.items.first.categoryColor != null
                  ? _parseHexColor(transaction.items.first.categoryColor!)
                  : null,
            ),
            if (transaction.items.first.itemName != null)
              _DetailSection(
                label: l10n.transactionItemName,
                value: transaction.items.first.itemName!,
                icon: FontAwesomeIcons.tag,
              ),
          ],

          // ─── Multi-item list ───
          if (transaction.items.length > 1) ...[
            SizedBox(height: 20.h),
            _ItemsSection(
              items: transaction.items,
              totalAmount: transaction.totalAmount,
            ),
          ],

          // ─── Debt/Loan contact + settlement section ───
          if (transaction.type == TransactionTypeEnum.debt ||
              transaction.type == TransactionTypeEnum.loan)
            _DebtLoanSection(transaction: transaction),

          // ─── Excluded from report label ───
          if (transaction.type == TransactionTypeEnum.debt ||
              transaction.type == TransactionTypeEnum.loan ||
              transaction.isSettlement) ...[
            SizedBox(height: 16.h),
            Text(
              l10n.debtLoanExcludedFromReport,
              style: TextStyleConstants.label2.copyWith(
                color: colors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    if (!context.mounted) return;

    final confirmed = await context.showConfirmDialog(
      title: context.l10n.transactionDeleteConfirmTitle,
      message: context.l10n.transactionDeleteConfirmMessage,
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    context.showLoadingOverlay();

    try {
      final result = await ref
          .read(transactionRepositoryProvider)
          .deleteTransaction(transaction.id);

      if (!context.mounted) return;

      if (result.isSuccess()) {
        ref.read(walletControllerProvider.notifier).loadWallets();
        ref.read(dashboardControllerProvider.notifier).loadDashboard();
        ref.read(historyControllerProvider.notifier).loadTransactions();
        context.closeOverlay();
        context.showAppAlert(
          context.l10n.transactionDeleteSuccess,
          alertType: AlertTypeEnum.success,
        );
        context.pop(true);
      } else {
        context.closeOverlay();
        final (message, _, _, _) = result.dataError()!;
        context.showAppAlert(message, alertType: AlertTypeEnum.error);
      }
    } finally {
      if (context.mounted) {
        context.closeOverlay();
      }
    }
  }

  /// Buka SettlementEditSheet — ambil `totalAmount` parent terlebih dahulu.
  Future<void> _openSettlementEdit(BuildContext context, WidgetRef ref) async {
    if (!context.mounted) return;

    context.showLoadingOverlay();

    final amountResult = await ref
        .read(transactionRepositoryProvider)
        .getTransactionAmount(transaction.referenceTransactionId!);

    if (!context.mounted) return;
    context.closeOverlay();

    if (!amountResult.isSuccess()) {
      final (message, _, _, _) = amountResult.dataError()!;
      context.showAppAlert(message, alertType: AlertTypeEnum.error);
      return;
    }

    final parentAmount = amountResult.dataSuccess()!;

    final settlementModel = SettlementHistoryModel(
      id: transaction.id,
      walletId: transaction.walletId,
      walletName: transaction.walletName,
      type: transaction.type.toDbValue(),
      totalAmount: transaction.totalAmount,
      date: transaction.date,
      note: transaction.note,
      settlementKind: transaction.settlementKind!,
      referenceTransactionId: transaction.referenceTransactionId!,
    );

    if (!context.mounted) return;

    DebtLoanSettlementSheet.showEdit(
      context: context,
      settlement: settlementModel,
      originalAmount: parentAmount,
      onSuccess: () {
        if (context.mounted) context.pop(true);
      },
    );
  }

  /// Hapus settlement dengan RPC khusus yang menghitung ulang status parent.
  Future<void> _confirmDeleteSettlement(
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (!context.mounted) return;

    final l10n = context.l10n;

    final confirmed = await context.showConfirmDialog(
      title: l10n.debtLoanSettlementDeleteConfirm,
      message: l10n.debtLoanSettlementDeleteMessage,
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    context.showLoadingOverlay();

    try {
      final result = await ref
          .read(transactionRepositoryProvider)
          .deleteSettlement(transaction.id);

      if (!context.mounted) return;

      if (result.isSuccess()) {
        ref.read(walletControllerProvider.notifier).loadWallets();
        ref.read(dashboardControllerProvider.notifier).loadDashboard();
        ref.read(historyControllerProvider.notifier).loadTransactions();
        context.closeOverlay();
        context.showAppAlert(
          l10n.debtLoanSettlementDeleteSuccess,
          alertType: AlertTypeEnum.success,
        );
        context.pop(true);
      } else {
        context.closeOverlay();
        final (message, _, _, _) = result.dataError()!;
        context.showAppAlert(message, alertType: AlertTypeEnum.error);
      }
    } finally {
      if (context.mounted) {
        context.closeOverlay();
      }
    }
  }
}

/// Header card showing type badge, amount, and color accent.
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.transaction});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typeColor = _typeColor(transaction.type, colors);

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: typeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: typeColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type label
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              _typeLabel(transaction.type, context),
              style: TextStyleConstants.label2.copyWith(
                color: typeColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          // Amount
          Text(
            transaction.totalAmount.toCurrency(),
            style: TextStyleConstants.h4.copyWith(
              color: typeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (transaction.merchantName != null) ...[
            SizedBox(height: 4.h),
            Text(
              transaction.merchantName!,
              style: TextStyleConstants.b2.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _typeColor(TransactionTypeEnum type, dynamic colors) {
    return switch (type) {
      TransactionTypeEnum.income => colors.income as Color,
      TransactionTypeEnum.expense => colors.expense as Color,
      TransactionTypeEnum.transfer => colors.transfer as Color,
      TransactionTypeEnum.debt => colors.debt as Color,
      TransactionTypeEnum.loan => colors.loan as Color,
      TransactionTypeEnum.adjustment => colors.primary as Color,
      TransactionTypeEnum.transferToAsset => colors.transfer as Color,
    };
  }

  String _typeLabel(TransactionTypeEnum type, BuildContext context) {
    final l10n = context.l10n;
    return switch (type) {
      TransactionTypeEnum.income => l10n.transactionIncome,
      TransactionTypeEnum.expense => l10n.transactionExpense,
      TransactionTypeEnum.transfer => l10n.transactionTransfer,
      TransactionTypeEnum.debt => l10n.transactionDebt,
      TransactionTypeEnum.loan => l10n.transactionLoan,
      TransactionTypeEnum.adjustment => l10n.transactionAdjustment,
      TransactionTypeEnum.transferToAsset => l10n.transactionTransferToAsset,
    };
  }
}

/// Satu baris detail field.
class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(icon, size: 14.w, color: iconColor ?? colors.textSecondary),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyleConstants.label2.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyleConstants.b2.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bagian daftar item transaksi.
class _ItemsSection extends StatelessWidget {
  const _ItemsSection({required this.items, required this.totalAmount});

  final List<TransactionItemModel> items;
  final double totalAmount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.transactionMultiItemToggle,
          style: TextStyleConstants.label1.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        ...items.map((item) => _ItemRow(item: item)),
        // Grand total
        Divider(height: 1, color: colors.border.withValues(alpha: 0.4)),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.transactionGrandTotal,
              style: TextStyleConstants.label1.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              totalAmount.toCurrency(),
              style: TextStyleConstants.b1.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.expense,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final TransactionItemModel item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final iconColor = item.categoryColor != null
        ? _parseColor(item.categoryColor!)
        : colors.textSecondary;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          if (item.categoryIcon != null)
            FaIcon(
              CategoryIconMapper.getIcon(item.categoryIcon!),
              size: 14.w,
              color: iconColor,
            )
          else
            FaIcon(
              FontAwesomeIcons.layerGroup,
              size: 14.w,
              color: colors.textSecondary,
            ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName ?? item.categoryName ?? '-',
                  style: TextStyleConstants.b2.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                if (item.categoryName != null && item.itemName != null)
                  Text(
                    item.categoryName!,
                    style: TextStyleConstants.label2.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            item.amount.toCurrency(),
            style: TextStyleConstants.b2.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }
}

/// Section hutang/piutang pada detail transaksi.
///
/// Menampilkan info kontak (Pemberi Pinjaman / Peminjam), progress pelunasan,
/// dan tombol aksi (PELUNASAN + DAFTAR TRANSAKSI).
class _DebtLoanSection extends ConsumerStatefulWidget {
  const _DebtLoanSection({required this.transaction});

  final TransactionModel transaction;

  @override
  ConsumerState<_DebtLoanSection> createState() => _DebtLoanSectionState();
}

class _DebtLoanSectionState extends ConsumerState<_DebtLoanSection> {
  @override
  void initState() {
    super.initState();
    // Load settlement history for this transaction.
    Future.microtask(() {
      ref
          .read(
            settlementHistoryControllerProvider(widget.transaction.id).notifier,
          )
          .loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final tx = widget.transaction;
    final isDebt = tx.type == TransactionTypeEnum.debt;
    final typeColor = isDebt ? colors.debt : colors.loan;
    final personName = tx.contactName ?? tx.withPerson ?? l10n.debtLoanSomeone;

    final historyState = ref.watch(settlementHistoryControllerProvider(tx.id));
    final totalSettled = historyState.totalSettled;
    final remaining = (tx.totalAmount - totalSettled).clamp(
      0.0,
      tx.totalAmount,
    );
    final progress = tx.totalAmount > 0
        ? (totalSettled / tx.totalAmount).clamp(0.0, 1.0)
        : 0.0;
    final isPaid = tx.status == DebtStatusEnum.paid || remaining <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20.h),

        // ─── Contact info ───
        Row(
          children: [
            CircleAvatar(
              radius: 20.r,
              backgroundColor: typeColor.withValues(alpha: 0.15),
              child: Text(
                personName.isNotEmpty ? personName[0].toUpperCase() : '?',
                style: TextStyleConstants.h6.copyWith(
                  color: typeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDebt ? l10n.debtLoanLender : l10n.debtLoanBorrower,
                    style: TextStyleConstants.label2.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    personName,
                    style: TextStyleConstants.b1.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: 16.h),

        // ─── Settlement progress ───
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            children: [
              // Labels row: Settled | Remaining
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.debtLoanStatusPaid,
                        style: TextStyleConstants.label2.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        totalSettled.toCurrency(),
                        style: TextStyleConstants.b2.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.success,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        l10n.debtLoanStatusRemaining,
                        style: TextStyleConstants.label2.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        remaining.toCurrency(),
                        style: TextStyleConstants.b2.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isPaid ? colors.success : colors.warning,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6.h,
                  backgroundColor: colors.border.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(colors.success),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16.h),

        // ─── Action buttons ───
        Row(
          children: [
            // Settlement button (only if not fully paid)
            if (!isPaid)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openSettlementSheet(
                    context,
                    tx,
                    totalSettled,
                    remaining,
                  ),
                  icon: FaIcon(
                    isDebt
                        ? FontAwesomeIcons.moneyBillTransfer
                        : FontAwesomeIcons.handHoldingDollar,
                    size: 14.w,
                    color: typeColor,
                  ),
                  label: Text(
                    isDebt ? l10n.debtLoanPayDebt : l10n.debtLoanCollectLoan,
                    style: TextStyleConstants.label1.copyWith(
                      color: typeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: typeColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                  ),
                ),
              ),
            if (!isPaid) SizedBox(width: 8.w),
            // Transaction list button (always visible)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push(
                  AppRouter.settlementHistory,
                  extra: SettlementHistoryArgument(
                    referenceTransactionId: tx.id,
                    originalAmount: tx.totalAmount,
                    withPerson: personName,
                    type: isDebt ? 'debt' : 'loan',
                  ),
                ),
                icon: FaIcon(
                  FontAwesomeIcons.clockRotateLeft,
                  size: 14.w,
                  color: colors.textSecondary,
                ),
                label: Text(
                  l10n.debtLoanSettlementHistory,
                  style: TextStyleConstants.label1.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _openSettlementSheet(
    BuildContext context,
    TransactionModel tx,
    double totalSettled,
    double remaining,
  ) {
    final isDebt = tx.type == TransactionTypeEnum.debt;
    final typeStr = isDebt ? 'debt' : 'loan';

    // Convert TransactionModel to DebtLoanTransactionModel for the sheet.
    final debtLoanTx = DebtLoanTransactionModel(
      id: tx.id,
      walletId: tx.walletId,
      walletName: tx.walletName,
      type: typeStr,
      totalAmount: tx.totalAmount,
      date: tx.date,
      note: tx.note,
      withPerson: tx.withPerson,
      contactId: tx.contactId,
      status: tx.status,
      dueDate: tx.dueDate,
      totalSettled: totalSettled,
      remaining: remaining,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => DebtLoanSettlementSheet(
        transactions: [debtLoanTx],
        type: typeStr,
        withPerson: tx.withPerson ?? tx.contactName,
        onSuccess: () {
          // Reload settlement history after settlement.
          ref
              .read(settlementHistoryControllerProvider(tx.id).notifier)
              .loadHistory();
        },
      ),
    );
  }
}
