import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/date_time_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/investment/controllers/investment_controller.dart';
import 'package:app_saku_rapi/features/investment/models/investment_asset_model.dart';
import 'package:app_saku_rapi/features/investment/models/investment_transaction_model.dart';
import 'package:app_saku_rapi/features/investment/view/widgets/investment_sell_sheet.dart';
import 'package:app_saku_rapi/features/investment/view/widgets/investment_settings_sheet.dart';
import 'package:app_saku_rapi/global/widgets/calculator_keyboard/calculator_keyboard.dart';
import 'package:app_saku_rapi/global/widgets/saku_card.dart';
import 'package:app_saku_rapi/global/widgets/saku_currency_field.dart';
import 'package:app_saku_rapi/global/widgets/saku_dialog.dart';
import 'package:app_saku_rapi/global/widgets/saku_error_state.dart';
import 'package:app_saku_rapi/global/widgets/saku_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class InvestmentDetailPage extends ConsumerStatefulWidget {
  const InvestmentDetailPage({super.key, required this.asset});
  final InvestmentAssetModel asset;

  @override
  ConsumerState<InvestmentDetailPage> createState() =>
      _InvestmentDetailPageState();
}

class _InvestmentDetailPageState extends ConsumerState<InvestmentDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  InvestmentAssetModel get _asset => widget.asset;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(investmentTransactionsProvider(_asset.id).notifier)
          .loadTransactions();
      // Pastikan harga sudah di-load
      final pricesStatus = ref.read(investmentPricesProvider).status;
      if (pricesStatus == PricesStatus.initial) {
        ref.read(investmentPricesProvider.notifier).loadPrices();
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

    // Watch latest asset data from dashboard state
    final dashboardState = ref.watch(investmentControllerProvider);
    final latestAsset =
        dashboardState.assets.where((a) => a.id == _asset.id).firstOrNull ??
        _asset;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        title: Text(latestAsset.name),
        actions: [
          IconButton(
            icon: FaIcon(FontAwesomeIcons.gear, size: 18.w),
            onPressed: () async {
              final changed = await InvestmentSettingsSheet.show(
                context,
                latestAsset,
              );
              if (changed == true && context.mounted) {
                // Asset may have been deleted — pop back
                if (!ref
                    .read(investmentControllerProvider)
                    .assets
                    .any((a) => a.id == _asset.id)) {
                  if (context.mounted) context.pop();
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _AssetSummaryCard(asset: latestAsset),
          SizedBox(height: 8.h),
          _QuickActionButtons(asset: latestAsset),
          SizedBox(height: 12.h),
          TabBar(
            controller: _tabController,
            labelColor: colors.primary,
            unselectedLabelColor: colors.textSecondary,
            indicatorColor: colors.primary,
            labelStyle: TextStyleConstants.label1.copyWith(
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: TextStyleConstants.label1,
            tabs: [
              Tab(text: l10n.investmentDetailBuyHistory),
              Tab(text: l10n.investmentDetailSellHistory),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TransactionList(
                  assetId: latestAsset.id,
                  isBuy: true,
                  unitLabel: latestAsset.unitLabel,
                  asset: latestAsset,
                ),
                _TransactionList(
                  assetId: latestAsset.id,
                  isBuy: false,
                  unitLabel: latestAsset.unitLabel,
                  asset: latestAsset,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Asset Summary Card ─────────────────────────────────

class _AssetSummaryCard extends ConsumerWidget {
  const _AssetSummaryCard({required this.asset});
  final InvestmentAssetModel asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final isBtc = asset.type == InvestmentType.bitcoin;

    // Ambil harga efektif dari prices state (sync)
    final pricesState = ref.watch(investmentPricesProvider);
    final effectivePrice = pricesState.getEffectivePrice(asset);

    // Hitung nilai & PnL dengan harga efektif
    final currentValue = asset.totalUnits * effectivePrice;
    final pnl = currentValue - asset.totalInvested;
    final isProfit = pnl >= 0;
    final pnlPercent = asset.totalInvested > 0
        ? (pnl / asset.totalInvested)
        : 0.0;

    return SakuCard(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current value
          Text(
            l10n.investmentDetailCurrentValue,
            style: TextStyleConstants.label2.copyWith(
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            currentValue.toCurrency(),
            style: TextStyleConstants.h6.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: 4.h),
          // P&L badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: (isProfit ? colors.success : colors.error).withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(
              '${isProfit ? '+' : ''}${pnl.toCurrency()} (${(pnlPercent * 100).toStringAsFixed(1)}%)',
              style: TextStyleConstants.label2.copyWith(
                color: isProfit ? colors.success : colors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          // Detail rows
          _DetailRow(
            label: l10n.investmentDetailTotalUnits,
            value:
                '${asset.totalUnits.toStringAsFixed(isBtc ? 8 : 2)} ${asset.unitLabel}',
          ),
          SizedBox(height: 8.h),
          _DetailRow(
            label: l10n.investmentDetailAvgBuyPrice,
            value: asset.avgBuyPrice.toCurrency(),
          ),
          SizedBox(height: 8.h),
          // Current price with optional edit pencil (PRD §3.2 — manual/custom only)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.investmentDetailCurrentPrice,
                style: TextStyleConstants.label2.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    effectivePrice.toCurrency(),
                    style: TextStyleConstants.label1.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // Only show edit for manual price source or custom type
                  if (asset.priceSource == 'manual' ||
                      asset.type == InvestmentType.custom) ...[
                    SizedBox(width: 6.w),
                    InkWell(
                      onTap: () => _showEditPriceDialog(context, ref),
                      borderRadius: BorderRadius.circular(4.r),
                      child: Padding(
                        padding: EdgeInsets.all(4.w),
                        child: FaIcon(
                          FontAwesomeIcons.penToSquare,
                          size: 14.w,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          SizedBox(height: 8.h),
          _DetailRow(
            label: l10n.investmentDetailTotalInvested,
            value: asset.totalInvested.toCurrency(),
          ),
          if (asset.totalFee > 0) ...[
            SizedBox(height: 8.h),
            _DetailRow(
              label: l10n.investmentDetailTotalFee,
              value: asset.totalFee.toCurrency(),
            ),
          ],
        ],
      ),
    );
  }

  void _showEditPriceDialog(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final priceController = SakuCurrencyController(
      initialValue: asset.currentPrice > 0 ? asset.currentPrice : null,
    );

    SakuDialog.show(
      context,
      title: l10n.investmentEditCurrentPrice,
      icon: Icons.edit_outlined,
      content: SakuCurrencyField(
        controller: priceController,
        label: l10n.investmentEditCurrentPriceHint,
      ),
      labelNegative: l10n.confirmCancel,
      onTapNegative: () {
        priceController.dispose();
        Navigator.of(context).pop();
      },
      labelPositive: l10n.investmentFormSave,
      onTapPositive: () async {
        final price = priceController.numericValue;
        priceController.dispose();
        Navigator.of(context).pop();
        if (price <= 0) return;

        final result = await ref
            .read(investmentControllerProvider.notifier)
            .updateCurrentPrice(assetId: asset.id, price: price);

        if (context.mounted) {
          if (result.isSuccess()) {
            context.showAppAlert(
              l10n.investmentSuccessUpdate,
              alertType: AlertTypeEnum.success,
            );
          } else {
            final (msg, _, _, _) = result.dataError()!;
            context.showAppAlert(msg, alertType: AlertTypeEnum.error);
          }
        }
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyleConstants.label2.copyWith(
            color: colors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyleConstants.label1.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Quick Action Buttons ───────────────────────────────

class _QuickActionButtons extends StatelessWidget {
  const _QuickActionButtons({required this.asset});
  final InvestmentAssetModel asset;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: FontAwesomeIcons.plus,
              label: l10n.investmentDetailTopUp,
              color: colors.primary,
              onTap: () {
                context.push(
                  AppRouter.investmentForm,
                  extra: {'mode': 'topup', 'asset': asset},
                );
              },
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _ActionButton(
              icon: FontAwesomeIcons.minus,
              label: l10n.investmentDetailSell,
              color: colors.error,
              onTap: () async {
                final sold = await InvestmentSellSheet.show(context, asset);
                if (sold == true && context.mounted) {
                  // Refresh after sell
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          color: color.withValues(alpha: 0.05),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, size: 14.w, color: color),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyleConstants.label1.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Transaction List ───────────────────────────────────

class _TransactionList extends ConsumerWidget {
  const _TransactionList({
    required this.assetId,
    required this.isBuy,
    required this.unitLabel,
    required this.asset,
  });

  final String assetId;
  final bool isBuy;
  final String unitLabel;
  final InvestmentAssetModel asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final txState = ref.watch(investmentTransactionsProvider(assetId));
    final transactions = isBuy
        ? txState.buyTransactions
        : txState.sellTransactions;

    switch (txState.status) {
      case InvestmentStatus.initial:
      case InvestmentStatus.loading:
        return const Center(child: SakuLoadingIndicator());

      case InvestmentStatus.error:
        return Center(
          child: SakuErrorState(
            message: txState.errorMessage ?? '',
            onRetry: () => ref
                .read(investmentTransactionsProvider(assetId).notifier)
                .loadTransactions(),
          ),
        );

      case InvestmentStatus.loaded:
        if (transactions.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(32.w),
              child: Text(
                l10n.investmentDetailNoTransactions,
                style: TextStyleConstants.b2.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ),
          );
        }
        return ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          itemCount: transactions.length,
          separatorBuilder: (_, __) => SizedBox(height: 8.h),
          itemBuilder: (context, index) {
            final tx = transactions[index];
            return _TransactionItem(
              tx: tx,
              unitLabel: unitLabel,
              onTap: isBuy
                  ? () {
                      // PRD §3.3C — tap buy row opens edit mode
                      context.push(
                        AppRouter.investmentForm,
                        extra: {
                          'mode': 'edit',
                          'asset': asset,
                          'transaction': tx,
                        },
                      );
                    }
                  : null,
            );
          },
        );
    }
  }
}

class _TransactionItem extends StatelessWidget {
  const _TransactionItem({
    required this.tx,
    required this.unitLabel,
    this.onTap,
  });

  final InvestmentTransactionModel tx;
  final String unitLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isBtc = unitLabel.toUpperCase() == 'BTC';

    return SakuCard(
      onTap: onTap,
      padding: EdgeInsets.all(12.w),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: (tx.isBuy ? colors.success : colors.error).withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Center(
              child: FaIcon(
                tx.isBuy
                    ? FontAwesomeIcons.arrowDown
                    : FontAwesomeIcons.arrowUp,
                size: 14.w,
                color: tx.isBuy ? colors.success : colors.error,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${tx.units.toStringAsFixed(isBtc ? 8 : 2)} $unitLabel',
                  style: TextStyleConstants.b2.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  tx.date.extToFormattedString(outputDateFormat: 'dd MMM yyyy'),
                  style: TextStyleConstants.label2.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                tx.totalValue.toCurrency(),
                style: TextStyleConstants.b2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                '@ ${tx.pricePerUnit.toCurrency()}',
                style: TextStyleConstants.label3.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
