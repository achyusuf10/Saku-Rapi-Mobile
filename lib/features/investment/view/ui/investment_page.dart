import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/investment/controllers/investment_controller.dart';
import 'package:app_saku_rapi/features/investment/models/investment_asset_model.dart';
import 'package:app_saku_rapi/features/investment/view/widgets/investment_shimmer.dart';
import 'package:app_saku_rapi/global/widgets/main_shell_page.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:app_saku_rapi/global/widgets/saku_card.dart';
import 'package:app_saku_rapi/global/widgets/saku_empty_state.dart';
import 'package:app_saku_rapi/global/widgets/saku_error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class InvestmentPage extends ConsumerStatefulWidget {
  const InvestmentPage({super.key});

  @override
  ConsumerState<InvestmentPage> createState() => _InvestmentPageState();
}

class _InvestmentPageState extends ConsumerState<InvestmentPage> {
  static const _investmentTabIndex = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final status = ref.read(investmentControllerProvider).status;
      if (status == InvestmentStatus.initial) {
        ref.read(investmentControllerProvider.notifier).loadDashboard();
      }
      // Load semua harga dari database (gold + bitcoin)
      final pricesStatus = ref.read(investmentPricesProvider).status;
      if (pricesStatus == PricesStatus.initial) {
        ref.read(investmentPricesProvider.notifier).loadPrices();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final state = ref.watch(investmentControllerProvider);

    ref.listen<int>(currentTabIndexProvider, (prev, next) {
      if (next == _investmentTabIndex && prev != _investmentTabIndex) {
        ref.read(investmentControllerProvider.notifier).loadDashboard();
        ref.read(investmentPricesProvider.notifier).loadPrices();
      }
    });

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(l10n.investmentTitle), centerTitle: false),
      body: _buildBody(state),
      floatingActionButton: state.status == InvestmentStatus.loaded
          ? FloatingActionButton(
              onPressed: () => context.push(AppRouter.investmentForm),
              backgroundColor: colors.primary,
              child: Icon(Icons.add, color: colors.onPrimary),
            )
          : null,
    );
  }

  Widget _buildBody(InvestmentState state) {
    final l10n = context.l10n;

    switch (state.status) {
      case InvestmentStatus.initial:
      case InvestmentStatus.loading:
        return const InvestmentShimmer();

      case InvestmentStatus.error:
        return Center(
          child: SakuErrorState(
            message: state.errorMessage ?? l10n.investmentErrorLoad,
            onRetry: () =>
                ref.read(investmentControllerProvider.notifier).loadDashboard(),
          ),
        );

      case InvestmentStatus.loaded:
        if (state.assets.isEmpty) {
          return _buildEmptyState(l10n);
        }
        return _buildContent(state);
    }
  }

  Widget _buildEmptyState(dynamic l10n) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.read(investmentControllerProvider.notifier).loadDashboard(),
          ref.read(investmentPricesProvider.notifier).loadPrices(),
        ]);
      },
      child: ListView(
        children: [
          SizedBox(height: 80.h),
          SakuEmptyState(
            icon: FontAwesomeIcons.chartLine,
            title: l10n.investmentEmpty,
            message: l10n.investmentEmptyHint,
          ),
          SizedBox(height: 24.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w),
            child: SakuButton(
              text: l10n.investmentAddAsset,
              onPressed: () => context.push(AppRouter.investmentForm),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(InvestmentState state) {
    final grouped = state.groupedActiveAssets;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.read(investmentControllerProvider.notifier).loadDashboard(),
          ref.read(investmentPricesProvider.notifier).loadPrices(),
        ]);
      },
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        children: [
          _PortfolioSummaryCard(),
          SizedBox(height: 16.h),
          // Grouped assets by type
          for (final entry in grouped.entries) ...[
            _SectionHeader(type: entry.key),
            SizedBox(height: 8.h),
            for (final asset in entry.value) ...[
              _AssetListItem(asset: asset),
              SizedBox(height: 8.h),
            ],
            SizedBox(height: 8.h),
          ],
          // Link to inactive assets
          if (state.inactiveAssets.isNotEmpty) ...[
            SizedBox(height: 8.h),
            _InactiveAssetsLink(count: state.inactiveAssets.length),
          ],
          SizedBox(height: 80.h),
        ],
      ),
    );
  }
}

// ─── Portfolio Summary Card ─────────────────────────────

class _PortfolioSummaryCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalInvested = ref.watch(investmentTotalInvestedProvider);

    // Watch prices state untuk loading indicator
    final pricesState = ref.watch(investmentPricesProvider);
    final isLoading = pricesState.isLoading;

    // Watch sync providers (sudah dihitung dgn harga efektif)
    final totalValue = ref.watch(investmentTotalValueProvider);
    final pnl = ref.watch(investmentProfitLossProvider);

    final isProfit = pnl >= 0;
    final pnlPercent = totalInvested > 0 ? ((pnl / totalInvested) * 100) : 0.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF065F46), const Color(0xFF047857)]
              : [colors.primaryDark, colors.primary],
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFF065F46).withValues(alpha: 0.4)
                : colors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.chartLine,
                size: 14.w,
                color: colors.onPrimary.withValues(alpha: 0.85),
              ),
              SizedBox(width: 8.w),
              Text(
                l10n.investmentTotalValue,
                style: TextStyleConstants.label2.copyWith(
                  color: colors.onPrimary.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          // Total value (with loading indicator)
          if (isLoading)
            SizedBox(
              height: 32.h,
              width: 150.w,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withValues(alpha: 0.5),
                ),
              ),
            )
          else
            Text(
              totalValue.toCurrency(),
              style: TextStyleConstants.h4.copyWith(
                color: colors.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          SizedBox(height: 12.h),
          // P&L badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(
                  isProfit
                      ? FontAwesomeIcons.arrowTrendUp
                      : FontAwesomeIcons.arrowTrendDown,
                  size: 12.w,
                  color: isProfit
                      ? const Color(0xFF86EFAC)
                      : const Color(0xFFFCA5A5),
                ),
                SizedBox(width: 6.w),
                if (isLoading)
                  SizedBox(
                    width: 80.w,
                    height: 14.h,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                else
                  Text(
                    '${isProfit ? '+' : ''}${pnl.toCurrency()} (${pnlPercent.toStringAsFixed(1)}%)',
                    style: TextStyleConstants.label2.copyWith(
                      color: isProfit
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFFFCA5A5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          // Bottom row: invested & profit
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.investmentTotalInvested,
                      style: TextStyleConstants.label3.copyWith(
                        color: colors.onPrimary.withValues(alpha: 0.7),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      totalInvested.toCurrency(),
                      style: TextStyleConstants.b2.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.investmentProfitLoss,
                      style: TextStyleConstants.label3.copyWith(
                        color: colors.onPrimary.withValues(alpha: 0.7),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    if (isLoading)
                      SizedBox(
                        width: 80.w,
                        height: 14.h,
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      )
                    else
                      Text(
                        '${isProfit ? '+' : ''}${pnl.toCurrency()}',
                        style: TextStyleConstants.b2.copyWith(
                          color: isProfit
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFFFCA5A5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ─────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.type});
  final InvestmentType type;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    String title;
    IconData icon;
    switch (type) {
      case InvestmentType.gold:
        title = l10n.investmentSectionGold;
        icon = FontAwesomeIcons.coins;
      case InvestmentType.bitcoin:
        title = l10n.investmentSectionBitcoin;
        icon = FontAwesomeIcons.bitcoin;
      case InvestmentType.custom:
        title = l10n.investmentSectionCustom;
        icon = FontAwesomeIcons.boxesStacked;
    }

    return Padding(
      padding: EdgeInsets.only(left: 4.w),
      child: Row(
        children: [
          FaIcon(icon, size: 14.w, color: colors.textSecondary),
          SizedBox(width: 8.w),
          Text(
            title,
            style: TextStyleConstants.label1.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Asset List Item ────────────────────────────────────

class _AssetListItem extends ConsumerWidget {
  const _AssetListItem({required this.asset});
  final InvestmentAssetModel asset;

  IconData _typeIcon(InvestmentType type) {
    switch (type) {
      case InvestmentType.gold:
        return FontAwesomeIcons.coins;
      case InvestmentType.bitcoin:
        return FontAwesomeIcons.bitcoin;
      case InvestmentType.custom:
        return FontAwesomeIcons.boxesStacked;
    }
  }

  Color _typeColor(InvestmentType type, dynamic colors) {
    switch (type) {
      case InvestmentType.gold:
        return const Color(0xFFD97706);
      case InvestmentType.bitcoin:
        return const Color(0xFFF7931A);
      case InvestmentType.custom:
        return colors.primary as Color;
    }
  }

  /// Format price source label untuk ditampilkan
  String _priceSourceLabel(String priceSource) {
    switch (priceSource) {
      case 'antaremas':
        return 'antaremas.com';
      case 'logammulia':
        return 'logammulia.com';
      case 'indodax':
        return 'indodax.com';
      case 'coingecko':
        return 'coingecko.com';
      case 'manual':
        return 'Manual';
      default:
        return priceSource;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typeColor = _typeColor(asset.type, colors);

    // Ambil harga efektif dari prices state (sync)
    final pricesState = ref.watch(investmentPricesProvider);
    final effectivePrice = pricesState.getEffectivePrice(asset);

    // Hitung nilai & PnL dengan harga efektif
    final currentValue = asset.totalUnits * effectivePrice;
    final pnl = currentValue - asset.totalInvested;
    final isProfit = pnl >= 0;
    final pnlPercent = asset.totalInvested > 0
        ? (pnl / asset.totalInvested) * 100
        : 0.0;

    return SakuCard(
      onTap: () {
        context.push(AppRouter.investmentDetail, extra: asset);
      },
      padding: EdgeInsets.all(12.w),
      child: Row(
        children: [
          // Type icon badge
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Center(
              child: FaIcon(
                _typeIcon(asset.type),
                size: 16.w,
                color: typeColor,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.name,
                  style: TextStyleConstants.b1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Text(
                      '${asset.totalUnits.toStringAsFixed(asset.type == InvestmentType.bitcoin ? 8 : 2)} ${asset.unitLabel}',
                      style: TextStyleConstants.label2.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 1.h,
                      ),
                      decoration: BoxDecoration(
                        color: colors.textSecondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        _priceSourceLabel(asset.priceSource),
                        style: TextStyleConstants.label3.copyWith(
                          color: colors.textSecondary,
                          fontSize: 9.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currentValue.toCurrency(),
                style: TextStyleConstants.b2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: (isProfit ? colors.success : colors.error).withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  '${isProfit ? '+' : ''}${pnlPercent.toStringAsFixed(1)}%',
                  style: TextStyleConstants.label3.copyWith(
                    color: isProfit ? colors.success : colors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Inactive Assets Link ───────────────────────────────

class _InactiveAssetsLink extends StatelessWidget {
  const _InactiveAssetsLink({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return InkWell(
      onTap: () => context.push(AppRouter.investmentInactive),
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.boxArchive,
              size: 14.w,
              color: colors.textSecondary,
            ),
            SizedBox(width: 8.w),
            Text(
              '${l10n.investmentViewInactive} ($count)',
              style: TextStyleConstants.b2.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
