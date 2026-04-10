import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/budget/controllers/budget_controller.dart';
import 'package:app_saku_rapi/features/budget/view/widgets/budget_card_tile.dart';
import 'package:app_saku_rapi/features/budget/view/widgets/budget_shimmer.dart';
import 'package:app_saku_rapi/global/widgets/saku_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Halaman terpisah untuk anggaran yang sudah selesai (expired).
class CompletedBudgetsPage extends ConsumerWidget {
  const CompletedBudgetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(completedBudgetsControllerProvider);
    final colors = context.colors;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(l10n.budgetCompletedTitle),
        centerTitle: false,
      ),
      body: state.isLoading
          ? const BudgetShimmer()
          : state.budgets.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(32.w),
                child: Text(
                  l10n.budgetCompletedEmpty,
                  style: TextStyleConstants.b2.copyWith(
                    color: colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              itemCount: state.budgets.length + 1,
              separatorBuilder: (_, index) => SizedBox(height: 12.h),
              itemBuilder: (_, i) {
                // Last item: load more trigger
                if (i == state.budgets.length) {
                  if (state.isLoadingMore) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      child: const Center(child: SakuLoadingIndicator()),
                    );
                  }
                  if (!state.hasMore) {
                    return const SizedBox.shrink();
                  }
                  return VisibilityDetector(
                    key: const Key('completed_budgets_load_more'),
                    onVisibilityChanged: (info) {
                      if (info.visibleFraction > 0) {
                        ref
                            .read(completedBudgetsControllerProvider.notifier)
                            .loadMore();
                      }
                    },
                    child: const SizedBox(height: 1),
                  );
                }

                final budget = state.budgets[i];
                return BudgetCardTile(
                  budget: budget,
                  onTap: () =>
                      context.push(AppRouter.budgetDetail, extra: budget),
                );
              },
            ),
    );
  }
}
