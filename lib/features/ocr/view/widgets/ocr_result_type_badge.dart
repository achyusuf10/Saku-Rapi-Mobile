import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Badge pill untuk menampilkan tipe transaksi hasil OCR (pengeluaran, pemasukan, …).
class OcrResultTypeBadge extends StatelessWidget {
  /// [type] adalah string dari model: `expense`, `income`, `transfer`, `debt`, `loan`.
  const OcrResultTypeBadge({
    super.key,
    required this.type,
    required this.colors,
    required this.l10n,
  });

  /// Nilai `result.type` dari parser.
  final String type;

  /// Token tema.
  final dynamic colors;

  /// Lokalisasi (AppLocalizations via extension).
  final dynamic l10n;

  @override
  Widget build(BuildContext context) {
    // Map tipe → label, warna chip, ikon.
    final (String label, Color color, IconData icon) = switch (type) {
      'income' => (
        l10n.ocrTypeIncome as String,
        colors.income as Color,
        FontAwesomeIcons.arrowDown,
      ),
      'transfer' => (
        l10n.ocrTypeTransfer as String,
        colors.info as Color,
        FontAwesomeIcons.rightLeft,
      ),
      'debt' => (
        l10n.ocrTypeDebt as String,
        colors.expense as Color,
        FontAwesomeIcons.handHoldingDollar,
      ),
      'loan' => (
        l10n.ocrTypeLoan as String,
        colors.accent as Color,
        FontAwesomeIcons.handHoldingDollar,
      ),
      _ => (
        l10n.ocrTypeExpense as String,
        colors.expense as Color,
        FontAwesomeIcons.arrowUp,
      ),
    };

    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, size: 12.w, color: color),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyleConstants.label2.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
