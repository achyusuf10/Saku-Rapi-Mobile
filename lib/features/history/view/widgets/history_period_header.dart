import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/date_time_ext.dart';
import 'package:app_saku_rapi/features/history/controllers/history_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Header navigasi periode "< Februari 2026 >".
///
/// Tap `<` atau `>` mengganti bulan aktif.
/// Mendukung swipe gesture horizontal pada seluruh area.
class HistoryPeriodHeader extends ConsumerWidget {
  const HistoryPeriodHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = context.colors;
    final historyState = ref.watch(historyControllerProvider);
    final controller = ref.read(historyControllerProvider.notifier);

    final periodLabel = historyState.activePeriodStart.extToFormattedString(
      outputDateFormat: 'MMMM yyyy',
    );

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        if (details.primaryVelocity! > 0) {
          controller.goToPreviousPeriod();
        } else if (details.primaryVelocity! < 0) {
          controller.goToNextPeriod();
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Tombol Previous ──
            _NavButton(
              icon: FontAwesomeIcons.chevronLeft,
              onTap: controller.goToPreviousPeriod,
              color: appColors.textSecondary,
            ),

            SizedBox(width: 16.w),

            // ── Label Bulan Tahun ──
            Text(
              periodLabel,
              style: TextStyleConstants.h7.copyWith(
                fontWeight: FontWeight.w700,
                color: appColors.textPrimary,
              ),
            ),

            SizedBox(width: 16.w),

            // ── Tombol Next ──
            _NavButton(
              icon: FontAwesomeIcons.chevronRight,
              onTap: controller.goToNextPeriod,
              color: appColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tombol navigasi kecil (< atau >).
class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 36.r,
        height: 36.r,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: FaIcon(icon, size: 14.r, color: color),
        ),
      ),
    );
  }
}
