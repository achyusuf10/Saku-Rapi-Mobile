import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/investment/controllers/investment_controller.dart';
import 'package:app_saku_rapi/features/investment/models/custom_asset_category_model.dart';
import 'package:app_saku_rapi/global/widgets/saku_bottom_sheet.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:app_saku_rapi/global/widgets/saku_dialog.dart';
import 'package:app_saku_rapi/global/widgets/saku_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Dialog CRUD untuk custom asset categories (max 3 per user).
/// `unit_label` disimpan di sini — aset `custom` membaca dari parent-nya.
class CustomAssetCategoryDialog extends ConsumerStatefulWidget {
  const CustomAssetCategoryDialog({super.key});

  static Future<void> show(BuildContext context) {
    return SakuBottomSheet.show(
      context: context,
      child: const CustomAssetCategoryDialog(),
    );
  }

  @override
  ConsumerState<CustomAssetCategoryDialog> createState() =>
      _CustomAssetCategoryDialogState();
}

class _CustomAssetCategoryDialogState
    extends ConsumerState<CustomAssetCategoryDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customAssetCategoriesProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final dataState = ref.watch(customAssetCategoriesProvider);
    final items = dataState.isSuccess()
        ? dataState.dataSuccess()!
        : <CustomAssetCategoryModel>[];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.investmentCategoryTitle,
              style: TextStyleConstants.h7.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            Text(
              '${items.length}/3',
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
                    l10n.investmentCategoryMax(3),
                    style: TextStyleConstants.b2.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ...items.map(
              (cat) => _CategoryItem(
                category: cat,
                onEdit: () => _showEditDialog(cat),
                onDelete: () => _confirmDelete(cat),
              ),
            ),
            SizedBox(height: 16.h),

            // Add button
            if (items.length < 3)
              SakuButton(
                text: l10n.investmentCategoryAdd,
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
    final unitLabelController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    SakuDialog.show(
      context,
      title: l10n.investmentCategoryAdd,
      icon: Icons.add_circle_outline_rounded,
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SakuTextField(
              controller: nameController,
              label: l10n.investmentCategoryName,
              hint: l10n.investmentCategoryNameHint,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.investmentCategoryNameRequired
                  : null,
            ),
            SizedBox(height: 12.h),
            SakuTextField(
              controller: unitLabelController,
              label: l10n.investmentCategoryUnitLabel,
              hint: l10n.investmentCategoryUnitLabelHint,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.investmentCategoryUnitLabelRequired
                  : null,
            ),
          ],
        ),
      ),
      labelNegative: l10n.confirmCancel,
      onTapNegative: () => Navigator.of(context).pop(),
      labelPositive: l10n.investmentFormSave,
      onTapPositive: () async {
        if (!formKey.currentState!.validate()) return;
        Navigator.of(context).pop();
        final result = await ref
            .read(customAssetCategoriesProvider.notifier)
            .create(
              name: nameController.text.trim(),
              unitLabel: unitLabelController.text.trim(),
            );
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

  void _showEditDialog(CustomAssetCategoryModel category) {
    final l10n = context.l10n;
    final nameController = TextEditingController(text: category.name);
    final unitLabelController = TextEditingController(text: category.unitLabel);
    final formKey = GlobalKey<FormState>();

    SakuDialog.show(
      context,
      title: l10n.investmentCategoryEdit,
      icon: Icons.edit_outlined,
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SakuTextField(
              controller: nameController,
              label: l10n.investmentCategoryName,
              hint: l10n.investmentCategoryNameHint,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.investmentCategoryNameRequired
                  : null,
            ),
            SizedBox(height: 12.h),
            SakuTextField(
              controller: unitLabelController,
              label: l10n.investmentCategoryUnitLabel,
              hint: l10n.investmentCategoryUnitLabelHint,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.investmentCategoryUnitLabelRequired
                  : null,
            ),
          ],
        ),
      ),
      labelNegative: l10n.confirmCancel,
      onTapNegative: () => Navigator.of(context).pop(),
      labelPositive: l10n.investmentFormSave,
      onTapPositive: () async {
        if (!formKey.currentState!.validate()) return;
        Navigator.of(context).pop();
        final result = await ref
            .read(customAssetCategoriesProvider.notifier)
            .update(
              id: category.id,
              name: nameController.text.trim(),
              unitLabel: unitLabelController.text.trim(),
            );
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

  void _confirmDelete(CustomAssetCategoryModel category) {
    final l10n = context.l10n;
    final colors = context.colors;

    SakuDialog.show(
      context,
      title: l10n.walletDelete,
      icon: Icons.delete_outline_rounded,
      positiveColor: colors.error,
      content: Text(
        l10n.investmentCategoryDeleteConfirm(category.name),
        style: TextStyleConstants.b2.copyWith(color: colors.textSecondary),
        textAlign: TextAlign.center,
      ),
      labelNegative: l10n.confirmCancel,
      onTapNegative: () => Navigator.of(context).pop(),
      labelPositive: l10n.walletDelete,
      onTapPositive: () async {
        Navigator.of(context).pop();
        final result = await ref
            .read(customAssetCategoriesProvider.notifier)
            .delete(category.id);
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

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final CustomAssetCategoryModel category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        category.name,
        style: TextStyleConstants.b1.copyWith(color: colors.textPrimary),
      ),
      subtitle: Text(
        category.unitLabel,
        style: TextStyleConstants.label2.copyWith(color: colors.textSecondary),
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
