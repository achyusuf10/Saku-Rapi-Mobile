import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/category/controllers/category_controller.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/category/view/widgets/category_filter_row.dart';
import 'package:app_saku_rapi/features/category/view/widgets/category_form_sheet.dart';
import 'package:app_saku_rapi/features/category/view/widgets/category_list_tile.dart';
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
/// Setiap parent punya state expand/collapse independen.
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
  /// Set ID parent yang sedang di-collapse — di-persist ke Hive per type.
  final Set<String> _collapsedParentIds = {};

  /// Flag agar init hanya dijalankan sekali saat categories pertama load.
  bool _initialized = false;

  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Filter & sort state (persisted per type)
  CategorySortField _sortField = CategorySortField.none;
  CategorySortDirection _sortDirection = CategorySortDirection.asc;
  CategorySourceFilter _sourceFilter = CategorySourceFilter.all;

  /// Load filter prefs lewat controller.
  void _loadFilterPrefs() {
    final prefs = ref
        .read(categoryControllerProvider.notifier)
        .getFilterPrefs(widget.type.value);
    _sortField = CategorySortField.values.firstWhere(
      (e) => e.name == prefs.sortField,
      orElse: () => CategorySortField.none,
    );
    _sortDirection = CategorySortDirection.values.firstWhere(
      (e) => e.name == prefs.sortDirection,
      orElse: () => CategorySortDirection.asc,
    );
    _sourceFilter = CategorySourceFilter.values.firstWhere(
      (e) => e.name == prefs.sourceFilter,
      orElse: () => CategorySourceFilter.all,
    );
  }

  /// Simpan filter prefs lewat controller.
  void _saveFilterPrefs() {
    ref
        .read(categoryControllerProvider.notifier)
        .saveFilterPrefs(
          widget.type.value,
          CategoryPickerPrefs(
            sortField: _sortField.name,
            sortDirection: _sortDirection.name,
            sourceFilter: _sourceFilter.name,
          ),
        );
  }

  /// Load collapsed IDs lewat controller, lalu apply ke state.
  /// Dipanggil di dalam setState() dari caller.
  void _loadCollapsedState() {
    final saved = ref
        .read(categoryControllerProvider.notifier)
        .getCollapsedParentIds(widget.type.value);
    _collapsedParentIds.addAll(saved);
  }

  /// Persist collapsed IDs lewat controller.
  void _saveCollapsedState() {
    ref
        .read(categoryControllerProvider.notifier)
        .saveCollapsedParentIds(widget.type.value, _collapsedParentIds);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _loadFilterPrefs();
        _loadCollapsedState();
      });
      final catState = ref.read(categoryControllerProvider);
      if (catState.status == CategoryStatus.initial) {
        ref.read(categoryControllerProvider.notifier).loadCategories();
      }
    });
  }

  Color get _typeColor => widget.type == CategoryType.expense
      ? context.colors.expense
      : context.colors.income;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    final groupedCategories = widget.type == CategoryType.expense
        ? ref.watch(expenseCategoriesProvider)
        : ref.watch(incomeCategoriesProvider);

    // Auto-expand semua parent saat categories pertama kali tersedia.
    if (!_initialized && groupedCategories.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _initialized = true;
          });
        }
      });
    }

    // Step 1: Apply source filter + sort
    final sourceSorted = applyCategorySort(
      applySourceFilter(groupedCategories, _sourceFilter),
      _sortField,
      _sortDirection,
    );

    // Step 2: Apply search query
    final q = _searchQuery.toLowerCase().trim();
    // Auto-expand semua hasil saat sedang search.
    if (q.isNotEmpty) {
      _collapsedParentIds.clear();
    }
    final filteredCategories = q.isEmpty
        ? sourceSorted
        : sourceSorted
              .map((parent) {
                final parentMatches = parent.name.toLowerCase().contains(q);
                final matchingChildren = parent.children
                    .where((c) => c.name.toLowerCase().contains(q))
                    .toList();

                if (parentMatches) {
                  return parent;
                } else if (matchingChildren.isNotEmpty) {
                  return parent.copyWith(children: matchingChildren);
                }
                return null;
              })
              .whereType<CategoryModel>()
              .toList();

    return Container(
      height: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 10.h),
            width: 36.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: colors.border.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 12.w, 12.h),
            child: Row(
              children: [
                // Icon + title
                Container(
                  width: 34.w,
                  height: 34.w,
                  decoration: BoxDecoration(
                    color: _typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Center(
                    child: FaIcon(
                      FontAwesomeIcons.layerGroup,
                      size: 14.w,
                      color: _typeColor,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.transactionSelectCategory,
                        style: TextStyleConstants.h7.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        widget.type == CategoryType.expense
                            ? l10n.categoryExpense
                            : l10n.categoryIncome,
                        style: TextStyleConstants.caption.copyWith(
                          color: _typeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Add category button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12.r),
                    onTap: _openAddCategory,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: _typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: _typeColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FaIcon(
                            FontAwesomeIcons.plus,
                            size: 11.w,
                            color: _typeColor,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            l10n.categoryAdd,
                            style: TextStyleConstants.caption.copyWith(
                              color: _typeColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Divider(
              height: 1,
              color: colors.border.withValues(alpha: 0.3),
            ),
          ),

          // Search field
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 4.h),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: TextStyleConstants.b2.copyWith(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: l10n.pickerSearchCategory,
                hintStyle: TextStyleConstants.b2.copyWith(
                  color: colors.textSecondary,
                ),
                prefixIcon: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: FaIcon(
                    FontAwesomeIcons.magnifyingGlass,
                    size: 14.w,
                    color: colors.textSecondary,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () => setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        }),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          child: FaIcon(
                            FontAwesomeIcons.circleXmark,
                            size: 14.w,
                            color: colors.textSecondary,
                          ),
                        ),
                      )
                    : null,
                suffixIconConstraints: const BoxConstraints(),
                filled: true,
                fillColor: colors.surfaceVariant,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 10.h,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: colors.border.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: colors.border.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: _typeColor, width: 1.5),
                ),
              ),
            ),
          ),

          // Filter & sort row
          CategoryFilterRow(
            sortField: _sortField,
            sortDirection: _sortDirection,
            sourceFilter: _sourceFilter,
            onSortChanged: (field, dir) {
              setState(() {
                _sortField = field;
                _sortDirection = dir;
              });
              _saveFilterPrefs();
            },
            onSourceFilterChanged: (filter) {
              setState(() => _sourceFilter = filter);
              _saveFilterPrefs();
            },
            onReset: () {
              setState(() {
                _sortField = CategorySortField.none;
                _sortDirection = CategorySortDirection.asc;
                _sourceFilter = CategorySourceFilter.all;
              });
              _saveFilterPrefs();
            },
          ),

          // Category list
          Flexible(
            child: filteredCategories.isEmpty
                ? Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.h),
                    child: SakuEmptyState(
                      message: l10n.categoryEmpty,
                      icon: FontAwesomeIcons.layerGroup,
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 8.h),
                    itemCount: filteredCategories.length,
                    separatorBuilder: (_, index) => SizedBox(height: 4.h),
                    itemBuilder: (context, index) {
                      final parent = filteredCategories[index];
                      return CategoryParentListTile(
                        category: parent,
                        isExpanded: !_collapsedParentIds.contains(parent.id),
                        isSelected: widget.selectedId == parent.id,
                        selectedChildId: widget.selectedId,
                        onTap: () => _handleParentTap(parent),
                        onToggleExpand: () => _toggleExpand(parent.id),
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
    _selectCategory(parent);
  }

  void _toggleExpand(String parentId) {
    setState(() {
      if (_collapsedParentIds.contains(parentId)) {
        _collapsedParentIds.remove(parentId);
      } else {
        _collapsedParentIds.add(parentId);
      }
    });
    _saveCollapsedState();
  }

  void _selectCategory(CategoryModel category) {
    Navigator.of(context).pop(category);
  }

  Future<void> _openAddCategory() async {
    await CategoryFormSheet.show(context: context, type: widget.type);
  }
}
