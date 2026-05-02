import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/category/utils/category_catalog_localizations.dart';
import 'package:app_saku_rapi/core/utils/color_utils.dart';
import 'package:app_saku_rapi/features/reports/models/report_model.dart';
import 'package:app_saku_rapi/global/widgets/saku_category_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Pie chart breakdown per kategori menggunakan Syncfusion.
class ReportCategoryPieChart extends StatelessWidget {
  const ReportCategoryPieChart({
    super.key,
    required this.categories,
    required this.total,
  });

  final List<ReportCategoryBreakdownModel> categories;
  final double total;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return SizedBox(height: 100.h);

    final colors = context.colors;
    final l10n = context.l10n;

    return SizedBox(
      height: 280.h,
      child: SfCircularChart(
        margin: EdgeInsets.zero,
        tooltipBehavior: TooltipBehavior(
          color: colors.surface,
          borderColor: colors.border,
          borderWidth: 1,
          enable: true,
          header: '',
          builder: (data, point, series, pointIdx, seriesIdx) {
            final cat = data as ReportCategoryBreakdownModel;
            final catColor = parseHexColor(cat.categoryColor);
            final displayName = resolvedCategoryDisplayName(
              l10n: l10n,
              rawName: cat.categoryName,
              ownership: cat.categoryOwnership,
            );
            final percent = total > 0
                ? (cat.amount / total * 100).toStringAsFixed(1)
                : '0.0';
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
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
                    '$displayName · $percent%',
                    style: TextStyleConstants.label2.copyWith(
                      color: colors.textPrimary,
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
            xValueMapper: (cat, _) => cat.categoryId,
            yValueMapper: (cat, _) => cat.amount,
            pointColorMapper: (cat, _) => parseHexColor(cat.categoryColor),
            innerRadius: '50%',
            radius: '70%',
            strokeWidth: 1.5,
            strokeColor: colors.surface,
            dataLabelSettings: DataLabelSettings(
              isVisible: true,
              labelPosition: ChartDataLabelPosition.outside,
              labelIntersectAction: LabelIntersectAction.none,
              connectorLineSettings: ConnectorLineSettings(
                length: '20%',
                type: ConnectorType.curve,
                color: colors.border,
              ),
              builder: (data, point, series, pointIdx, seriesIdx) {
                final cat = data as ReportCategoryBreakdownModel;
                final catColor = parseHexColor(cat.categoryColor);
                final ratio = total > 0 ? cat.amount / total : 0.0;
                final percent = (ratio * 100).toStringAsFixed(0);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SakuCategoryIcon(
                      iconName: cat.categoryIcon,
                      color: catColor,
                      backgroundFill: parseHexColor(cat.categoryBackgroundColor),
                      size: 18,
                      iconSize: 9,
                      circular: true,
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      '$percent%',
                      style: TextStyleConstants.label3.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
