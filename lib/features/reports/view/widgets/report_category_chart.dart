import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/features/category/utils/category_icon_mapper.dart';
import 'package:app_saku_rapi/features/reports/models/report_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Category breakdown list dengan icon, progress bar, dan persentase.
///
/// Menggantikan donut chart — lebih informatif dan readable.
class ReportCategoryChart extends StatelessWidget {
  const ReportCategoryChart({
    super.key,
    required this.categories,
    required this.total,
  });

  final List<ReportCategoryBreakdownModel> categories;
  final double total;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return SizedBox(height: 100.h);

    return Column(
      children: [
        for (int i = 0; i < categories.length; i++) ...[
          if (i > 0) SizedBox(height: 10.h),
          _CategoryRow(category: categories[i], total: total, rank: i + 1),
        ],
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.total,
    required this.rank,
  });

  final ReportCategoryBreakdownModel category;
  final double total;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ratio = category.ratioOf(total);
    final percent = (ratio * 100).toStringAsFixed(1);
    final catColor = _parseColor(category.categoryColor);

    return Row(
      children: [
        // Icon circle
        Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: catColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Center(
            child: FaIcon(
              CategoryIconMapper.getIcon(category.categoryIcon),
              size: 16.w,
              color: catColor,
            ),
          ),
        ),
        SizedBox(width: 10.w),
        // Name + progress bar
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      category.categoryName,
                      style: TextStyleConstants.label2.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    category.amount.toCompactCurrency(),
                    style: TextStyleConstants.label2.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5.h),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3.r),
                      child: LinearProgressIndicator(
                        value: ratio.clamp(0.0, 1.0),
                        minHeight: 6.h,
                        backgroundColor: colors.surfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(catColor),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  SizedBox(
                    width: 42.w,
                    child: Text(
                      '$percent%',
                      style: TextStyleConstants.label3.copyWith(
                        color: colors.textSecondary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Color _parseColor(String? hex) {
  if (hex == null || hex.isEmpty) return const Color(0xFF6B7280);
  final clean = hex.replaceFirst('#', '');
  if (clean.length == 6) return Color(int.parse('0xFF$clean'));
  return const Color(0xFF6B7280);
}
