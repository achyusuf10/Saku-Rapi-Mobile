import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/utils/category_icon_mapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Bottom sheet untuk memilih icon kategori.
///
/// Menampilkan grid semua icon yang tersedia.
/// Mendukung pencarian nama icon.
class CategoryIconPickerSheet extends StatefulWidget {
  const CategoryIconPickerSheet({super.key, this.selectedIcon});

  /// Nama icon yang sedang dipilih (untuk highlight).
  final String? selectedIcon;

  /// Menampilkan icon picker dan return nama icon terpilih.
  static Future<String?> show({
    required BuildContext context,
    String? selectedIcon,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryIconPickerSheet(selectedIcon: selectedIcon),
    );
  }

  @override
  State<CategoryIconPickerSheet> createState() =>
      _CategoryIconPickerSheetState();
}

class _CategoryIconPickerSheetState extends State<CategoryIconPickerSheet> {
  late List<MapEntry<String, IconData>> _filteredIcons;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredIcons = CategoryIconMapper.availableIcons.entries.toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    setState(() {
      if (normalizedQuery.isEmpty) {
        _filteredIcons = CategoryIconMapper.availableIcons.entries.toList();
      } else {
        _filteredIcons = CategoryIconMapper.availableIcons.entries
            .where((e) => e.key.toLowerCase().contains(normalizedQuery))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

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
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Text(
              l10n.categoryIconPicker,
              style: TextStyleConstants.h7.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ),

          // Search
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: l10n.categorySearchIcon,
                hintStyle: TextStyleConstants.b2.copyWith(
                  color: colors.textSecondary,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: colors.textSecondary,
                  size: 20.w,
                ),
                filled: true,
                fillColor: colors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: colors.border),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 10.h,
                ),
              ),
              style: TextStyleConstants.b2,
            ),
          ),
          SizedBox(height: 12.h),

          // Icon grid
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 8.h,
                crossAxisSpacing: 8.w,
              ),
              itemCount: _filteredIcons.length,
              itemBuilder: (context, index) {
                final entry = _filteredIcons[index];
                final isSelected = entry.key == widget.selectedIcon;

                return InkWell(
                  onTap: () => Navigator.pop(context, entry.key),
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.primary.withValues(alpha: 0.15)
                          : colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isSelected ? colors.primary : colors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: FaIcon(
                        entry.value,
                        size: 18.w,
                        color: isSelected ? colors.primary : colors.textPrimary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: MediaQuery.paddingOf(context).bottom + 8.h),
        ],
      ),
    );
  }
}
