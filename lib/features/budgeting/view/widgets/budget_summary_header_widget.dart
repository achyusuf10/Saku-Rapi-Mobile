import 'dart:math';

import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/budgeting/models/budget_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Header ringkasan budget di `BudgetListScreen`.
///
/// Struktur:
/// 1. Semicircle gauge (CustomPainter)
/// 2. Row 3 kolom: total anggaran | total pengeluaran | sisa hari
/// 3. CTA button "Membuat Anggaran"
class BudgetSummaryHeaderWidget extends StatelessWidget {
  const BudgetSummaryHeaderWidget({
    super.key,
    required this.summary,
    required this.onCreateTapped,
  });

  final BudgetSummaryModel summary;
  final VoidCallback onCreateTapped;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final remaining = summary.remainingAmount;
    final isPositive = remaining >= 0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          SizedBox(height: 16.h),

          // ── A. Semicircle Gauge ──
          SizedBox(
            height: 160.h,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                CustomPaint(
                  size: Size(260.r, 130.r),
                  painter: _BudgetGaugePainter(
                    progress: summary.usagePercentage.clamp(0.0, 1.0),
                    statusColor: _statusColor(context, summary.status),
                    backgroundColor: colors.surface,
                  ),
                ),
                Positioned(
                  bottom: 8.h,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.budgetSpendableLabel,
                        style: TextStyleConstants.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${isPositive ? '+' : ''}${remaining.toCurrency()}',
                        style: TextStyleConstants.h5.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isPositive ? colors.income : colors.expense,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 12.h),

          // ── B. Row Ringkasan 3 Kolom ──
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Kolom kiri: Total anggaran
                  Expanded(
                    child: _SummaryColumn(
                      value: summary.totalAmount.toCompactCurrency(),
                      label: l10n.budgetTotalBudgetLabel,
                    ),
                  ),
                  VerticalDivider(width: 1, thickness: 1, color: colors.border),
                  // Kolom tengah: Total pengeluaran
                  Expanded(
                    child: _SummaryColumn(
                      value: summary.totalUsedAmount.toCurrency(),
                      label: l10n.budgetUsed,
                    ),
                  ),
                  VerticalDivider(width: 1, thickness: 1, color: colors.border),
                  // Kolom kanan: Akhir bulan
                  Expanded(
                    child: _SummaryColumn(
                      value: l10n.budgetDaysRemaining(
                        summary.daysRemainingInMonth,
                      ),
                      label: l10n.budgetEndOfMonthLabel,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 8.h),

          // ── C. CTA Membuat Anggaran ──
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onCreateTapped,
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 14.h),
              ),
              child: Text(
                l10n.budgetAdd,
                style: TextStyleConstants.b1.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Color _statusColor(BuildContext context, BudgetStatus status) {
    final colors = context.colors;
    return switch (status) {
      BudgetStatus.safe => colors.primary,
      BudgetStatus.warning => colors.warning,
      BudgetStatus.overBudget => colors.expense,
    };
  }
}

/// Kolom single dalam row 3-kolom ringkasan.
class _SummaryColumn extends StatelessWidget {
  const _SummaryColumn({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyleConstants.b1.copyWith(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyleConstants.caption.copyWith(
            color: context.colors.textSecondary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
        ),
      ],
    );
  }
}

/// Painter setengah lingkaran (semicircle gauge) untuk indikator budget.
///
/// - Background arc: tipis, warna surface
/// - Foreground arc: tebal, warna sesuai status
/// - Dot indicator di ujung foreground arc
class _BudgetGaugePainter extends CustomPainter {
  _BudgetGaugePainter({
    required this.progress,
    required this.statusColor,
    required this.backgroundColor,
  });

  final double progress;
  final Color statusColor;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 14.r;

    // Background arc
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.r
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      bgPaint,
    );

    // Foreground arc
    final fgPaint = Paint()
      ..color = statusColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.r
      ..strokeCap = StrokeCap.round;

    final sweepAngle = pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      sweepAngle,
      false,
      fgPaint,
    );

    // Dot indicator di ujung foreground arc
    final dotAngle = pi + sweepAngle;
    final dotOffset = Offset(
      center.dx + radius * cos(dotAngle),
      center.dy + radius * sin(dotAngle),
    );

    // Shadow / glow
    final glowPaint = Paint()
      ..color = statusColor.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(dotOffset, 8.r, glowPaint);

    // Dot
    final dotPaint = Paint()
      ..color = statusColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(dotOffset, 6.r, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _BudgetGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.statusColor != statusColor;
  }
}
