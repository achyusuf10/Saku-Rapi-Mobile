import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/utils/color_utils.dart';
import 'package:app_saku_rapi/features/category/utils/category_icon_mapper.dart';
import 'package:app_saku_rapi/features/reports/models/report_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Pie chart breakdown per kategori menggunakan Syncfusion.
///
/// Menampilkan doughnut chart dengan icon + persentase di label,
/// dan wrapped legend di bawah chart.
class ReportCategoryPieChart extends StatelessWidget {
  const ReportCategoryPieChart({
    super.key,
    required this.categories,
    required this.total,
    this.onCategoryTap,
  });

  final List<ReportCategoryBreakdownModel> categories;
  final double total;
  final void Function(ReportCategoryBreakdownModel category)? onCategoryTap;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return SizedBox(height: 100.h);

    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // ─── Doughnut Chart ───
        SizedBox(
          height: 280.h,
          child: SfCircularChart(
            margin: EdgeInsets.zero,
            tooltipBehavior: TooltipBehavior(
              enable: true,
              header: '',
              builder: (data, point, series, pointIdx, seriesIdx) {
                final cat = data as ReportCategoryBreakdownModel;
                final catColor = parseHexColor(cat.categoryColor);
                final percent = total > 0
                    ? (cat.amount / total * 100).toStringAsFixed(1)
                    : '0.0';
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F2937) : Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10.w,
                        height: 10.w,
                        decoration: BoxDecoration(
                          color: catColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        '${cat.categoryName} · $percent%',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            series: <CircularSeries<ReportCategoryBreakdownModel, String>>[
              DoughnutSeries<ReportCategoryBreakdownModel, String>(
                dataSource: categories,
                xValueMapper: (cat, _) => cat.categoryName,
                yValueMapper: (cat, _) => cat.amount,
                pointColorMapper: (cat, _) => parseHexColor(cat.categoryColor),
                innerRadius: '50%',
                radius: '70%',
                strokeWidth: 1.5,
                strokeColor: colors.surface,
                dataLabelSettings: DataLabelSettings(
                  isVisible: true,
                  labelPosition: ChartDataLabelPosition.outside,
                  labelIntersectAction: LabelIntersectAction.shift,
                  connectorLineSettings: ConnectorLineSettings(
                    length: '18%',
                    type: ConnectorType.curve,
                    color: colors.textSecondary.withValues(alpha: 0.4),
                  ),
                  builder: (data, point, series, pointIdx, seriesIdx) {
                    final cat = data as ReportCategoryBreakdownModel;
                    final catColor = parseHexColor(cat.categoryColor);
                    final ratio = total > 0 ? cat.amount / total : 0.0;
                    final percent = (ratio * 100).toStringAsFixed(0);
                    return GestureDetector(
                      onTap: onCategoryTap != null
                          ? () => onCategoryTap!(cat)
                          : null,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 24.w,
                            height: 24.w,
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Center(
                              child: FaIcon(
                                CategoryIconMapper.getIcon(cat.categoryIcon),
                                size: 11.w,
                                color: catColor,
                              ),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            '$percent%',
                            style: TextStyleConstants.label3.copyWith(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 9.sp,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // Tap pada irisan pie chart tidak navigasi — hanya tooltip.
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // ─── Wrapped Legend ───
        Wrap(
          spacing: 14.w,
          runSpacing: 10.h,
          children: categories.map((cat) {
            final catColor = parseHexColor(cat.categoryColor);
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onCategoryTap != null ? () => onCategoryTap!(cat) : null,
                borderRadius: BorderRadius.circular(6.r),
                splashColor: catColor.withValues(alpha: 0.12),
                highlightColor: catColor.withValues(alpha: 0.06),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
                  child: _PieLegendItem(
                    icon: CategoryIconMapper.getIcon(cat.categoryIcon),
                    color: catColor,
                    label: cat.categoryName,
                    textColor: colors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PieLegendItem extends StatelessWidget {
  const _PieLegendItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.textColor,
  });

  final IconData icon;
  final Color color;
  final String label;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24.w,
          height: 24.w,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Center(
            child: FaIcon(icon, size: 12.w, color: color),
          ),
        ),
        SizedBox(width: 5.w),
        Text(
          label,
          style: TextStyleConstants.label2.copyWith(color: textColor),
        ),
      ],
    );
  }
}
