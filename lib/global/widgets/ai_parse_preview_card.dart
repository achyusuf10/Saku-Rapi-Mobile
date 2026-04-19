import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/date_time_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/category/controllers/category_controller.dart';
import 'package:app_saku_rapi/features/category/utils/category_icon_ext.dart';
import 'package:app_saku_rapi/features/voice/models/voice_parse_result_model.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:app_saku_rapi/global/widgets/ai_item_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Preview card untuk menampilkan hasil AI parse (suara/teks).
///
/// Menampilkan:
/// - Raw transcript (opsional)
/// - Tipe transaksi
/// - Nominal / multi-item (jika items > 1)
/// - Kategori, merchant, wallet, tanggal, catatan
/// - Grand total + mismatch warning (multi-item)
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
    final categoryMap = {for (final c in allCategories) c.id: c.name};
    final wallets = ref.read(walletListProvider);
    String resolveWallet(String id) =>
        wallets.where((w) => w.id == id).firstOrNull?.name ?? id;

    final hasMultipleItems = result.items.length > 1;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colors.success.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: colors.success.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Transcript asli ──
          if (result.rawTranscript != null &&
              result.rawTranscript!.isNotEmpty) ...[
            Text(
              l10n.voiceTranscript,
              style: TextStyleConstants.label2.copyWith(
                color: colors.textSecondary,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              '"${result.rawTranscript}"',
              style: TextStyleConstants.b2.copyWith(
                color: colors.textPrimary,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 12.h),
            Divider(height: 1, color: colors.border.withValues(alpha: 0.15)),
            SizedBox(height: 12.h),
          ],

          // ── Tipe transaksi ──
          _PreviewInfoRow(
            icon: _typeIcon(result.type),
            iconColor: _typeColor(result.type, colors),
            label: l10n.voicePreviewType,
            value: _typeLabel(result.type, l10n),
          ),

          // ── Nominal (single item) ──
          if (!hasMultipleItems &&
              result.amount != null &&
              result.amount! > 0) ...[
            SizedBox(height: 8.h),
            _PreviewInfoRow(
              icon: FontAwesomeIcons.moneyBill,
              iconColor: colors.primary,
              label: l10n.transactionAmount,
              value: result.amount!.toCurrency(),
            ),
          ],

          // ── Kategori (single item) ──
          if (!hasMultipleItems &&
              (matchedCategory != null ||
                  (result.categoryKeyword != null &&
                      result.categoryKeyword!.isNotEmpty))) ...[
            SizedBox(height: 8.h),
            _PreviewInfoRow(
              icon: FontAwesomeIcons.tag,
              iconColor: colors.accent,
              label: l10n.transactionCategory,
              value: matchedCategory?.name ?? result.categoryKeyword!,
              leading: matchedCategory?.toIcon(
                size: 14,
                showBackground: false,
                colorOverride: colors.accent,
              ),
            ),
          ],

          // ── Merchant ──
          if (result.merchantName != null &&
              result.merchantName!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            _PreviewInfoRow(
              icon: FontAwesomeIcons.store,
              iconColor: colors.info,
              label: l10n.transactionMerchant,
              value: result.merchantName!,
            ),
          ],

          // ── Wallet ──
          if (result.suggestedWalletId != null &&
              result.suggestedWalletId!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            _PreviewInfoRow(
              icon: FontAwesomeIcons.wallet,
              iconColor: colors.transfer,
              label: l10n.transactionWallet,
              value: resolveWallet(result.suggestedWalletId!),
            ),
          ],

          // ── Destination wallet (transfer) ──
          if (result.type == TransactionTypeEnum.transfer &&
              result.destinationWalletId != null &&
              result.destinationWalletId!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            _PreviewInfoRow(
              icon: FontAwesomeIcons.arrowRight,
              iconColor: colors.transfer,
              label: l10n.voicePreviewDestWallet,
              value: resolveWallet(result.destinationWalletId!),
            ),
          ],

          // ── Nama orang (hutang/piutang) ──
          if (result.withPerson != null && result.withPerson!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            _PreviewInfoRow(
              icon: FontAwesomeIcons.userTag,
              iconColor: colors.expense,
              label: l10n.transactionWithPerson,
              value: result.withPerson!,
            ),
          ],

          // ── Tanggal ──
          if (result.date != null) ...[
            SizedBox(height: 8.h),
            _PreviewInfoRow(
              icon: FontAwesomeIcons.calendar,
              iconColor: colors.textSecondary,
              label: l10n.transactionDate,
              value: result.date!.extToFormattedString(
                outputDateFormat: 'dd MMM yyyy, HH:mm',
              ),
            ),
          ],

          // ── Catatan ──
          if (result.note != null && result.note!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            _PreviewInfoRow(
              icon: FontAwesomeIcons.noteSticky,
              iconColor: colors.textSecondary,
              label: l10n.transactionNote,
              value: result.note!,
            ),
          ],

          // ── Multi-item section ──
          if (hasMultipleItems) ...[
            SizedBox(height: 14.h),
            Divider(height: 1, color: colors.border.withValues(alpha: 0.15)),
            SizedBox(height: 14.h),

            // Header "X item terdeteksi"
            Row(
              children: [
                FaIcon(FontAwesomeIcons.list, size: 14.w, color: colors.accent),
                SizedBox(width: 8.w),
                Text(
                  l10n.aiPreviewItemsHeader(result.items.length),
                  style: TextStyleConstants.label1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),

            // Daftar item
            ...result.items.asMap().entries.map(
              (e) => AiItemTile(
                index: e.key,
                name: e.value.name,
                qty: e.value.qty,
                unitPrice: e.value.unitPrice,
                subtotal: e.value.subtotal,
                categoryName: e.value.categoryId != null
                    ? categoryMap[e.value.categoryId]
                    : null,
              ),
            ),

            SizedBox(height: 8.h),

            // Grand total
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: colors.accent.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.aiPreviewGrandTotal,
                    style: TextStyleConstants.b1.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    result.itemsTotal.toCurrency(),
                    style: TextStyleConstants.h7.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.accent,
                    ),
                  ),
                ],
              ),
            ),

            // Warning jika total mismatch
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
                      size: 14.w,
                      color: colors.expense,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        l10n.aiPreviewTotalMismatch(
                          result.itemsTotal.toCurrency(),
                          result.amount!.toCurrency(),
                        ),
                        style: TextStyleConstants.caption.copyWith(
                          color: colors.expense,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          // ── Provider badge ──
          SizedBox(height: 12.h),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                result.provider ?? 'AI',
                style: TextStyleConstants.label3.copyWith(
                  color: colors.primary,
                ),
              ),
            ),
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

/// Baris info dalam preview card: [icon] [label] [value].
class _PreviewInfoRow extends StatelessWidget {
  const _PreviewInfoRow({
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

  /// Widget custom leading (override icon + iconColor).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20.w,
          child: leading ?? FaIcon(icon, size: 14.w, color: iconColor),
        ),
        SizedBox(width: 8.w),
        SizedBox(
          width: 80.w,
          child: Text(
            label,
            style: TextStyleConstants.label2.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyleConstants.b2.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
