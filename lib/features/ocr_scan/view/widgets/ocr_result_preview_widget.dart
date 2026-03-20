import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/global/services/transaction_parser_service.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Preview hasil parsing OCR sebelum handoff ke form.
///
/// Menampilkan merchant, grand total, jumlah item, dan dua tombol:
/// "Lanjutkan" (navigate ke form) dan "Scan Ulang".
class OcrResultPreviewWidget extends StatelessWidget {
  const OcrResultPreviewWidget({
    super.key,
    required this.result,
    required this.onContinue,
    required this.onRescan,
  });

  /// Hasil parsing OCR.
  final OcrParseResult result;

  /// Callback saat user tap "Lanjutkan".
  final VoidCallback onContinue;

  /// Callback saat user tap "Scan Ulang".
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;
    final l10n = context.l10n;

    return Container(
      padding: EdgeInsets.only(
        top: 16.h,
        left: 16.w,
        right: 16.w,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
      ),
      decoration: BoxDecoration(
        color: appColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle bar ──
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: appColors.border,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 16.h),

          // ── Title ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                FontAwesomeIcons.receipt,
                color: appColors.primary,
                size: 20.r,
              ),
              SizedBox(width: 8.w),
              Text(
                l10n.ocrResultTitle,
                style: TextStyleConstants.h7.copyWith(
                  fontWeight: FontWeight.w700,
                  color: appColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // ── Info rows ──
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: appColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                // Merchant
                if (result.merchantName != null) ...[
                  _InfoRow(
                    label: l10n.ocrMerchant,
                    value: result.merchantName!,
                    icon: FontAwesomeIcons.store,
                    color: appColors.primary,
                  ),
                  SizedBox(height: 12.h),
                ],

                // Grand Total
                if (result.grandTotal != null) ...[
                  _InfoRow(
                    label: l10n.ocrGrandTotal,
                    value: result.grandTotal!.toCurrency(),
                    icon: FontAwesomeIcons.moneyBill,
                    color: appColors.expense,
                    isBold: true,
                  ),
                  SizedBox(height: 12.h),
                ],

                // Item count
                _InfoRow(
                  label: l10n.ocrItemCount(result.items.length),
                  value: result.itemsTotal.toCurrency(),
                  icon: FontAwesomeIcons.listCheck,
                  color: appColors.income,
                ),

                // Auto-balance badge
                if (_hasAutoBalanceItem) ...[
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: appColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(
                          FontAwesomeIcons.scaleBalanced,
                          color: appColors.warning,
                          size: 12.r,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          l10n.ocrAutoBalance,
                          style: TextStyleConstants.caption.copyWith(
                            color: appColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 20.h),

          // ── Item list preview (max 5 items) ──
          if (result.items.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: appColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < result.items.length && i < 5; i++) ...[
                    _ItemRow(item: result.items[i]),
                    if (i < result.items.length - 1 && i < 4)
                      Divider(height: 16.h, color: appColors.border),
                  ],
                  if (result.items.length > 5) ...[
                    SizedBox(height: 8.h),
                    Center(
                      child: Text(
                        '+${result.items.length - 5} item lainnya',
                        style: TextStyleConstants.caption.copyWith(
                          color: appColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 20.h),
          ],

          // ── Buttons ──
          SizedBox(
            width: double.infinity,
            child: SakuButton(text: l10n.ocrContinue, onPressed: onContinue),
          ),
          SizedBox(height: 8.h),
          SizedBox(
            width: double.infinity,
            child: SakuButton(
              text: l10n.ocrRescan,
              isOutlined: true,
              onPressed: onRescan,
            ),
          ),
        ],
      ),
    );
  }

  /// Cek apakah ada item Auto-Balance (selisih).
  bool get _hasAutoBalanceItem =>
      result.items.any((i) => i.name == 'Pajak / Biaya Lain / Selisih');
}

/// Satu baris info (label + value) dengan icon di kiri.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isBold = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;

    return Row(
      children: [
        FaIcon(icon, color: color, size: 14.r),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            label,
            style: TextStyleConstants.b2.copyWith(
              color: appColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyleConstants.b1.copyWith(
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: appColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Satu baris item dari struk.
class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final OcrItemResult item;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;

    return Row(
      children: [
        Expanded(
          child: Text(
            item.name,
            style: TextStyleConstants.b2.copyWith(color: appColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          item.amount.toCurrency(),
          style: TextStyleConstants.b2.copyWith(
            fontWeight: FontWeight.w600,
            color: appColors.expense,
          ),
        ),
      ],
    );
  }
}
