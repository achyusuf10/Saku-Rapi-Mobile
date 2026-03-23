import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/global/widgets/saku_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Halaman form tambah/edit transaksi.
///
/// Mendukung input manual, voice, dan OCR.
/// Implementasi detail ditambahkan di Phase 4.
class TransactionFormPage extends ConsumerWidget {
  const TransactionFormPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          l10n.transactionAddItem,
          style: TextStyleConstants.h6.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: SakuEmptyState(
          icon: FontAwesomeIcons.penToSquare,
          title: l10n.transactionAddItem,
          message: l10n.dashboardComingSoon,
        ),
      ),
    );
  }
}
