import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/dashboard/controllers/dashboard_controller.dart';
import 'package:app_saku_rapi/features/history/view/widgets/history_transaction_tile.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:app_saku_rapi/global/widgets/saku_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// Section transaksi terbaru di dashboard.
///
/// Menampilkan 5 transaksi terbaru dengan tap untuk detail.
class DashboardRecentTransactions extends ConsumerWidget {
  const DashboardRecentTransactions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final dashState = ref.watch(dashboardControllerProvider);
    final transactions = dashState.recentTransactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Header ───
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            l10n.dashboardRecentTransactions,
            style: TextStyleConstants.b1.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
        ),
        SizedBox(height: 12.h),

        // ─── Transaction List ───
        if (transactions.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: SakuCard(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.h),
                  child: Column(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.receipt,
                        size: 28.w,
                        color: colors.textSecondary.withValues(alpha: 0.4),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        l10n.dashboardEmptyTransactions,
                        style: TextStyleConstants.label1.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: SakuCard(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Column(
                children: [
                  for (int i = 0; i < transactions.length; i++) ...[
                    HistoryTransactionTile(
                      transaction: transactions[i],
                      showDate: true,
                      onTap: () async {
                        final result = await context.push<bool>(
                          AppRouter.transactionDetail,
                          extra: transactions[i],
                        );
                        if (result == true) {
                          ref
                              .read(dashboardControllerProvider.notifier)
                              .loadDashboard();
                          ref
                              .read(walletControllerProvider.notifier)
                              .loadWallets();
                        }
                      },
                    ),
                    if (i < transactions.length - 1)
                      Divider(
                        height: 1,
                        indent: 56.w,
                        color: colors.border.withValues(alpha: 0.5),
                      ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
