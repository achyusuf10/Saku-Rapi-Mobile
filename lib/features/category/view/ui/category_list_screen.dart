import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/category/controllers/category_controller.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/category/view/widgets/category_parent_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// Layar utama daftar kategori parent-child.
///
/// Fitur:
/// - Tab "Pengeluaran" / "Pemasukan" untuk filter tipe.
/// - Expandable tiles parent → children.
/// - FAB untuk tambah kategori baru.
/// - Long-press tile → bottom sheet opsi (Edit / Hide / Delete).
class CategoryListScreen extends ConsumerStatefulWidget {
  const CategoryListScreen({super.key});

  @override
  ConsumerState<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends ConsumerState<CategoryListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  /// Tracking expand/collapse state per category ID.
  final Set<String> _expandedIds = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────

  String _currentType() => _tabCtrl.index == 0 ? 'expense' : 'income';

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  // ─────────────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────────────

  void _showOptions(CategoryModel category) {
    final l10n = context.l10n;
    final appColors = context.colors;

    showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      backgroundColor: appColors.background,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Handle bar ──
                Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 8.h),
                  decoration: BoxDecoration(
                    color: appColors.border,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),

                // ── Title ──
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  child: Text(
                    category.name,
                    style: TextStyleConstants.h7.copyWith(
                      fontWeight: FontWeight.w700,
                      color: appColors.textPrimary,
                    ),
                  ),
                ),

                // ── Edit ──
                ListTile(
                  leading: FaIcon(
                    FontAwesomeIcons.penToSquare,
                    size: 18.r,
                    color: appColors.primary,
                  ),
                  title: Text(l10n.categoryEdit),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    context.push(AppRouter.categoryForm, extra: category);
                  },
                ),

                // ── Hide / Show ──
                ListTile(
                  leading: FaIcon(
                    category.isHidden
                        ? FontAwesomeIcons.eye
                        : FontAwesomeIcons.eyeSlash,
                    size: 18.r,
                    color: appColors.textSecondary,
                  ),
                  title: Text(
                    category.isHidden ? l10n.categoryShow : l10n.categoryHide,
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _toggleHide(category);
                  },
                ),

                // ── Delete  (disabled for default) ──
                if (!category.isDefault)
                  ListTile(
                    leading: FaIcon(
                      FontAwesomeIcons.trashCan,
                      size: 18.r,
                      color: appColors.expense,
                    ),
                    title: Text(
                      l10n.categoryDelete,
                      style: TextStyle(color: appColors.expense),
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _confirmDelete(category);
                    },
                  ),

                if (category.isDefault)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    child: Text(
                      l10n.categoryDeleteDefault,
                      style: TextStyleConstants.caption.copyWith(
                        color: appColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleHide(CategoryModel category) async {
    final controller = ref.read(categoryControllerProvider.notifier);
    final l10n = context.l10n;

    final result = await controller.toggleHide(category.id, !category.isHidden);

    if (!mounted) return;

    result.map(
      success: (_) {
        final msg = category.isHidden
            ? l10n.categorySuccessShow
            : l10n.categorySuccessHide;
        context.showAppAlert(msg);
      },
      error: (err) {
        context.showAppAlert(
          l10n.categoryErrorSave,
          alertType: AlertTypeEnum.error,
        );
      },
    );
  }

  Future<void> _confirmDelete(CategoryModel category) async {
    final l10n = context.l10n;

    final confirmed = await context.showConfirmDialog(
      title: l10n.categoryDelete,
      message: l10n.categoryDeleteConfirm(category.name),
    );

    if (confirmed != true || !mounted) return;

    context.showLoadingOverlay();

    final controller = ref.read(categoryControllerProvider.notifier);
    final result = await controller.removeCategory(category.id);

    if (!mounted) return;
    context.closeOverlay();

    result.map(
      success: (_) {
        context.showAppAlert(l10n.categorySuccessDelete);
      },
      error: (err) {
        context.showAppAlert(
          l10n.categoryErrorDelete,
          alertType: AlertTypeEnum.error,
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final categoryAsync = ref.watch(categoryControllerProvider);
    final appColors = context.colors;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.categoryTitle),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabCtrl,
          onTap: (_) => setState(() {}),
          labelColor: appColors.primary,
          unselectedLabelColor: appColors.textSecondary,
          indicatorColor: appColors.primary,
          tabs: [
            Tab(text: l10n.categoryExpense),
            Tab(text: l10n.categoryIncome),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(
          AppRouter.categoryForm,
          extra: <String, dynamic>{'type': _currentType()},
        ),
        backgroundColor: appColors.primary,
        child: FaIcon(FontAwesomeIcons.plus, color: Colors.white, size: 20.r),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // ── Expense Tab ──
          categoryAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ErrorBody(
              message: error.toString(),
              onRetry: () =>
                  ref.read(categoryControllerProvider.notifier).refresh(),
            ),
            data: (state) => _CategoryList(
              categories: state.expenseCategories,
              expandedIds: _expandedIds,
              onToggleExpand: _toggleExpand,
              onShowOptions: _showOptions,
            ),
          ),

          // ── Income Tab ──
          categoryAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ErrorBody(
              message: error.toString(),
              onRetry: () =>
                  ref.read(categoryControllerProvider.notifier).refresh(),
            ),
            data: (state) => _CategoryList(
              categories: state.incomeCategories,
              expandedIds: _expandedIds,
              onToggleExpand: _toggleExpand,
              onShowOptions: _showOptions,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Private helper widgets
// ─────────────────────────────────────────────────────

class _CategoryList extends StatelessWidget {
  const _CategoryList({
    required this.categories,
    required this.expandedIds,
    required this.onToggleExpand,
    required this.onShowOptions,
  });

  final List<CategoryModel> categories;
  final Set<String> expandedIds;
  final void Function(String id) onToggleExpand;
  final void Function(CategoryModel category) onShowOptions;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;
    final l10n = context.l10n;

    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.folderOpen,
              size: 48.r,
              color: appColors.textSecondary.withValues(alpha: 0.4),
            ),
            SizedBox(height: 16.h),
            Text(
              l10n.categoryEmpty,
              style: TextStyleConstants.b1.copyWith(
                color: appColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ProviderScope.containerOf(
        context,
      ).read(categoryControllerProvider.notifier).refresh(),
      child: ListView.separated(
        padding: EdgeInsets.only(top: 8.h, bottom: 80.h),
        itemCount: categories.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          indent: 16.w,
          endIndent: 16.w,
          color: appColors.border.withValues(alpha: 0.5),
        ),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return CategoryParentTile(
            category: cat,
            isExpanded: expandedIds.contains(cat.id),
            onTap: () => onToggleExpand(cat.id),
            onLongPress: () => onShowOptions(cat),
            onChildLongPress: (child) => onShowOptions(child),
          );
        },
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.triangleExclamation,
              size: 48.r,
              color: appColors.expense,
            ),
            SizedBox(height: 16.h),
            Text(
              message,
              style: TextStyleConstants.b2.copyWith(
                color: appColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            FilledButton.icon(
              onPressed: onRetry,
              icon: FaIcon(FontAwesomeIcons.arrowsRotate, size: 14.r),
              label: Text(context.l10n.retryButton),
            ),
          ],
        ),
      ),
    );
  }
}
