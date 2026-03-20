import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/dashboard/controllers/dashboard_controller.dart';
import 'package:app_saku_rapi/features/dashboard/view/widgets/dashboard_header_widget.dart';
import 'package:app_saku_rapi/features/dashboard/view/widgets/dashboard_recent_transactions_widget.dart';
import 'package:app_saku_rapi/features/dashboard/view/widgets/dashboard_snapshot_chart_widget.dart';
import 'package:app_saku_rapi/features/dashboard/view/widgets/dashboard_top_expenses_widget.dart';
import 'package:app_saku_rapi/features/dashboard/view/widgets/dashboard_wallet_preview_widget.dart';
import 'package:app_saku_rapi/features/parsing_dictionary/controllers/parsing_dictionary_controller.dart';
import 'package:app_saku_rapi/features/voice_input/view/ui/voice_input_sheet.dart';
import 'package:app_saku_rapi/global/widgets/saku_expandable_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// Layar dashboard utama — pusat kendali finansial SakuRapi.
///
/// Menggunakan [CustomScrollView] + [SliverToBoxAdapter] untuk performa.
/// Mendukung pull-to-refresh via [RefreshIndicator].
/// [SakuExpandableFab] ditempatkan sebagai floatingActionButton.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Trigger load kamus parsing saat app start
    ref.watch(parsingDictionaryControllerProvider);

    final appColors = context.colors;

    return Scaffold(
      backgroundColor: appColors.background,
      floatingActionButton: SakuExpandableFab(
        onVoiceTapped: () {
          showModalBottomSheet(
            context: context,
            isDismissible: false,
            enableDrag: false,
            backgroundColor: Colors.transparent,
            builder: (_) => const VoiceInputSheet(),
          );
        },
        onScanTapped: () {
          context.push(AppRouter.ocrScan);
        },
        onManualTapped: () {
          context.push(AppRouter.transactionForm);
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: RefreshIndicator(
        color: appColors.primary,
        onRefresh: () async {
          await ref.read(dashboardControllerProvider.notifier).refresh();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Header (saldo total + greeting) ──
            const SliverToBoxAdapter(child: DashboardHeaderWidget()),

            // ── Spacing ──
            SliverToBoxAdapter(child: SizedBox(height: 20.h)),

            // ── Wallet preview ──
            const SliverToBoxAdapter(child: DashboardWalletPreviewWidget()),

            // ── Spacing ──
            SliverToBoxAdapter(child: SizedBox(height: 20.h)),

            // ── Snapshot chart ──
            const SliverToBoxAdapter(child: DashboardSnapshotChartWidget()),

            // ── Spacing ──
            SliverToBoxAdapter(child: SizedBox(height: 20.h)),

            // ── Top expenses ──
            const SliverToBoxAdapter(child: DashboardTopExpensesWidget()),

            // ── Spacing ──
            SliverToBoxAdapter(child: SizedBox(height: 20.h)),

            // ── Recent transactions ──
            const SliverToBoxAdapter(
              child: DashboardRecentTransactionsWidget(),
            ),

            // ── Bottom padding untuk FAB ──
            SliverToBoxAdapter(child: SizedBox(height: 100.h)),
          ],
        ),
      ),
    );
  }
}
