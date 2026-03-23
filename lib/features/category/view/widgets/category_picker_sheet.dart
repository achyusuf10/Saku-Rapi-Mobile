import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/category/controllers/category_controller.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/category/utils/category_icon_mapper.dart';
import 'package:app_saku_rapi/global/widgets/saku_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Bottom sheet picker untuk memilih kategori di form transaksi.
///
/// Menampilkan daftar kategori parent-child max 2 level.
/// Tap parent yang punya children → expand children.
/// Tap parent tanpa children atau child → return kategori terpilih.
///
/// Penggunaan:
/// ```dart
/// final selected = await CategoryPickerSheet.show(
///   context: context,
///   type: CategoryType.expense,
///   selectedId: currentCategoryId,
/// );
/// ```
class CategoryPickerSheet extends ConsumerStatefulWidget {
  const CategoryPickerSheet({super.key, required this.type, this.selectedId});

  /// Tipe kategori yang ditampilkan (income/expense).
  final CategoryType type;

  /// ID kategori yang sedang dipilih (untuk highlight).
  final String? selectedId;

  /// Menampilkan bottom sheet picker dan return [CategoryModel] terpilih.
  static Future<CategoryModel?> show({
    required BuildContext context,
    required CategoryType type,
    String? selectedId,
  }) {
    return showModalBottomSheet<CategoryModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryPickerSheet(type: type, selectedId: selectedId),
    );
  }

  @override
  ConsumerState<CategoryPickerSheet> createState() =>
      _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends ConsumerState<CategoryPickerSheet> {
  /// ID parent yang sedang di-expand.
  String? _expandedParentId;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    final groupedCategories = widget.type == CategoryType.expense
        ? ref.watch(expenseCategoriesProvider)
        : ref.watch(incomeCategoriesProvider);

    return Container(
      constraints: BoxConstraints(maxHeight: 0.75.sh),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // Title
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Row(
              children: [
                Text(
                  l10n.transactionSelectCategory,
                  style: TextStyleConstants.h7.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Chip tipe kategori
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: widget.type == CategoryType.expense
                        ? colors.expense.withValues(alpha: 0.1)
                        : colors.income.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    widget.type == CategoryType.expense
                        ? l10n.categoryExpense
                        : l10n.categoryIncome,
                    style: TextStyleConstants.caption.copyWith(
                      color: widget.type == CategoryType.expense
                          ? colors.expense
                          : colors.income,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: colors.border.withValues(alpha: 0.5)),

          // Category list
          Flexible(
            child: groupedCategories.isEmpty
                ? SakuEmptyState(
                    message: l10n.categoryEmpty,
                    icon: FontAwesomeIcons.layerGroup,
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    itemCount: groupedCategories.length,
                    itemBuilder: (context, index) {
                      final parent = groupedCategories[index];
                      return _CategoryParentTile(
                        category: parent,
                        isExpanded: _expandedParentId == parent.id,
                        isSelected: widget.selectedId == parent.id,
                        selectedChildId: widget.selectedId,
                        onTap: () => _handleParentTap(parent),
                        onExpand: () => _toggleExpand(parent.id),
                        onChildTap: (child) => _selectCategory(child),
                      );
                    },
                  ),
          ),

          SizedBox(height: MediaQuery.paddingOf(context).bottom + 8.h),
        ],
      ),
    );
  }

  void _handleParentTap(CategoryModel parent) {
    if (parent.children.isEmpty) {
      _selectCategory(parent);
    } else {
      _toggleExpand(parent.id);
    }
  }

  void _toggleExpand(String parentId) {
    setState(() {
      _expandedParentId = _expandedParentId == parentId ? null : parentId;
    });
  }

  void _selectCategory(CategoryModel category) {
    Navigator.of(context).pop(category);
  }
}

/// Tile untuk parent category dengan expand/collapse children.
class _CategoryParentTile extends StatelessWidget {
  const _CategoryParentTile({
    required this.category,
    required this.isExpanded,
    required this.isSelected,
    required this.selectedChildId,
    required this.onTap,
    required this.onExpand,
    required this.onChildTap,
  });

  final CategoryModel category;
  final bool isExpanded;
  final bool isSelected;
  final String? selectedChildId;
  final VoidCallback onTap;
  final VoidCallback onExpand;
  final ValueChanged<CategoryModel> onChildTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasChildren = category.children.isNotEmpty;
    final categoryColor = _parseColor(category.color);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Parent tile
        InkWell(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            color: isSelected
                ? colors.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            child: Row(
              children: [
                // Icon
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Center(
                    child: FaIcon(
                      CategoryIconMapper.getIcon(category.icon),
                      size: 16.w,
                      color: categoryColor,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),

                // Name
                Expanded(
                  child: Text(
                    category.name,
                    style: TextStyleConstants.b2.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isSelected ? colors.primary : colors.textPrimary,
                    ),
                  ),
                ),

                // Selected check
                if (isSelected)
                  FaIcon(
                    FontAwesomeIcons.circleCheck,
                    size: 16.w,
                    color: colors.primary,
                  ),

                // Expand arrow (jika punya children)
                if (hasChildren && !isSelected) ...[
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: onExpand,
                    child: AnimatedRotation(
                      turns: isExpanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: FaIcon(
                        FontAwesomeIcons.chevronRight,
                        size: 12.w,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Children (expanded)
        if (hasChildren && isExpanded)
          ...category.children.map(
            (child) => _CategoryChildTile(
              category: child,
              isSelected: selectedChildId == child.id,
              onTap: () => onChildTap(child),
            ),
          ),
      ],
    );
  }
}

/// Tile untuk child category (indented).
class _CategoryChildTile extends StatelessWidget {
  const _CategoryChildTile({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final CategoryModel category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final categoryColor = _parseColor(category.color);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(
          left: 64.w,
          right: 16.w,
          top: 10.h,
          bottom: 10.h,
        ),
        color: isSelected
            ? colors.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        child: Row(
          children: [
            // Small icon
            Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Center(
                child: FaIcon(
                  CategoryIconMapper.getIcon(category.icon),
                  size: 12.w,
                  color: categoryColor,
                ),
              ),
            ),
            SizedBox(width: 10.w),

            // Name
            Expanded(
              child: Text(
                category.name,
                style: TextStyleConstants.caption.copyWith(
                  fontWeight: FontWeight.w400,
                  color: isSelected ? colors.primary : colors.textPrimary,
                ),
              ),
            ),

            // Selected check
            if (isSelected)
              FaIcon(
                FontAwesomeIcons.circleCheck,
                size: 14.w,
                color: colors.primary,
              ),
          ],
        ),
      ),
    );
  }
}

/// Parse hex color string ke [Color].
Color _parseColor(String hexColor) {
  final hex = hexColor.replaceFirst('#', '');
  if (hex.length == 6) {
    return Color(int.parse('FF$hex', radix: 16));
  }
  return const Color(0xFF6B7280);
}
