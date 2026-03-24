import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/dashboard/controllers/dashboard_controller.dart';
import 'package:app_saku_rapi/features/dashboard/view/widgets/dashboard_comparison_chart.dart';
import 'package:app_saku_rapi/features/dashboard/view/widgets/dashboard_trend_report_chart.dart';
import 'package:app_saku_rapi/global/widgets/saku_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Carousel wrapper untuk 2 halaman chart dashboard:
/// 1. Laporan Pengeluaran (bar chart)
/// 2. Laporan Tren (cumulative line chart)
///
/// Dilengkapi navigasi arrows, dot indicator, judul halaman, dan mode toggle.
class DashboardChartCarousel extends ConsumerStatefulWidget {
  const DashboardChartCarousel({super.key});

  @override
  ConsumerState<DashboardChartCarousel> createState() =>
      _DashboardChartCarouselState();
}

class _DashboardChartCarouselState
    extends ConsumerState<DashboardChartCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;

  static const _pageCount = 2;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    if (page < 0 || page >= _pageCount) return;
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final dashState = ref.watch(dashboardControllerProvider);
    final isMonthly = dashState.chartMode == DashboardChartMode.monthly;

    final titles = [l10n.dashboardExpenseReport, l10n.dashboardTrendReport];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: SakuCard(
        child: Column(
          children: [
            // ─── Header: arrows + title + mode toggle ───
            Row(
              children: [
                // Left arrow
                _NavArrow(
                  icon: Icons.chevron_left_rounded,
                  enabled: _currentPage > 0,
                  onTap: () => _goToPage(_currentPage - 1),
                ),

                // Title
                Expanded(
                  child: Text(
                    titles[_currentPage],
                    textAlign: TextAlign.center,
                    style: TextStyleConstants.b2.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ),

                // Right arrow
                _NavArrow(
                  icon: Icons.chevron_right_rounded,
                  enabled: _currentPage < _pageCount - 1,
                  onTap: () => _goToPage(_currentPage + 1),
                ),

                SizedBox(width: 8.w),

                // Mode toggle
                _ModeToggle(
                  isMonthly: isMonthly,
                  monthlyLabel: l10n.dashboardMonthlyMode,
                  weeklyLabel: l10n.dashboardWeeklyMode,
                  onToggle: () {
                    ref
                        .read(dashboardControllerProvider.notifier)
                        .toggleChartMode();
                  },
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // ─── PageView ───
            SizedBox(
              // Fixed height to avoid layout jumps
              height: 400.h,
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: const [
                  DashboardComparisonChart(),
                  DashboardTrendReportChart(),
                ],
              ),
            ),
            SizedBox(height: 8.h),

            // ─── Dot Indicator ───
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pageCount, (i) {
                final isActive = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.symmetric(horizontal: 3.w),
                  width: isActive ? 18.w : 6.w,
                  height: 6.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3.r),
                    color: isActive ? colors.primary : colors.border,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Icon(
        icon,
        size: 24.w,
        color: enabled ? colors.textPrimary : colors.border,
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.isMonthly,
    required this.monthlyLabel,
    required this.weeklyLabel,
    required this.onToggle,
  });

  final bool isMonthly;
  final String monthlyLabel;
  final String weeklyLabel;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          color: colors.primaryLight,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isMonthly ? monthlyLabel : weeklyLabel,
              style: TextStyleConstants.label2.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 4.w),
            Icon(Icons.swap_horiz_rounded, size: 14.w, color: colors.primary),
          ],
        ),
      ),
    );
  }
}
