import 'dart:math';

import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/budget/controllers/budget_controller.dart';
import 'package:app_saku_rapi/features/budget/view/widgets/budget_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Kartu ringkasan budget di bagian atas halaman.
///
/// Menampilkan:
/// - Gauge arc melingkar yang menunjukkan pemakaian
/// - Total yang bisa dibelanjakan (spendable)
/// - Info statistik: total anggaran, total pengeluaran, sisa hari
class BudgetSummaryCard extends ConsumerWidget {
  const BudgetSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final budgets = ref.watch(budgetByPeriodProvider);

    final totalBudget = ref.watch(budgetTotalAmountProvider);
    final totalUsed = ref.watch(budgetTotalUsedProvider);
    final spendable = ref.watch(budgetSpendableProvider);
    final ratio = totalBudget > 0 ? totalUsed / totalBudget : 0.0;

    // Hitung sisa hari dari budget terdekat yang akan berakhir
    int daysRemaining = 0;
    if (budgets.isNotEmpty) {
      daysRemaining = budgets
          .map((b) => b.daysRemaining)
          .reduce((a, b) => a < b ? a : b);
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: colors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // ─── Gauge ───
          SizedBox(
            width: 180.w,
            height: 110.h,
            child: CustomPaint(
              painter: _BudgetGaugePainter(
                ratio: ratio,
                trackColor: colors.surfaceVariant,
                fillColor: BudgetProgressBar.colorForRatio(ratio, context),
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 16.h),
                  child: Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      color: BudgetProgressBar.colorForRatio(ratio, context),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: BudgetProgressBar.colorForRatio(
                            ratio,
                            context,
                          ).withValues(alpha: 0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 4.h),

          // ─── Label ───
          Text(
            l10n.budgetSpendableLabel,
            style: TextStyleConstants.caption.copyWith(
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: 4.h),

          // ─── Spendable amount ───
          Text(
            spendable >= 0
                ? '+${spendable.toCurrency()}'
                : spendable.toCurrency(),
            style: TextStyleConstants.h5.copyWith(
              fontWeight: FontWeight.bold,
              color: spendable > 0 ? colors.income : colors.error,
            ),
          ),
          SizedBox(height: 20.h),

          // ─── Stats row ───
          Row(
            children: [
              _StatItem(
                value: totalBudget.toCompactCurrency(),
                label: l10n.budgetTotalBudgetLabel,
              ),
              Container(
                width: 1,
                height: 32.h,
                color: colors.border.withValues(alpha: 0.3),
              ),
              _StatItem(
                value: totalUsed.toCompactCurrency(),
                label: l10n.budgetUsed,
              ),
              Container(
                width: 1,
                height: 32.h,
                color: colors.border.withValues(alpha: 0.3),
              ),
              _StatItem(
                value: l10n.budgetDaysRemaining(daysRemaining),
                label: l10n.budgetEndOfPeriodLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────── Stat Item ─────────────────

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyleConstants.b2.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyleConstants.label3.copyWith(
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ───────────────── Gauge Painter ─────────────────

class _BudgetGaugePainter extends CustomPainter {
  _BudgetGaugePainter({
    required this.ratio,
    required this.trackColor,
    required this.fillColor,
  });

  final double ratio;
  final Color trackColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = min(size.width / 2, size.height) - 8;
    const startAngle = pi; // 180° (left)
    const sweepAngle = pi; // 180° arc (semicircle)
    final strokeWidth = 10.0;

    // Track (background arc)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Fill (foreground arc)
    final clampedRatio = ratio.clamp(0.0, 1.0);
    if (clampedRatio > 0) {
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * clampedRatio,
        false,
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BudgetGaugePainter oldDelegate) {
    return oldDelegate.ratio != ratio ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.fillColor != fillColor;
  }
}
