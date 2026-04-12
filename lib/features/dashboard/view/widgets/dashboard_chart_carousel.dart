import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/dashboard/controllers/dashboard_chart_controller.dart';
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
    final chartState = ref.watch(dashboardChartControllerProvider);
    final chartMode = chartState.chartMode;

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
                      fontWeight: FontWeight.w600,
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

                // Mode selector (PopupMenu)
                _ModeSelector(
                  currentMode: chartMode,
                  onSelect: (mode) {
                    ref
                        .read(dashboardChartControllerProvider.notifier)
                        .selectChartMode(mode);
                  },
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // ─── PageView ───
            SizedBox(
              // Fixed height to avoid layout jumps
              height: 400.w,
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

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.currentMode, required this.onSelect});

  final DashboardChartMode currentMode;
  final ValueChanged<DashboardChartMode> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    final items = [
      (DashboardChartMode.monthly, l10n.dashboardMonthlyMode),
      (DashboardChartMode.weekly, l10n.dashboardWeeklyMode),
      (DashboardChartMode.daily, l10n.dashboardDailyMode),
    ];

    final currentLabel = switch (currentMode) {
      DashboardChartMode.monthly => l10n.dashboardMonthlyMode,
      DashboardChartMode.weekly => l10n.dashboardWeeklyMode,
      DashboardChartMode.daily => l10n.dashboardDailyMode,
    };

    return PopupMenuButton<DashboardChartMode>(
      onSelected: onSelect,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      color: colors.surface,
      elevation: 3,
      itemBuilder: (_) => items
          .map(
            (entry) => PopupMenuItem<DashboardChartMode>(
              value: entry.$1,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.$2,
                      style: TextStyleConstants.label1.copyWith(
                        color: colors.textPrimary,
                        fontWeight: entry.$1 == currentMode
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (entry.$1 == currentMode)
                    Icon(
                      Icons.check_rounded,
                      size: 16.w,
                      color: colors.primary,
                    ),
                ],
              ),
            ),
          )
          .toList(),
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
              currentLabel,
              style: TextStyleConstants.label2.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 2.w),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 16.w,
              color: colors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
