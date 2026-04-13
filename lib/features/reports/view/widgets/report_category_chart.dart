import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/utils/color_utils.dart';
import 'package:app_saku_rapi/features/reports/models/report_model.dart';
import 'package:app_saku_rapi/global/widgets/saku_category_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Category breakdown list dengan icon, progress bar, dan persentase.
class ReportCategoryChart extends StatelessWidget {
  const ReportCategoryChart({
    super.key,
    required this.categories,
    required this.total,
    this.onCategoryTap,
    this.isOthersExpanded = false,
  });

  final List<ReportCategoryBreakdownModel> categories;
  final double total;
  final void Function(ReportCategoryBreakdownModel category)? onCategoryTap;
  final bool isOthersExpanded;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return SizedBox(height: 100.h);

    return Column(
      children: [
        for (int i = 0; i < categories.length; i++) ...[
          if (i > 0) SizedBox(height: 10.h),
          _CategoryRow(
            category: categories[i],
            total: total,
            isExpanded: categories[i].categoryId == '__others__'
                ? isOthersExpanded
                : false,
            onTap: onCategoryTap != null
                ? () => onCategoryTap!(categories[i])
                : null,
          ),
        ],
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.total,
    this.onTap,
    this.isExpanded = false,
  });

  final ReportCategoryBreakdownModel category;
  final double total;
  final VoidCallback? onTap;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ratio = category.ratioOf(total);
    final percent = (ratio * 100).toStringAsFixed(1);
    final catColor = parseHexColor(category.categoryColor);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          // Icon circle
          SakuCategoryIcon(
            iconName: category.categoryIcon,
            color: catColor,
            size: 36,
            iconSize: 16,
            borderRadius: 10,
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
                    if (category.categoryId == '__others__') ...[
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 250),
                        child: FaIcon(
                          FontAwesomeIcons.chevronDown,
                          size: 10.w,
                          color: colors.textSecondary,
                        ),
                      ),
                      SizedBox(width: 6.w),
                    ],
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
                          backgroundColor: colors.surfaceVariant,
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
      ),
    );
  }
}
