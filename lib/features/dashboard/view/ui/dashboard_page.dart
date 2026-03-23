import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/auth/controllers/auth_controller.dart';
import 'package:app_saku_rapi/features/dashboard/controllers/dashboard_controller.dart';
import 'package:app_saku_rapi/features/dashboard/view/widgets/dashboard_balance_card.dart';
import 'package:app_saku_rapi/features/dashboard/view/widgets/dashboard_comparison_chart.dart';
import 'package:app_saku_rapi/features/dashboard/view/widgets/dashboard_period_summary.dart';
import 'package:app_saku_rapi/features/dashboard/view/widgets/dashboard_quick_actions.dart';
import 'package:app_saku_rapi/features/dashboard/view/widgets/dashboard_recent_transactions.dart';
import 'package:app_saku_rapi/features/dashboard/view/widgets/dashboard_wallet_section.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:app_saku_rapi/global/widgets/saku_error_state.dart';
import 'package:app_saku_rapi/global/widgets/saku_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Halaman utama Dashboard (tab pertama bottom nav).
///
/// Menampilkan ringkasan keuangan: greeting, total saldo (gradient card),
/// quick actions, wallet summary, period summary, chart perbandingan,
/// dan transaksi terakhir.
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Load data on first build (post-frame to avoid provider read during build)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletControllerProvider.notifier).loadWallets();
      ref.read(dashboardControllerProvider.notifier).loadDashboard();
    });
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      ref.read(walletControllerProvider.notifier).loadWallets(),
      ref.read(dashboardControllerProvider.notifier).loadDashboard(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final dashState = ref.watch(dashboardControllerProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: colors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ─── Greeting ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                  child: Text(
                    l10n.dashboardGreeting(
                      user?.fullName?.split(' ').first ?? '—',
                    ),
                    style: TextStyleConstants.h5.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),

              // ─── Body: depends on status ───
              if (dashState.status == DashboardStatus.loading &&
                  dashState.recentTransactions.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: SakuLoadingIndicator()),
                )
              else if (dashState.status == DashboardStatus.error &&
                  dashState.recentTransactions.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: SakuErrorState(
                      message:
                          dashState.errorMessage ?? l10n.dashboardComingSoon,
                      onRetry: _onRefresh,
                    ),
                  ),
                )
              else ...[
                // ─── Balance Card ───
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: const DashboardBalanceCard(),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 16.h)),

                // ─── Quick Actions ───
                const SliverToBoxAdapter(child: DashboardQuickActions()),
                SliverToBoxAdapter(child: SizedBox(height: 20.h)),

                // ─── Wallet Section ───
                const SliverToBoxAdapter(child: DashboardWalletSection()),
                SliverToBoxAdapter(child: SizedBox(height: 20.h)),

                // ─── Period Summary ───
                const SliverToBoxAdapter(child: DashboardPeriodSummary()),
                SliverToBoxAdapter(child: SizedBox(height: 20.h)),

                // ─── Comparison Chart ───
                const SliverToBoxAdapter(child: DashboardComparisonChart()),
                SliverToBoxAdapter(child: SizedBox(height: 20.h)),

                // ─── Recent Transactions ───
                const SliverToBoxAdapter(child: DashboardRecentTransactions()),
                SliverToBoxAdapter(child: SizedBox(height: 24.h)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
