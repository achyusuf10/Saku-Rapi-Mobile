import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/transaction/controllers/transaction_form_controller.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Bottom save bar dengan tombol simpan berwarna sesuai tipe transaksi.
///
/// Menonaktifkan tombol saat [formState.isSaving] atau saat multi-item
/// total belum cocok dengan grand total.
class TransactionFormSaveBar extends StatelessWidget {
  const TransactionFormSaveBar({
    super.key,
    required this.formState,
    required this.onSave,
    required this.typeColor,
  });

  final TransactionFormState formState;
  final VoidCallback onSave;
  final Color typeColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    final isDisabled =
        formState.isSaving ||
        (formState.isMultiItem && !formState.isTotalMatched);

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SakuButton(
          text: l10n.transactionSave,
          icon: FaIcon(
            FontAwesomeIcons.circleCheck,
            size: 16.w,
            color: Colors.white,
          ),
          backgroundColor: typeColor,
          onPressed: isDisabled ? null : onSave,
          isLoading: formState.isSaving,
        ),
      ),
    );
  }
}
