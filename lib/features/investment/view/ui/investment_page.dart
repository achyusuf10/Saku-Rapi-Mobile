import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/global/widgets/saku_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Halaman investasi (tab keempat bottom nav).
///
/// Menampilkan portofolio investasi, aset, dan unrealized P/L.
/// Implementasi detail ditambahkan di Phase 11.
class InvestmentPage extends ConsumerWidget {
  const InvestmentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          l10n.investmentTitle,
          style: TextStyleConstants.h6.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: Center(
        child: SakuEmptyState(
          icon: FontAwesomeIcons.chartColumn,
          title: l10n.investmentTitle,
          message: l10n.dashboardComingSoon,
        ),
      ),
    );
  }
}
