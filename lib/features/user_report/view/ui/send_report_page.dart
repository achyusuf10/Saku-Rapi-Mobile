import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/user_report/controllers/send_report_controller.dart';
import 'package:app_saku_rapi/features/user_report/models/user_report_model.dart';
import 'package:app_saku_rapi/features/user_report/view/widgets/report_photo_field.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:app_saku_rapi/global/widgets/saku_dropdown.dart';
import 'package:app_saku_rapi/global/widgets/saku_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Halaman form untuk mengirim laporan ke tim SakuRapi.
///
/// Fields: Kategori, Judul, Deskripsi, Foto Lampiran (opsional).
/// Flow foto: pick → crop → local state → compress + upload saat submit.
class SendReportPage extends ConsumerStatefulWidget {
  const SendReportPage({super.key});

  @override
  ConsumerState<SendReportPage> createState() => _SendReportPageState();
}

class _SendReportPageState extends ConsumerState<SendReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final state = ref.watch(sendReportControllerProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(l10n.sendReportTitle),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
          children: [
            // ─── Kategori ───
            SakuDropdown<UserReportCategory>(
              label: l10n.sendReportCategory,
              hint: l10n.sendReportCategoryHint,
              value: state.category,
              items: UserReportCategory.values.map((cat) {
                return DropdownItem<UserReportCategory>(
                  value: cat,
                  child: Text(
                    _categoryLabel(cat, l10n),
                    style: TextStyleConstants.b2,
                  ),
                );
              }).toList(),
              onChanged: (cat) {
                if (cat != null) {
                  ref
                      .read(sendReportControllerProvider.notifier)
                      .setCategory(cat);
                }
              },
              validator: (_) {
                if (state.category == null) {
                  return l10n.sendReportValidateCategory;
                }
                return null;
              },
            ),
            SizedBox(height: 16.h),

            // ─── Judul ───
            SakuTextField(
              controller: _titleController,
              label: l10n.sendReportFormTitle,
              hint: l10n.sendReportFormTitleHint,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              validator: (value) {
                final v = value?.trim() ?? '';
                if (v.length < 5) return l10n.sendReportValidateTitle;
                return null;
              },
            ),
            SizedBox(height: 16.h),

            // ─── Deskripsi ───
            SakuTextField(
              controller: _descriptionController,
              label: l10n.sendReportDescription,
              hint: l10n.sendReportDescriptionHint,
              maxLines: 5,
              minLines: 3,
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              validator: (value) {
                final v = value?.trim() ?? '';
                if (v.length < 10) return l10n.sendReportValidateDescription;
                return null;
              },
            ),
            SizedBox(height: 16.h),

            // ─── Foto Lampiran ───
            const ReportPhotoField(),
            SizedBox(height: 32.h),

            // ─── Tombol Kirim ───
            SakuButton(
              text: l10n.sendReportSubmit,
              onPressed: state.isSubmitting ? null : _handleSubmit,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Paksa validasi kategori juga (dropdown tidak selalu trigger validator)
    final state = ref.read(sendReportControllerProvider);
    if (state.category == null) {
      context.showAppAlert(
        context.l10n.sendReportValidateCategory,
        alertType: AlertTypeEnum.warning,
      );
      return;
    }

    context.showLoadingOverlay();

    try {
      await ref.read(sendReportControllerProvider.notifier).submit(
            title: _titleController.text,
            description: _descriptionController.text,
          );

      if (!mounted) return;

      context.showAppAlert(
        context.l10n.sendReportSuccessMessage,
        customTitle: context.l10n.sendReportSuccessTitle,
        alertType: AlertTypeEnum.success,
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      context.showAppAlert(
        e.toString().replaceFirst('Exception: ', ''),
        alertType: AlertTypeEnum.error,
      );
    } finally {
      if (mounted) context.closeOverlay();
    }
  }

  String _categoryLabel(UserReportCategory cat, dynamic l10n) {
    return switch (cat) {
      UserReportCategory.bugReport => l10n.sendReportCategoryBugReport as String,
      UserReportCategory.featureRequest =>
        l10n.sendReportCategoryFeatureRequest as String,
      UserReportCategory.accountIssue =>
        l10n.sendReportCategoryAccountIssue as String,
      UserReportCategory.paymentIssue =>
        l10n.sendReportCategoryPaymentIssue as String,
      UserReportCategory.other => l10n.sendReportCategoryOther as String,
    };
  }
}
