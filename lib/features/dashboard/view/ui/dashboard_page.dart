import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/global/widgets/saku_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Halaman utama Dashboard (tab pertama bottom nav).
///
/// Menampilkan ringkasan keuangan: total saldo, pengeluaran bulan ini,
/// grafik cashflow, dan transaksi terakhir.
/// Implementasi detail ditambahkan di Phase 5.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          l10n.dashboardTitle,
          style: TextStyleConstants.h6.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: Center(
        child: SakuEmptyState(
          icon: FontAwesomeIcons.chartLine,
          title: l10n.dashboardTitle,
          message: l10n.dashboardComingSoon,
        ),
      ),
    );
  }
}
