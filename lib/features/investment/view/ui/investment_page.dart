import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/investment/controllers/asset_type_controller.dart';
import 'package:app_saku_rapi/features/investment/controllers/investment_controller.dart';
import 'package:app_saku_rapi/features/investment/models/investment_model.dart';
import 'package:app_saku_rapi/features/investment/view/ui/asset_type_management_page.dart';
import 'package:app_saku_rapi/features/investment/view/widgets/investment_asset_card.dart';
import 'package:app_saku_rapi/features/investment/view/widgets/investment_filter_sheet.dart';
import 'package:app_saku_rapi/features/investment/view/widgets/investment_portfolio_summary.dart';
import 'package:app_saku_rapi/global/widgets/saku_empty_state.dart';
import 'package:app_saku_rapi/global/widgets/saku_error_state.dart';
import 'package:app_saku_rapi/global/widgets/saku_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// Halaman investasi (tab keempat bottom nav).
///
/// Menampilkan portfolio summary di atas dan daftar aset di bawah.
/// Data di-load saat pertama kali halaman dibuka.
class InvestmentPage extends ConsumerStatefulWidget {
  const InvestmentPage({super.key});

  @override
  ConsumerState<InvestmentPage> createState() => _InvestmentPageState();
}

class _InvestmentPageState extends ConsumerState<InvestmentPage> {
  InvestmentFilterState _filterState = const InvestmentFilterState();

  @override
  void initState() {
    super.initState();
    // Load investasi saat page pertama kali dibuka.
    Future.microtask(() {
      ref.read(investmentControllerProvider.notifier).loadInvestments();
      ref.read(assetTypeControllerProvider.notifier).loadAssetTypes();
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(investmentControllerProvider.notifier).refresh();
  }

  void _onAddTap() {
    context.push(AppRouter.investmentForm);
  }

  void _onRefreshPrices() {
    ref.read(investmentControllerProvider.notifier).refreshPrices();
  }

  void _onAssetTap(InvestmentModel investment) {
    context.push(AppRouter.investmentForm, extra: investment);
  }

  void _onManageAssetTypes() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AssetTypeManagementPage()),
    );
  }

  Future<void> _onFilterTap() async {
    final result = await InvestmentFilterSheet.show(
      context,
      currentFilter: _filterState,
      assetTypes: ref.read(assetTypeListProvider),
    );
    if (result != null) {
      setState(() => _filterState = result);
    }
  }

  /// Apply filter & sort to investment list.
  List<InvestmentModel> _applyFilter(List<InvestmentModel> investments) {
    var filtered = investments.toList();

    // Type filter
    if (_filterState.selectedType != null) {
      filtered = filtered
          .where((i) => i.type == _filterState.selectedType)
          .toList();
    }

    // Asset type filter (specific custom asset type)
    if (_filterState.selectedAssetTypeId != null) {
      filtered = filtered
          .where((i) => i.assetTypeId == _filterState.selectedAssetTypeId)
          .toList();
    }

    // Search
    if (_filterState.searchQuery.isNotEmpty) {
      final query = _filterState.searchQuery.toLowerCase();
      filtered = filtered
          .where((i) => i.name.toLowerCase().contains(query))
          .toList();
    }

    // Sort
    switch (_filterState.sortOption) {
      case InvestmentSortOption.newest:
        filtered.sort(
          (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
            a.createdAt ?? DateTime(0),
          ),
        );
      case InvestmentSortOption.oldest:
        filtered.sort(
          (a, b) => (a.createdAt ?? DateTime(0)).compareTo(
            b.createdAt ?? DateTime(0),
          ),
        );
      case InvestmentSortOption.highest:
        filtered.sort((a, b) => b.currentValue.compareTo(a.currentValue));
      case InvestmentSortOption.lowest:
        filtered.sort((a, b) => a.currentValue.compareTo(b.currentValue));
    }

    return filtered;
  }

  /// Perform delete without confirmation (called after Dismissible confirmDismiss).
  Future<void> _performDelete(InvestmentModel investment) async {
    context.showLoadingOverlay();
    try {
      final result = await ref
          .read(investmentControllerProvider.notifier)
          .deleteInvestment(investment.id);

      if (!mounted) return;
      context.closeOverlay();

      if (result.isSuccess()) {
        context.showAppAlert(context.l10n.investmentSuccessDelete);
      } else {
        context.showAppAlert(context.l10n.investmentErrorDelete);
      }
    } finally {
      if (mounted) {
        context.closeOverlay();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final state = ref.watch(investmentControllerProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(l10n.investmentTitle),
        centerTitle: false,
        actions: [
          if (state.investments.isNotEmpty) ...[
            // Filter button
            IconButton(
              onPressed: _onFilterTap,
              tooltip: l10n.investmentFilterTitle,
              icon: Badge(
                isLabelVisible: _filterState.hasActiveFilter,
                smallSize: 8.w,
                backgroundColor: colors.primary,
                child: FaIcon(
                  FontAwesomeIcons.filter,
                  size: 16.w,
                  color: _filterState.hasActiveFilter
                      ? colors.primary
                      : colors.textSecondary,
                ),
              ),
            ),
            // Refresh prices button
            IconButton(
              onPressed: state.isPriceLoading ? null : _onRefreshPrices,
              tooltip: l10n.investmentRefreshPrice,
              icon: state.isPriceLoading
                  ? SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.primary,
                      ),
                    )
                  : FaIcon(
                      FontAwesomeIcons.arrowsRotate,
                      size: 16.w,
                      color: colors.primary,
                    ),
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddTap,
        backgroundColor: colors.primary,
        child: FaIcon(
          FontAwesomeIcons.plus,
          color: colors.onPrimary,
          size: 18.w,
        ),
      ),
      body: _buildBody(state, l10n),
    );
  }

  Widget _buildBody(InvestmentState state, dynamic l10n) {
    if (state.isLoading && state.investments.isEmpty) {
      return const Center(child: SakuLoadingIndicator());
    }

    if (state.status == InvestmentStatus.error && state.investments.isEmpty) {
      return Center(
        child: SakuErrorState(
          message: state.errorMessage ?? l10n.investmentErrorAdd,
          onRetry: _onRefresh,
        ),
      );
    }

    if (state.isEmpty) {
      return Center(
        child: SakuEmptyState(
          icon: FontAwesomeIcons.chartColumn,
          title: l10n.investmentEmptyTitle,
          message: l10n.investmentEmptySubtitle,
          actionLabel: l10n.investmentAdd,
          onAction: _onAddTap,
        ),
      );
    }

    final filteredList = _applyFilter(state.investments);

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: 16.h)),

          // ─── Portfolio Summary ───
          const SliverToBoxAdapter(child: InvestmentPortfolioSummary()),

          SliverToBoxAdapter(child: SizedBox(height: 20.h)),

          // ─── Asset List Header + Manage Asset Types ───
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  Text(
                    l10n.investmentTitle,
                    style: TextStyleConstants.b1.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _onManageAssetTypes,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(
                          FontAwesomeIcons.layerGroup,
                          size: 12.w,
                          color: context.colors.primary,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          l10n.investmentManageAssetTypes,
                          style: TextStyleConstants.label2.copyWith(
                            color: context.colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 8.h)),

          // ─── Filtered empty / Asset List ───
          if (filteredList.isEmpty && _filterState.hasActiveFilter)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32.w),
                child: SakuEmptyState(
                  icon: FontAwesomeIcons.filterCircleXmark,
                  message: l10n.investmentFilterSearch,
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final investment = filteredList[index];
                return Dismissible(
                  key: ValueKey(investment.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 24.w),
                    margin: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.expense.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: FaIcon(
                      FontAwesomeIcons.trash,
                      color: context.colors.expense,
                      size: 18.w,
                    ),
                  ),
                  confirmDismiss: (_) async {
                    final confirmed = await context.showConfirmDialog(
                      title: l10n.investmentDeleteConfirmTitle,
                      message: l10n.investmentDeleteConfirmMessage(
                        investment.name,
                      ),
                    );
                    return confirmed == true;
                  },
                  onDismissed: (_) => _performDelete(investment),
                  child: InvestmentAssetCard(
                    investment: investment,
                    onTap: () => _onAssetTap(investment),
                  ),
                );
              },
            ),

          SliverToBoxAdapter(child: SizedBox(height: 80.h)),
        ],
      ),
    );
  }
}
