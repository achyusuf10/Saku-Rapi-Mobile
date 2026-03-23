import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/category/controllers/category_controller.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/category/utils/category_icon_mapper.dart';
import 'package:app_saku_rapi/features/category/view/widgets/category_form_sheet.dart';
import 'package:app_saku_rapi/global/widgets/saku_empty_state.dart';
import 'package:app_saku_rapi/global/widgets/saku_error_state.dart';
import 'package:app_saku_rapi/global/widgets/saku_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Halaman manajemen kategori.
///
/// Diakses dari Settings. Menampilkan tab Pengeluaran / Pemasukan.
/// User bisa menambah, edit, hide/show, dan hapus kategori.
class CategoryManagementPage extends ConsumerStatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  ConsumerState<CategoryManagementPage> createState() =>
      _CategoryManagementPageState();
}

class _CategoryManagementPageState extends ConsumerState<CategoryManagementPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load categories if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(categoryControllerProvider);
      if (state.status == CategoryStatus.initial) {
        ref.read(categoryControllerProvider.notifier).loadCategories();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final categoryState = ref.watch(categoryControllerProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          l10n.categoryTitle,
          style: TextStyleConstants.h6.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: TextStyleConstants.label1.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyleConstants.label1,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: colors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: [
            Tab(text: l10n.categoryExpense),
            Tab(text: l10n.categoryIncome),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddForm(context),
        backgroundColor: colors.primary,
        child: FaIcon(
          FontAwesomeIcons.plus,
          color: colors.onPrimary,
          size: 18.w,
        ),
      ),
      body: _buildBody(categoryState),
    );
  }

  Widget _buildBody(CategoryState categoryState) {
    if (categoryState.isLoading && categoryState.categories.isEmpty) {
      return const Center(child: SakuLoadingIndicator());
    }

    if (categoryState.status == CategoryStatus.error &&
        categoryState.categories.isEmpty) {
      return SakuErrorState(
        message: categoryState.errorMessage ?? '',
        onRetry: () {
          ref.read(categoryControllerProvider.notifier).loadCategories();
        },
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _CategoryListTab(type: CategoryType.expense),
        _CategoryListTab(type: CategoryType.income),
      ],
    );
  }

  void _showAddForm(BuildContext context) {
    final type = _tabController.index == 0
        ? CategoryType.expense
        : CategoryType.income;

    CategoryFormSheet.show(context: context, type: type);
  }
}

/// Tab content untuk satu tipe kategori (expense/income).
class _CategoryListTab extends ConsumerWidget {
  const _CategoryListTab({required this.type});

  final CategoryType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    final groupedCategories = type == CategoryType.expense
        ? ref.watch(allExpenseCategoriesProvider)
        : ref.watch(allIncomeCategoriesProvider);

    if (groupedCategories.isEmpty) {
      return SakuEmptyState(
        message: l10n.categoryEmpty,
        icon: FontAwesomeIcons.layerGroup,
        actionLabel: l10n.categoryAdd,
        onAction: () => CategoryFormSheet.show(context: context, type: type),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(categoryControllerProvider.notifier).loadCategories();
      },
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        itemCount: groupedCategories.length,
        itemBuilder: (context, index) {
          final parent = groupedCategories[index];
          return _CategoryManagementTile(category: parent, type: type);
        },
      ),
    );
  }
}

/// Tile manajemen kategori dengan aksi edit/hide/delete.
class _CategoryManagementTile extends ConsumerWidget {
  const _CategoryManagementTile({required this.category, required this.type});

  final CategoryModel category;
  final CategoryType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final categoryColor = _parseColor(category.color);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Parent tile
        InkWell(
          onTap: () => _showEditForm(context, category),
          onLongPress: () => _showActions(context, ref, category),
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Center(
                    child: FaIcon(
                      CategoryIconMapper.getIcon(category.icon),
                      size: 18.w,
                      color: category.isHidden
                          ? colors.textSecondary.withValues(alpha: 0.5)
                          : categoryColor,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),

                // Name + info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              category.name,
                              style: TextStyleConstants.b2.copyWith(
                                fontWeight: FontWeight.w500,
                                color: category.isHidden
                                    ? colors.textSecondary
                                    : colors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (category.isHidden) ...[
                            SizedBox(width: 6.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: colors.textSecondary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                l10n.categoryHidden,
                                style: TextStyleConstants.overline.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                          if (category.isDefault) ...[
                            SizedBox(width: 6.w),
                            FaIcon(
                              FontAwesomeIcons.lock,
                              size: 10.w,
                              color: colors.textSecondary.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (category.children.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 2.h),
                          child: Text(
                            l10n.categoryChildCount(category.children.length),
                            style: TextStyleConstants.caption.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // More actions
                IconButton(
                  onPressed: () => _showActions(context, ref, category),
                  icon: FaIcon(
                    FontAwesomeIcons.ellipsisVertical,
                    size: 14.w,
                    color: colors.textSecondary,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),

        // Children
        if (category.children.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: 52.w),
            child: Column(
              children: category.children
                  .map(
                    (child) => _CategoryChildManagementTile(
                      category: child,
                      type: type,
                    ),
                  )
                  .toList(),
            ),
          ),

        SizedBox(height: 4.h),
      ],
    );
  }

  void _showEditForm(BuildContext context, CategoryModel category) {
    CategoryFormSheet.show(
      context: context,
      type: type,
      editCategory: category,
    );
  }

  void _showActions(
    BuildContext context,
    WidgetRef ref,
    CategoryModel category,
  ) {
    final colors = context.colors;
    final l10n = context.l10n;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 8.h),

            // Edit
            if (!category.isDefault)
              ListTile(
                leading: FaIcon(
                  FontAwesomeIcons.pen,
                  size: 16.w,
                  color: colors.textPrimary,
                ),
                title: Text(l10n.categoryEdit, style: TextStyleConstants.b2),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditForm(context, category);
                },
              ),

            // Hide/Show
            ListTile(
              leading: FaIcon(
                category.isHidden
                    ? FontAwesomeIcons.eye
                    : FontAwesomeIcons.eyeSlash,
                size: 16.w,
                color: colors.textPrimary,
              ),
              title: Text(
                category.isHidden ? l10n.categoryShow : l10n.categoryHide,
                style: TextStyleConstants.b2,
              ),
              onTap: () {
                Navigator.pop(ctx);
                _toggleHidden(context, ref, category);
              },
            ),

            // Delete (non-default only)
            if (!category.isDefault)
              ListTile(
                leading: FaIcon(
                  FontAwesomeIcons.trash,
                  size: 16.w,
                  color: colors.error,
                ),
                title: Text(
                  l10n.categoryDelete,
                  style: TextStyleConstants.b2.copyWith(color: colors.error),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(context, ref, category);
                },
              ),

            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleHidden(
    BuildContext context,
    WidgetRef ref,
    CategoryModel category,
  ) async {
    final l10n = context.l10n;
    final result = await ref
        .read(categoryControllerProvider.notifier)
        .toggleHidden(categoryId: category.id, isHidden: !category.isHidden);

    if (!context.mounted) return;

    if (result.isSuccess()) {
      context.showAppAlert(
        category.isHidden ? l10n.categorySuccessShow : l10n.categorySuccessHide,
        alertType: AlertTypeEnum.success,
      );
    } else {
      final (message, _, _, _) = result.dataError()!;
      context.showAppAlert(message, alertType: AlertTypeEnum.error);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CategoryModel category,
  ) async {
    final l10n = context.l10n;

    if (category.isDefault) {
      context.showAppAlert(
        l10n.categoryDeleteDefault,
        alertType: AlertTypeEnum.warning,
      );
      return;
    }

    final confirmed = await context.showConfirmDialog(
      title: l10n.categoryDelete,
      message: l10n.categoryDeleteConfirm(category.name),
      confirmLabel: l10n.categoryDelete,
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    context.showLoadingOverlay();

    try {
      final result = await ref
          .read(categoryControllerProvider.notifier)
          .deleteCategory(category.id);

      if (!context.mounted) return;

      if (result.isSuccess()) {
        context.showAppAlert(
          l10n.categorySuccessDelete,
          alertType: AlertTypeEnum.success,
        );
      } else {
        final (message, _, _, _) = result.dataError()!;
        context.showAppAlert(message, alertType: AlertTypeEnum.error);
      }
    } finally {
      if (context.mounted) {
        context.closeOverlay();
      }
    }
  }
}

/// Tile child dalam management view.
class _CategoryChildManagementTile extends ConsumerWidget {
  const _CategoryChildManagementTile({
    required this.category,
    required this.type,
  });

  final CategoryModel category;
  final CategoryType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final categoryColor = _parseColor(category.color);

    return InkWell(
      onTap: () => CategoryFormSheet.show(
        context: context,
        type: type,
        editCategory: category,
      ),
      onLongPress: () {
        // Reuse parent's action sheet pattern
        _CategoryManagementTile(
          category: category,
          type: type,
        )._showActions(context, ref, category);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 4.w),
        child: Row(
          children: [
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
                  color: category.isHidden
                      ? colors.textSecondary.withValues(alpha: 0.5)
                      : categoryColor,
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                category.name,
                style: TextStyleConstants.caption.copyWith(
                  color: category.isHidden
                      ? colors.textSecondary
                      : colors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (category.isHidden)
              FaIcon(
                FontAwesomeIcons.eyeSlash,
                size: 10.w,
                color: colors.textSecondary.withValues(alpha: 0.5),
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
