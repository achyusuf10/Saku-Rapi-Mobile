import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/budgeting/controllers/budget_controller.dart';
import 'package:app_saku_rapi/features/budgeting/models/budget_model.dart';
import 'package:app_saku_rapi/features/budgeting/view/widgets/budget_item_widget.dart';
import 'package:app_saku_rapi/features/budgeting/view/widgets/budget_summary_header_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// Layar utama Anggaran (Budget List).
///
/// Struktur:
/// - AppBar: judul "Anggaran", tab periode
/// - CustomScrollView:
///   - SliverToBoxAdapter: [BudgetSummaryHeaderWidget]
///   - SliverList: [BudgetItemWidget] × N
/// - Swipe-to-refresh (RefreshIndicator)
class BudgetListScreen extends ConsumerWidget {
  const BudgetListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetAsync = ref.watch(budgetControllerProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.budgetTitle), centerTitle: true),
      body: budgetAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorBody(
          message: error.toString(),
          onRetry: () => ref.read(budgetControllerProvider.notifier).refresh(),
        ),
        data: (state) => _SuccessBody(state: state),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Body: Error
// ─────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.triangleExclamation,
              size: 48.r,
              color: colors.expense,
            ),
            SizedBox(height: 16.h),
            Text(
              message,
              style: TextStyleConstants.b2.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            FilledButton.icon(
              onPressed: onRetry,
              icon: FaIcon(FontAwesomeIcons.arrowsRotate, size: 14.r),
              label: Text(
                l10n.retryButton,
                style: TextStyleConstants.b2.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Body: Success
// ─────────────────────────────────────────────────────────────

class _SuccessBody extends ConsumerWidget {
  const _SuccessBody({required this.state});

  final BudgetState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final controller = ref.read(budgetControllerProvider.notifier);

    return RefreshIndicator(
      onRefresh: () => controller.refresh(),
      child: CustomScrollView(
        slivers: [
          // ── Header ringkasan ──
          SliverToBoxAdapter(
            child: state.summary != null
                ? BudgetSummaryHeaderWidget(
                    summary: state.summary!,
                    onCreateTapped: () => context.push(AppRouter.budgetForm),
                  )
                : _EmptySummaryHeader(
                    onCreateTapped: () => context.push(AppRouter.budgetForm),
                  ),
          ),

          // ── Label section daftar budget ──
          if (state.budgets.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
                child: Text(
                  l10n.budgetActiveBudgets,
                  style: TextStyleConstants.label1.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),

          // ── Daftar budget ──
          if (state.budgets.isEmpty)
            SliverToBoxAdapter(child: _EmptyBudgetList())
          else
            SliverList.builder(
              itemCount: state.budgets.length,
              itemBuilder: (context, index) {
                final budget = state.budgets[index];
                return BudgetItemWidget(
                  budget: budget,
                  onTap: () =>
                      context.push(AppRouter.budgetForm, extra: budget),
                  onLongPress: () => _confirmDelete(context, ref, budget),
                );
              },
            ),

          // Padding bawah
          SliverPadding(padding: EdgeInsets.only(bottom: 80.h)),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    BudgetModel budget,
  ) async {
    final l10n = context.l10n;
    final confirmed = await context.showConfirmDialog(
      title: l10n.budgetDeleteConfirmTitle,
      message: l10n.budgetDeleteConfirmMessage(budget.categoryName ?? '-'),
    );
    if (confirmed != true) return;

    if (!context.mounted) return;
    context.showLoadingOverlay();

    final result = await ref
        .read(budgetControllerProvider.notifier)
        .removeBudget(budget.id);

    if (!context.mounted) return;
    context.closeOverlay();

    if (result.isSuccess()) {
      context.showAppAlert(l10n.budgetSuccessDelete);
    } else {
      context.showAppAlert(
        result.dataError()?.$1 ?? l10n.budgetErrorDelete,
        alertType: AlertTypeEnum.error,
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────

/// Header placeholder saat summary belum tersedia.
class _EmptySummaryHeader extends StatelessWidget {
  const _EmptySummaryHeader({required this.onCreateTapped});

  final VoidCallback onCreateTapped;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.all(16.r),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onCreateTapped,
          style: FilledButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.r),
            ),
            padding: EdgeInsets.symmetric(vertical: 14.h),
          ),
          child: Text(
            l10n.budgetAdd,
            style: TextStyleConstants.b1.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Tampilan kosong saat belum ada budget.
class _EmptyBudgetList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 48.h, horizontal: 32.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            FontAwesomeIcons.chartPie,
            size: 48.r,
            color: colors.textSecondary.withValues(alpha: 0.4),
          ),
          SizedBox(height: 16.h),
          Text(
            l10n.budgetEmpty,
            style: TextStyleConstants.b1.copyWith(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            l10n.budgetEmptyHint,
            style: TextStyleConstants.caption.copyWith(
              color: colors.textSecondary.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
