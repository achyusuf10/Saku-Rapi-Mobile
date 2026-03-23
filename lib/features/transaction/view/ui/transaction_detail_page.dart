import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/date_time_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/category/utils/category_icon_mapper.dart';
import 'package:app_saku_rapi/features/transaction/controllers/transaction_form_controller.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_item_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
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
          // Edit button (disabled for adjustments and settlement)
          if (transaction.type != TransactionTypeEnum.adjustment &&
              !transaction.isSettlement)
            IconButton(
              icon: FaIcon(FontAwesomeIcons.penToSquare, size: 18.w),
              onPressed: () =>
                  context.push(AppRouter.transactionForm, extra: transaction),
            ),
          // Delete button (disabled for settlements)
          if (!transaction.isSettlement)
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

          // ─── Items list ───
          if (transaction.items.isNotEmpty) ...[
            SizedBox(height: 20.h),
            _ItemsSection(items: transaction.items),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    if (!context.mounted) return;

    final confirmed = await context.showConfirmDialog(
      title: context.l10n.transactionDeleteConfirm,
      message: context.l10n.transactionDeleteConfirm,
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
        context.closeOverlay();
        context.showAppAlert(
          context.l10n.transactionDeleteSuccess,
          alertType: AlertTypeEnum.success,
        );
        context.pop();
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
      TransactionTypeEnum.transferToAsset => l10n.transactionTransfer,
    };
  }
}

/// Satu baris detail field.
class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(icon, size: 14.w, color: colors.textSecondary),
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
  const _ItemsSection({required this.items});

  final List<TransactionItemModel> items;

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
              items.fold(0.0, (sum, i) => sum + i.amount).toCurrency(),
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
