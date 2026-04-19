import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/category/controllers/category_controller.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// ─────────────────────────────────────────────────────────
// Exported helper functions
// ─────────────────────────────────────────────────────────

/// Filter grouped category list berdasarkan sumber (semua / buatan user / sistem).
///
/// Filtering dilakukan pada level parent — parent yang match
/// ditampilkan beserta semua children-nya.
List<CategoryModel> applySourceFilter(
  List<CategoryModel> grouped,
  CategorySourceFilter filter,
) {
  if (filter == CategorySourceFilter.all) return grouped;
  return grouped.where((parent) {
    return switch (filter) {
      CategorySourceFilter.all => true,
      CategorySourceFilter.user => !parent.isDefault,
      CategorySourceFilter.system => parent.isDefault,
    };
  }).toList();
}

/// Urutkan grouped category list berdasarkan field dan arah tertentu.
List<CategoryModel> applyCategorySort(
  List<CategoryModel> grouped,
  CategorySortField field,
  CategorySortDirection direction,
) {
  final sorted = [...grouped];
  sorted.sort((a, b) {
    final int cmp;
    if (field == CategorySortField.name) {
      cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    } else {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      cmp = aDate.compareTo(bDate);
    }
    return direction == CategorySortDirection.asc ? cmp : -cmp;
  });
  return sorted;
}

// ─────────────────────────────────────────────────────────
// CategoryFilterRow
// ─────────────────────────────────────────────────────────

/// Row kontrol filter & sort kategori.
///
/// Menampilkan dua dropdown pills:
/// - **Urut**: pilih kolom (Nama / Tanggal) + arah (A→Z/Z→A, Terbaru/Terlama)
/// - **Filter**: pilih sumber (Semua / Buatan Saya / Dari Sistem)
///
/// Tombol **Reset** muncul otomatis jika ada filter non-default aktif.
class CategoryFilterRow extends StatelessWidget {
  const CategoryFilterRow({
    super.key,
    required this.sortField,
    required this.sortDirection,
    required this.sourceFilter,
    required this.onSortChanged,
    required this.onSourceFilterChanged,
    required this.onReset,
  });

  final CategorySortField sortField;
  final CategorySortDirection sortDirection;
  final CategorySourceFilter sourceFilter;

  /// Dipanggil saat user memilih opsi sort baru.
  final void Function(CategorySortField field, CategorySortDirection direction)
  onSortChanged;

  /// Dipanggil saat user memilih opsi filter sumber baru.
  final ValueChanged<CategorySourceFilter> onSourceFilterChanged;

  /// Dipanggil saat user tap tombol Reset.
  final VoidCallback onReset;

  bool get _isDefault =>
      sortField == CategorySortField.name &&
      sortDirection == CategorySortDirection.asc &&
      sourceFilter == CategorySourceFilter.all;

  bool get _isSortActive =>
      !(sortField == CategorySortField.name &&
          sortDirection == CategorySortDirection.asc);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 6.h, 12.w, 4.h),
      child: Row(
        children: [
          // ── Sort dropdown ──
          PopupMenuButton<(CategorySortField, CategorySortDirection)>(
            onSelected: (v) => onSortChanged(v.$1, v.$2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            itemBuilder: (ctx) => [
              _buildSortItem(ctx, l10n.categorySortNameAZ, (
                CategorySortField.name,
                CategorySortDirection.asc,
              )),
              _buildSortItem(ctx, l10n.categorySortNameZA, (
                CategorySortField.name,
                CategorySortDirection.desc,
              )),
              const PopupMenuDivider(height: 1),
              _buildSortItem(ctx, l10n.categorySortNewest, (
                CategorySortField.createdAt,
                CategorySortDirection.desc,
              )),
              _buildSortItem(ctx, l10n.categorySortOldest, (
                CategorySortField.createdAt,
                CategorySortDirection.asc,
              )),
            ],
            child: _FilterPill(
              icon: FontAwesomeIcons.sort,
              label: _currentSortLabel(l10n),
              isActive: _isSortActive,
            ),
          ),

          SizedBox(width: 8.w),

          // ── Source filter dropdown ──
          PopupMenuButton<CategorySourceFilter>(
            onSelected: onSourceFilterChanged,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            itemBuilder: (ctx) => [
              _buildFilterItem(
                ctx,
                l10n.categoryFilterAll,
                CategorySourceFilter.all,
              ),
              _buildFilterItem(
                ctx,
                l10n.categoryFilterUserCreated,
                CategorySourceFilter.user,
              ),
              _buildFilterItem(
                ctx,
                l10n.categoryFilterSystem,
                CategorySourceFilter.system,
              ),
            ],
            child: _FilterPill(
              icon: FontAwesomeIcons.filter,
              label: _currentFilterLabel(l10n),
              isActive: sourceFilter != CategorySourceFilter.all,
            ),
          ),

          const Spacer(),

          // ── Reset (hanya jika ada filter aktif) ──
          if (!_isDefault)
            GestureDetector(
              onTap: onReset,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: colors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: colors.error.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.xmark,
                      size: 10.w,
                      color: colors.error,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      l10n.categoryFilterReset,
                      style: TextStyleConstants.caption.copyWith(
                        color: colors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  PopupMenuItem<(CategorySortField, CategorySortDirection)> _buildSortItem(
    BuildContext context,
    String label,
    (CategorySortField, CategorySortDirection) value,
  ) {
    final colors = context.colors;
    final isSelected = sortField == value.$1 && sortDirection == value.$2;
    return PopupMenuItem(
      value: value,
      height: 40,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyleConstants.b2.copyWith(
                color: isSelected ? colors.primary : colors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (isSelected)
            FaIcon(FontAwesomeIcons.check, size: 12.w, color: colors.primary),
        ],
      ),
    );
  }

  PopupMenuItem<CategorySourceFilter> _buildFilterItem(
    BuildContext context,
    String label,
    CategorySourceFilter value,
  ) {
    final colors = context.colors;
    final isSelected = sourceFilter == value;
    return PopupMenuItem(
      value: value,
      height: 40,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyleConstants.b2.copyWith(
                color: isSelected ? colors.primary : colors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (isSelected)
            FaIcon(FontAwesomeIcons.check, size: 12.w, color: colors.primary),
        ],
      ),
    );
  }

  String _currentSortLabel(dynamic l10n) {
    if (sortField == CategorySortField.name) {
      return sortDirection == CategorySortDirection.asc
          ? l10n.categorySortNameAZ
          : l10n.categorySortNameZA;
    }
    return sortDirection == CategorySortDirection.desc
        ? l10n.categorySortNewest
        : l10n.categorySortOldest;
  }

  String _currentFilterLabel(dynamic l10n) {
    return switch (sourceFilter) {
      CategorySourceFilter.all => l10n.categoryFilterAll,
      CategorySourceFilter.user => l10n.categoryFilterUserCreated,
      CategorySourceFilter.system => l10n.categoryFilterSystem,
    };
  }
}

// ─────────────────────────────────────────────────────────
// Private: _FilterPill
// ─────────────────────────────────────────────────────────

/// Pill button visual untuk sort/filter dropdown.
class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.icon,
    required this.label,
    required this.isActive,
  });

  final IconData icon;
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final activeColor = isActive ? colors.primary : colors.textSecondary;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: isActive
            ? colors.primary.withValues(alpha: 0.08)
            : colors.surfaceVariant,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isActive
              ? colors.primary.withValues(alpha: 0.3)
              : colors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 10.w, color: activeColor),
          SizedBox(width: 5.w),
          Text(
            label,
            style: TextStyleConstants.caption.copyWith(
              color: activeColor,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          SizedBox(width: 4.w),
          FaIcon(
            FontAwesomeIcons.chevronDown,
            size: 8.w,
            color: activeColor.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }
}
