import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/investment/controllers/investment_controller.dart';
import 'package:app_saku_rapi/features/investment/models/investment_model.dart';
import 'package:app_saku_rapi/features/investment/view/widgets/investment_asset_card.dart';
import 'package:app_saku_rapi/features/investment/view/widgets/investment_portfolio_summary_widget.dart';
import 'package:app_saku_rapi/features/investment/view/widgets/investment_price_ticker_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// Halaman daftar aset investasi dengan ringkasan portofolio dan ticker harga.
///
/// Mendukung pull-to-refresh dan navigasi ke [InvestmentFormScreen].
class InvestmentListScreen extends ConsumerWidget {
  const InvestmentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investmentAsync = ref.watch(investmentControllerProvider);
    final l10n = context.l10n;
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.investmentTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: FaIcon(FontAwesomeIcons.plus, size: 16.r),
            onPressed: () => context.push(AppRouter.investmentForm),
          ),
        ],
      ),
      body: investmentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: error.toString(),
          onRetry: () =>
              ref.read(investmentControllerProvider.notifier).refresh(),
        ),
        data: (investmentState) {
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(investmentControllerProvider.notifier).refresh(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: 16.h)),

                // ── Kartu ringkasan portofolio ──
                SliverToBoxAdapter(
                  child: InvestmentPortfolioSummaryWidget(
                    investmentState: investmentState,
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 12.h)),

                // ── Ticker harga live ──
                SliverToBoxAdapter(
                  child: InvestmentPriceTickerWidget(
                    investmentState: investmentState,
                    onRefresh: () => ref
                        .read(investmentControllerProvider.notifier)
                        .refreshPrices(),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 8.h)),

                // ── Header daftar ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
                    child: Text(
                      l10n.investmentPortfolio,
                      style: TextStyleConstants.b2.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ),

                // ── Daftar aset atau empty ──
                if (investmentState.investments.isEmpty)
                  SliverFillRemaining(
                    child: _EmptyView(colors: colors, l10n: l10n),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final isLoadingPrice = investmentState.isPriceRefreshing;
                      final investment = investmentState.investments[index];
                      return InvestmentAssetCard(
                        investment: investment,
                        isLoadingPrice: isLoadingPrice,
                        onEdit: () => context.push(
                          AppRouter.investmentForm,
                          extra: investment,
                        ),
                        onDelete: () =>
                            _confirmDelete(context, ref, investment),
                      );
                    }, childCount: investmentState.investments.length),
                  ),
                SliverToBoxAdapter(child: SizedBox(height: 24.h)),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    InvestmentModel investment,
  ) async {
    final l10n = context.l10n;

    final confirmed = await context.showConfirmDialog(
      title: l10n.investmentDeleteConfirmTitle,
      message: l10n.investmentDeleteConfirmMessage(investment.name),
    );

    if (confirmed != true || !context.mounted) return;

    context.showLoadingOverlay();

    final result = await ref
        .read(investmentControllerProvider.notifier)
        .removeInvestment(investment.id);

    if (!context.mounted) return;
    context.closeOverlay();

    if (result.isSuccess()) {
      context.showAppAlert(l10n.investmentSuccessDelete);
    } else {
      context.showAppAlert(
        l10n.investmentErrorDelete,
        alertType: AlertTypeEnum.error,
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Private widgets
// ─────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.colors, required this.l10n});

  final dynamic colors;
  final dynamic l10n;

  @override
  Widget build(BuildContext context) {
    final c = colors as dynamic;
    final l = l10n as dynamic;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.chartPie,
              size: 48.r,
              color: c.textSecondary as Color,
            ),
            SizedBox(height: 16.h),
            Text(
              l.investmentEmptyTitle as String,
              style: TextStyleConstants.h7.copyWith(
                fontWeight: FontWeight.w700,
                color: c.textPrimary as Color,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              l.investmentEmptySubtitle as String,
              style: TextStyleConstants.b2.copyWith(
                color: c.textSecondary as Color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.circleExclamation,
              size: 40.r,
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
