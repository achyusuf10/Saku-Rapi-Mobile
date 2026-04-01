import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/utils/color_utils.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/category/utils/category_icon_mapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Reusable parent category tile dengan expand/collapse children.
///
/// Dipakai di [CategoryPickerSheet] dan [CategoryManagementPage].
/// Visual seragam, behaviour dikontrol via callback.
class CategoryParentListTile extends StatelessWidget {
  const CategoryParentListTile({
    super.key,
    required this.category,
    required this.onTap,
    this.onLongPress,
    this.onChildTap,
    this.onChildLongPress,
    this.isExpanded = true,
    this.onToggleExpand,
    this.isSelected = false,
    this.selectedChildId,
    this.trailing,
    this.childTrailing,
  });

  final CategoryModel category;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<CategoryModel>? onChildTap;
  final ValueChanged<CategoryModel>? onChildLongPress;

  /// Expand/collapse state (default: expanded).
  final bool isExpanded;
  final VoidCallback? onToggleExpand;

  /// Highlight parent sebagai selected.
  final bool isSelected;

  /// ID child yang sedang selected (untuk highlight).
  final String? selectedChildId;

  /// Custom trailing widget untuk parent (misal: more button, lock icon).
  final Widget Function(BuildContext context, CategoryModel category)? trailing;

  /// Custom trailing widget untuk child.
  final Widget Function(BuildContext context, CategoryModel child)?
  childTrailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasChildren = category.children.isNotEmpty;
    final categoryColor = parseHexColor(category.color);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected
            ? categoryColor.withValues(alpha: 0.07)
            : colors.background,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isSelected
              ? categoryColor.withValues(alpha: 0.3)
              : colors.border.withValues(alpha: 0.2),
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: categoryColor.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Parent tile ───
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14.r),
              onTap: onTap,
              onLongPress: onLongPress,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 38.w,
                      height: 38.w,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            categoryColor.withValues(alpha: 0.18),
                            categoryColor.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(11.r),
                      ),
                      child: Center(
                        child: FaIcon(
                          CategoryIconMapper.getIcon(category.icon),
                          size: 15.w,
                          color: category.isHidden
                              ? colors.textSecondary.withValues(alpha: 0.5)
                              : categoryColor,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),

                    // Name + children count
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: TextStyleConstants.b2.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? categoryColor
                                  : category.isHidden
                                  ? colors.textSecondary
                                  : colors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (hasChildren) ...[
                            SizedBox(height: 2.h),
                            Text(
                              '${category.children.length} sub',
                              style: TextStyleConstants.overline.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Selected check
                    if (isSelected)
                      Container(
                        width: 24.w,
                        height: 24.w,
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: FaIcon(
                            FontAwesomeIcons.check,
                            size: 11.w,
                            color: categoryColor,
                          ),
                        ),
                      ),

                    // Custom trailing
                    if (trailing != null) trailing!(context, category),

                    // Expand arrow (jika punya children & ada toggle handler)
                    if (hasChildren && onToggleExpand != null) ...[
                      SizedBox(width: 4.w),
                      IconButton(
                        onPressed: onToggleExpand,
                        padding: EdgeInsets.all(6.w),
                        constraints: const BoxConstraints(),
                        icon: AnimatedRotation(
                          turns: isExpanded ? 0.25 : 0,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child: FaIcon(
                            FontAwesomeIcons.chevronRight,
                            size: 11.w,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // ─── Children (animated expand/collapse) ───
          if (hasChildren)
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: isExpanded
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          child: Divider(
                            height: 1,
                            color: colors.border.withValues(alpha: 0.8),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            right: 8.w,
                            top: 6.h,
                            bottom: 8.h,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: category.children
                                .map(
                                  (child) => CategoryChildListTile(
                                    category: child,
                                    isSelected: selectedChildId == child.id,
                                    onTap: () => onChildTap?.call(child),
                                    onLongPress: onChildLongPress != null
                                        ? () => onChildLongPress!(child)
                                        : null,
                                    trailing: childTrailing,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}

/// Reusable child category tile (indented di bawah parent).
class CategoryChildListTile extends StatelessWidget {
  const CategoryChildListTile({
    super.key,
    required this.category,
    required this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.trailing,
  });

  final CategoryModel category;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final Widget Function(BuildContext context, CategoryModel child)? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final categoryColor = parseHexColor(category.color);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10.r),
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          margin: EdgeInsets.only(left: 16.w, bottom: 2.h),
          decoration: BoxDecoration(
            color: isSelected
                ? categoryColor.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Row(
            children: [
              // Small icon
              Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Center(
                  child: FaIcon(
                    CategoryIconMapper.getIcon(category.icon),
                    size: 11.w,
                    color: category.isHidden
                        ? colors.textSecondary.withValues(alpha: 0.5)
                        : categoryColor,
                  ),
                ),
              ),
              SizedBox(width: 10.w),

              // Name
              Expanded(
                child: Text(
                  category.name,
                  style: TextStyleConstants.caption.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? categoryColor
                        : category.isHidden
                        ? colors.textSecondary
                        : colors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Selected check
              if (isSelected)
                Container(
                  width: 20.w,
                  height: 20.w,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: FaIcon(
                      FontAwesomeIcons.check,
                      size: 9.w,
                      color: categoryColor,
                    ),
                  ),
                ),

              // Custom trailing
              if (trailing != null) trailing!(context, category),
            ],
          ),
        ),
      ),
    );
  }
}
