import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/investment/controllers/investment_controller.dart';
import 'package:app_saku_rapi/features/investment/models/custom_gold_type_model.dart';
import 'package:app_saku_rapi/global/widgets/saku_bottom_sheet.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:app_saku_rapi/global/widgets/saku_dialog.dart';
import 'package:app_saku_rapi/global/widgets/saku_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Dialog CRUD untuk custom gold types (max 2 per user).
class CustomGoldTypeDialog extends ConsumerStatefulWidget {
  const CustomGoldTypeDialog({super.key});

  static Future<void> show(BuildContext context) {
    return SakuBottomSheet.show(
      context: context,
      child: const CustomGoldTypeDialog(),
    );
  }

  @override
  ConsumerState<CustomGoldTypeDialog> createState() =>
      _CustomGoldTypeDialogState();
}

class _CustomGoldTypeDialogState extends ConsumerState<CustomGoldTypeDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customGoldTypesProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final dataState = ref.watch(customGoldTypesProvider);
    final items = dataState.isSuccess()
        ? dataState.dataSuccess()!
        : <CustomGoldTypeModel>[];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.investmentGoldTypeTitle,
              style: TextStyleConstants.h7.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            Text(
              '${items.length}/2',
              style: TextStyleConstants.label2.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),

        // List
        if (items.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Center(
              child: Text(
                l10n.investmentGoldTypeMax(2),
                style: TextStyleConstants.b2.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
        ...items.map(
          (type) => _GoldTypeItem(
            type: type,
            onEdit: () => _showEditDialog(type),
            onDelete: () => _confirmDelete(type),
          ),
        ),
        SizedBox(height: 16.h),

        // Add button
        if (items.length < 2)
          SakuButton(
            text: l10n.investmentGoldTypeAdd,
            isOutlined: true,
            onPressed: () => _showAddDialog(),
          ),
        SizedBox(height: 16.h),
      ],
    );
  }

  void _showAddDialog() {
    final l10n = context.l10n;
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    SakuDialog.show(
      context,
      title: l10n.investmentGoldTypeAdd,
      icon: Icons.add_circle_outline_rounded,
      content: Form(
        key: formKey,
        child: SakuTextField(
          controller: nameController,
          label: l10n.investmentGoldTypeName,
          hint: l10n.investmentGoldTypeNameHint,
          validator: (v) => (v == null || v.trim().isEmpty)
              ? l10n.investmentGoldTypeNameRequired
              : null,
        ),
      ),
      labelNegative: l10n.confirmCancel,
      onTapNegative: () => Navigator.of(context).pop(),
      labelPositive: l10n.investmentFormSave,
      onTapPositive: () async {
        if (!formKey.currentState!.validate()) return;
        Navigator.of(context).pop();
        final result = await ref
            .read(customGoldTypesProvider.notifier)
            .create(nameController.text.trim());
        if (!mounted) return;
        if (result.isSuccess()) {
          context.showAppAlert(
            l10n.investmentSuccessCreate(nameController.text.trim()),
            alertType: AlertTypeEnum.success,
          );
        } else {
          final (msg, _, _, _) = result.dataError()!;
          context.showAppAlert(msg, alertType: AlertTypeEnum.error);
        }
      },
    );
  }

  void _showEditDialog(CustomGoldTypeModel type) {
    final l10n = context.l10n;
    final nameController = TextEditingController(text: type.name);
    final formKey = GlobalKey<FormState>();

    SakuDialog.show(
      context,
      title: l10n.investmentGoldTypeEdit,
      icon: Icons.edit_outlined,
      content: Form(
        key: formKey,
        child: SakuTextField(
          controller: nameController,
          label: l10n.investmentGoldTypeName,
          hint: l10n.investmentGoldTypeNameHint,
          validator: (v) => (v == null || v.trim().isEmpty)
              ? l10n.investmentGoldTypeNameRequired
              : null,
        ),
      ),
      labelNegative: l10n.confirmCancel,
      onTapNegative: () => Navigator.of(context).pop(),
      labelPositive: l10n.investmentFormSave,
      onTapPositive: () async {
        if (!formKey.currentState!.validate()) return;
        Navigator.of(context).pop();
        final result = await ref
            .read(customGoldTypesProvider.notifier)
            .update(id: type.id, name: nameController.text.trim());
        if (!mounted) return;
        if (result.isSuccess()) {
          context.showAppAlert(
            l10n.investmentSuccessUpdate,
            alertType: AlertTypeEnum.success,
          );
        } else {
          final (msg, _, _, _) = result.dataError()!;
          context.showAppAlert(msg, alertType: AlertTypeEnum.error);
        }
      },
    );
  }

  void _confirmDelete(CustomGoldTypeModel type) {
    final l10n = context.l10n;
    final colors = context.colors;

    SakuDialog.show(
      context,
      title: l10n.walletDelete,
      icon: Icons.delete_outline_rounded,
      positiveColor: colors.error,
      content: Text(
        l10n.investmentGoldTypeDeleteConfirm(type.name),
        style: TextStyleConstants.b2.copyWith(color: colors.textSecondary),
        textAlign: TextAlign.center,
      ),
      labelNegative: l10n.confirmCancel,
      onTapNegative: () => Navigator.of(context).pop(),
      labelPositive: l10n.walletDelete,
      onTapPositive: () async {
        Navigator.of(context).pop();
        final result = await ref
            .read(customGoldTypesProvider.notifier)
            .delete(type.id);
        if (!mounted) return;
        if (result.isSuccess()) {
          context.showAppAlert(
            l10n.investmentSuccessDelete,
            alertType: AlertTypeEnum.success,
          );
        } else {
          final (msg, _, _, _) = result.dataError()!;
          context.showAppAlert(msg, alertType: AlertTypeEnum.error);
        }
      },
    );
  }
}

class _GoldTypeItem extends StatelessWidget {
  const _GoldTypeItem({
    required this.type,
    required this.onEdit,
    required this.onDelete,
  });

  final CustomGoldTypeModel type;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        type.name,
        style: TextStyleConstants.b1.copyWith(color: colors.textPrimary),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit, size: 18.w, color: colors.primary),
            onPressed: onEdit,
          ),
          IconButton(
            icon: Icon(Icons.delete, size: 18.w, color: colors.error),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
