import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/date_time_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/dashboard/controllers/dashboard_controller.dart';
import 'package:app_saku_rapi/features/history/view/widgets/history_transaction_tile.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:app_saku_rapi/global/widgets/saku_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// Section transaksi terbaru di dashboard.
///
/// Menampilkan 5 transaksi terbaru yang digroup per tanggal,
/// dengan header tanggal tiap grup dan tombol "Lihat Semua".
class DashboardRecentTransactions extends ConsumerWidget {
  const DashboardRecentTransactions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final dashState = ref.watch(dashboardControllerProvider);
    final transactions = dashState.recentTransactions;

    // Group transactions by date key (yyyy-MM-dd), preserve order.
    final Map<String, List<TransactionModel>> grouped = {};
    for (final tx in transactions) {
      final key = _dateKey(tx.date);
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Header ───
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.dashboardRecentTransactions,
                style: TextStyleConstants.b1.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => context.go(AppRouter.history),
                child: Text(
                  l10n.dashboardSeeAll,
                  style: TextStyleConstants.label1.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
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
                        color: colors.textSecondary.withValues(alpha: 0.5),
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
          for (final entry in grouped.entries) ...[
            // ─── Date Group Header ───
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                _dateLabel(entry.key, context),
                style: TextStyleConstants.label1.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 8.h),

            // ─── Transactions per Group ───
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: SakuCard(
                padding: EdgeInsets.symmetric(vertical: 4.h),
                child: Column(
                  children: [
                    for (int i = 0; i < entry.value.length; i++) ...[
                      HistoryTransactionTile(
                        transaction: entry.value[i],
                        showDate: false,
                        onTap: () async {
                          final result = await context.push<bool>(
                            AppRouter.transactionDetail,
                            extra: entry.value[i],
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
                      if (i < entry.value.length - 1)
                        Divider(height: 1, indent: 56.w, color: colors.border),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),
          ],
      ],
    );
  }

  /// Membuat key unik berdasarkan tanggal (yyyy-MM-dd) untuk pengelompokan.
  String _dateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  /// Mengembalikan label tanggal yang mudah dibaca.
  ///
  /// Menampilkan "Hari Ini", "Kemarin", atau format "EEE, dd MMM".
  String _dateLabel(String dateKey, BuildContext context) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final todayKey = _dateKey(now);
    final yesterdayKey = _dateKey(now.subtract(const Duration(days: 1)));

    if (dateKey == todayKey) return l10n.dashboardToday;
    if (dateKey == yesterdayKey) return l10n.dashboardYesterday;

    final parts = dateKey.split('-');
    final date = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    return date.extToFormattedString(outputDateFormat: 'EEE, dd MMM');
  }
}
