import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/investment/controllers/investment_controller.dart';
import 'package:app_saku_rapi/features/investment/models/investment_asset_model.dart';
import 'package:app_saku_rapi/global/widgets/saku_card.dart';
import 'package:app_saku_rapi/global/widgets/saku_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// Halaman daftar aset investasi yang sudah tidak aktif (total units = 0).
class InvestmentInactivePage extends ConsumerWidget {
  const InvestmentInactivePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final state = ref.watch(investmentControllerProvider);
    final inactiveAssets = state.assets.where((a) => !a.isActive).toList();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(l10n.investmentInactiveTitle)),
      body: inactiveAssets.isEmpty
          ? SakuEmptyState(
              title: l10n.investmentInactiveEmpty,
              message: l10n.investmentInactiveHint,
              icon: Icons.inventory_2_outlined,
            )
          : ListView.separated(
              padding: EdgeInsets.all(16.w),
              itemCount: inactiveAssets.length,
              separatorBuilder: (_, index) => SizedBox(height: 8.h),
              itemBuilder: (_, index) =>
                  _InactiveAssetItem(asset: inactiveAssets[index]),
            ),
    );
  }
}

class _InactiveAssetItem extends StatelessWidget {
  const _InactiveAssetItem({required this.asset});
  final InvestmentAssetModel asset;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return SakuCard(
      onTap: () {
        context.push(AppRouter.investmentDetail, extra: asset);
      },
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Row(
          children: [
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
                  SizedBox(height: 4.h),
                  Text(
                    l10n.investmentTransactionCount(asset.transactionsCount),
                    style: TextStyleConstants.label2.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '${l10n.investmentDetailTotalInvested}: ${asset.totalInvested.toCurrency()}',
                    style: TextStyleConstants.label2.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: colors.textSecondary.withValues(alpha: 0.1),
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                l10n.investmentSettingsInactive,
                style: TextStyleConstants.label3.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
