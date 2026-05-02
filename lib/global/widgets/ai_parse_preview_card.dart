import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/date_time_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/category/controllers/category_controller.dart';
import 'package:app_saku_rapi/features/category/utils/category_display_name.dart';
import 'package:app_saku_rapi/features/category/utils/category_icon_ext.dart';
import 'package:app_saku_rapi/features/voice/models/voice_parse_result_model.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:app_saku_rapi/global/widgets/ai_item_tile.dart';
import 'package:app_saku_rapi/global/widgets/ai_multi_transaction_preview_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Preview card untuk menampilkan hasil AI parse (suara/teks).
///
/// Menampilkan:
/// - Raw transcript (opsional)
/// - Ringkasan transaksi dalam tabel dua kolom tanpa border (tipe, nominal,
///   merchant, wallet, kategori, orang, tanggal, catatan)
/// - Daftar item + total (hanya jika multi-item), di bawah ringkasan
/// - Provider badge
///
/// Dipakai bersama oleh `VoiceInputSheet` dan `TextInputSheet`.
class AiParsePreviewCard extends ConsumerWidget {
  const AiParsePreviewCard({super.key, required this.result});

  /// Hasil parsing dari Edge Function.
  final VoiceParseResultModel result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;

    // Lookup kategori & wallet
    final allCategories = ref.watch(categoryControllerProvider).categories;
    final matchedCategory = result.categoryId != null
        ? allCategories.where((c) => c.id == result.categoryId).firstOrNull
        : null;
    final categoryMap = {
      for (final c in allCategories) c.id: c.displayTitle(l10n),
    };
    final wallets = ref.read(walletListProvider);
    String resolveWallet(String id) =>
        wallets.where((w) => w.id == id).firstOrNull?.name ?? id;

    if (result.isAiMultiTransaction) {
      final metaRowsShared = <_PreviewDetailRow>[
        _PreviewDetailRow(
          icon: _typeIcon(result.type),
          iconColor: _typeColor(result.type, colors),
          label: l10n.voicePreviewType,
          value: _typeLabel(result.type, l10n),
        ),
        if (result.type == TransactionTypeEnum.transfer &&
            result.destinationWalletId != null &&
            result.destinationWalletId!.isNotEmpty)
          _PreviewDetailRow(
            icon: FontAwesomeIcons.arrowRight,
            iconColor: colors.transfer,
            label: l10n.voicePreviewDestWallet,
            value: resolveWallet(result.destinationWalletId!),
          ),
        if (result.withPerson != null && result.withPerson!.isNotEmpty)
          _PreviewDetailRow(
            icon: FontAwesomeIcons.userTag,
            iconColor: colors.expense,
            label: l10n.transactionWithPerson,
            value: result.withPerson!,
          ),
        if (result.date != null)
          _PreviewDetailRow(
            icon: FontAwesomeIcons.calendar,
            iconColor: colors.textSecondary,
            label: l10n.transactionDate,
            value: result.date!.extToFormattedString(
              outputDateFormat: 'dd MMM yyyy, HH:mm',
            ),
          ),
      ];

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: colors.success.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: colors.success.withValues(alpha: 0.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.rawTranscript != null &&
                result.rawTranscript!.isNotEmpty) ...[
              Text(
                l10n.voiceTranscript,
                style: TextStyleConstants.label3.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.15,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '"${result.rawTranscript}"',
                style: TextStyleConstants.b2.copyWith(
                  color: colors.textPrimary,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                ),
              ),
              SizedBox(height: 10.h),
              Divider(height: 1, color: colors.border.withValues(alpha: 0.12)),
              SizedBox(height: 10.h),
            ],
            _PreviewDetailTable(colors: colors, rows: metaRowsShared),
            SizedBox(height: 10.h),
            AiMultiTransactionPreviewList(
              slices: result.aiTransactions!,
              showOcrAttachmentHint: false,
              rootSuggestedWalletId: result.suggestedWalletId,
            ),
            SizedBox(height: 8.h),
            _AiPreviewProviderChip(
              colors: colors,
              label: result.provider ?? 'AI',
            ),
          ],
        ),
      );
    }

    final hasMultipleItems = result.items.length > 1;
    final unifiedMultiItemCategory =
        hasMultipleItems &&
        (result.type == TransactionTypeEnum.expense ||
            result.type == TransactionTypeEnum.income);
    final hasRootCategoryDisplay =
        matchedCategory != null ||
        (result.categoryKeyword != null && result.categoryKeyword!.isNotEmpty);

    final metaRows = <_PreviewDetailRow>[
      _PreviewDetailRow(
        icon: _typeIcon(result.type),
        iconColor: _typeColor(result.type, colors),
        label: l10n.voicePreviewType,
        value: _typeLabel(result.type, l10n),
      ),
      if (!hasMultipleItems && result.amount != null && result.amount! > 0)
        _PreviewDetailRow(
          icon: FontAwesomeIcons.moneyBill,
          iconColor: colors.primary,
          label: l10n.transactionAmount,
          value: result.amount!.toCurrency(),
        ),
      if (result.merchantName != null && result.merchantName!.isNotEmpty)
        _PreviewDetailRow(
          icon: FontAwesomeIcons.store,
          iconColor: colors.info,
          label: l10n.transactionMerchant,
          value: result.merchantName!,
        ),
      if (result.suggestedWalletId != null &&
          result.suggestedWalletId!.isNotEmpty)
        _PreviewDetailRow(
          icon: FontAwesomeIcons.wallet,
          iconColor: colors.transfer,
          label: l10n.transactionWallet,
          value: resolveWallet(result.suggestedWalletId!),
        ),
      if (result.type == TransactionTypeEnum.transfer &&
          result.destinationWalletId != null &&
          result.destinationWalletId!.isNotEmpty)
        _PreviewDetailRow(
          icon: FontAwesomeIcons.arrowRight,
          iconColor: colors.transfer,
          label: l10n.voicePreviewDestWallet,
          value: resolveWallet(result.destinationWalletId!),
        ),
      if (hasRootCategoryDisplay)
        _PreviewDetailRow(
          icon: FontAwesomeIcons.tag,
          iconColor: colors.accent,
          label: l10n.transactionCategory,
          value: matchedCategory?.name ?? result.categoryKeyword!,
          leading: matchedCategory?.toIcon(
            size: 11,
            showBackground: false,
            colorOverride: colors.accent,
          ),
        ),
      if (result.withPerson != null && result.withPerson!.isNotEmpty)
        _PreviewDetailRow(
          icon: FontAwesomeIcons.userTag,
          iconColor: colors.expense,
          label: l10n.transactionWithPerson,
          value: result.withPerson!,
        ),
      if (result.date != null)
        _PreviewDetailRow(
          icon: FontAwesomeIcons.calendar,
          iconColor: colors.textSecondary,
          label: l10n.transactionDate,
          value: result.date!.extToFormattedString(
            outputDateFormat: 'dd MMM yyyy, HH:mm',
          ),
        ),
      if (result.note != null && result.note!.isNotEmpty)
        _PreviewDetailRow(
          icon: FontAwesomeIcons.noteSticky,
          iconColor: colors.textSecondary,
          label: l10n.transactionNote,
          value: result.note!,
        ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: colors.success.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: colors.success.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Transcript asli ──
          if (result.rawTranscript != null &&
              result.rawTranscript!.isNotEmpty) ...[
            Text(
              l10n.voiceTranscript,
              style: TextStyleConstants.label3.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.15,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              '"${result.rawTranscript}"',
              style: TextStyleConstants.b2.copyWith(
                color: colors.textPrimary,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w400,
                height: 1.45,
              ),
            ),
            SizedBox(height: 10.h),
            Divider(height: 1, color: colors.border.withValues(alpha: 0.12)),
            SizedBox(height: 10.h),
          ],

          // Ringkasan transaksi (tabel dua kolom tanpa border)
          _PreviewDetailTable(colors: colors, rows: metaRows),

          // Item + total hanya setelah semua ringkasan
          if (hasMultipleItems) ...[
            SizedBox(height: 10.h),
            Divider(height: 1, color: colors.border.withValues(alpha: 0.12)),
            SizedBox(height: 10.h),
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.list,
                  size: 12.w,
                  color: colors.accent.withValues(alpha: 0.9),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    l10n.aiPreviewItemsHeader(result.items.length),
                    style: TextStyleConstants.label2.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            ...result.items.asMap().entries.map(
              (e) => AiItemTile(
                index: e.key,
                name: e.value.name,
                qty: e.value.qty,
                unitPrice: e.value.unitPrice,
                subtotal: e.value.subtotal,
                categoryName: unifiedMultiItemCategory || hasRootCategoryDisplay
                    ? null
                    : (e.value.categoryId != null
                          ? categoryMap[e.value.categoryId]
                          : null),
              ),
            ),
            SizedBox(height: 6.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: colors.accent.withValues(alpha: 0.14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.aiPreviewGrandTotal,
                    style: TextStyleConstants.label2.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                  Text(
                    result.itemsTotal.toCurrency(),
                    style: TextStyleConstants.b1.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.accent,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            if (result.amount != null &&
                result.amount! > 0 &&
                (result.itemsTotal - result.amount!).abs() > 1) ...[
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: colors.expense.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.circleExclamation,
                      size: 12.w,
                      color: colors.expense,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        l10n.aiPreviewTotalMismatch(
                          result.itemsTotal.toCurrency(),
                          result.amount!.toCurrency(),
                        ),
                        style: TextStyleConstants.label3.copyWith(
                          color: colors.expense,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          // ── Provider badge ──
          SizedBox(height: hasMultipleItems ? 8.h : 10.h),
          _AiPreviewProviderChip(
            colors: colors,
            label: result.provider ?? 'AI',
          ),
        ],
      ),
    );
  }

  /// Icon untuk tipe transaksi.
  IconData _typeIcon(TransactionTypeEnum type) {
    return switch (type) {
      TransactionTypeEnum.income => FontAwesomeIcons.arrowDown,
      TransactionTypeEnum.expense => FontAwesomeIcons.arrowUp,
      TransactionTypeEnum.transfer => FontAwesomeIcons.arrowRightArrowLeft,
      TransactionTypeEnum.debt => FontAwesomeIcons.handHoldingDollar,
      TransactionTypeEnum.loan => FontAwesomeIcons.handHoldingHand,
      _ => FontAwesomeIcons.circleQuestion,
    };
  }

  /// Warna untuk tipe transaksi.
  Color _typeColor(TransactionTypeEnum type, dynamic colors) {
    return switch (type) {
      TransactionTypeEnum.income => colors.income as Color,
      TransactionTypeEnum.expense => colors.expense as Color,
      TransactionTypeEnum.transfer => colors.transfer as Color,
      TransactionTypeEnum.debt => colors.expense as Color,
      TransactionTypeEnum.loan => colors.income as Color,
      _ => colors.textSecondary as Color,
    };
  }

  /// Label untuk tipe transaksi.
  String _typeLabel(TransactionTypeEnum type, dynamic l10n) {
    return switch (type) {
      TransactionTypeEnum.income => l10n.transactionIncome as String,
      TransactionTypeEnum.expense => l10n.transactionExpense as String,
      TransactionTypeEnum.transfer => l10n.transactionTransfer as String,
      TransactionTypeEnum.debt => l10n.transactionDebt as String,
      TransactionTypeEnum.loan => l10n.transactionLoan as String,
      _ => type.toDbValue(),
    };
  }
}

class _PreviewDetailRow {
  const _PreviewDetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.leading,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Widget? leading;
}

/// Tabel dua kolom tanpa border: label + ikon kiri, nilai kanan.
class _PreviewDetailTable extends StatelessWidget {
  const _PreviewDetailTable({required this.colors, required this.rows});

  final dynamic colors;
  final List<_PreviewDetailRow> rows;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 2.w),
      child: Table(
        columnWidths: {0: FlexColumnWidth(1.05), 1: FlexColumnWidth(1.35)},
        defaultVerticalAlignment: TableCellVerticalAlignment.top,
        children: [
          for (var i = 0; i < rows.length; i++)
            TableRow(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i < rows.length - 1 ? 8.h : 0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 1.h),
                        child: SizedBox(
                          width: 16.w,
                          child:
                              rows[i].leading ??
                              FaIcon(
                                rows[i].icon,
                                size: 11.w,
                                color: rows[i].iconColor,
                              ),
                        ),
                      ),
                      SizedBox(width: 5.w),
                      Expanded(
                        child: Text(
                          rows[i].label,
                          style: TextStyleConstants.label2.copyWith(
                            color: colors.textSecondary,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i < rows.length - 1 ? 8.h : 0,
                    left: 4.w,
                  ),
                  child: Text(
                    rows[i].value,
                    style: TextStyleConstants.b2.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Chip kecil kanan bawah: nama provider AI (Voice / Text preview).
class _AiPreviewProviderChip extends StatelessWidget {
  const _AiPreviewProviderChip({required this.colors, required this.label});

  final dynamic colors;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: colors.primary.withValues(alpha: 0.12)),
        ),
        child: Text(
          label,
          style: TextStyleConstants.label3.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}
