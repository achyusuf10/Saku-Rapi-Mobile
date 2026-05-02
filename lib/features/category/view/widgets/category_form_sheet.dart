import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/core/utils/color_utils.dart';
import 'package:app_saku_rapi/features/category/controllers/category_controller.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/category/utils/category_icon_ext.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:app_saku_rapi/global/widgets/saku_category_icon.dart';
import 'package:app_saku_rapi/global/widgets/saku_color_picker_sheet.dart';
import 'package:app_saku_rapi/global/widgets/saku_dropdown.dart';
import 'package:app_saku_rapi/global/widgets/saku_icon_picker_sheet.dart';
import 'package:app_saku_rapi/global/widgets/saku_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Bottom sheet form untuk menambah atau edit kategori.
///
/// Menampilkan form: nama, icon, warna, parent (opsional).
/// Validasi:
/// - Nama wajib diisi
/// - Parent harus bertipe sama dan bukan child
/// - Nama tidak boleh duplikat dalam scope yang sama
class CategoryFormSheet extends ConsumerStatefulWidget {
  const CategoryFormSheet({super.key, required this.type, this.editCategory});

  /// Tipe kategori yang akan ditambah/diedit.
  final CategoryType type;

  /// Kategori yang akan diedit (null = mode tambah).
  final CategoryModel? editCategory;

  /// Menampilkan form sebagai bottom sheet.
  static Future<void> show({
    required BuildContext context,
    required CategoryType type,
    CategoryModel? editCategory,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryFormSheet(type: type, editCategory: editCategory),
    );
  }

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  late String _selectedIcon;
  late String _selectedColor;
  late String _selectedBackgroundColor;
  String? _selectedParentId;
  bool _isSaving = false;

  bool get _isEdit => widget.editCategory != null;

  @override
  void initState() {
    super.initState();
    final edit = widget.editCategory;
    _nameController = TextEditingController(text: edit?.name ?? '');
    _selectedIcon = edit?.icon ?? 'tag';
    _selectedColor = edit?.color ?? '#6B7280';
    _selectedBackgroundColor =
        edit?.backgroundColor ?? kSakuDefaultIconBackgroundHex;
    _selectedParentId = edit?.parentId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom;

    // Parent categories untuk dropdown (hanya parent, tipe sama)
    final state = ref.watch(categoryControllerProvider);
    final parentOptions = state.categories
        .where(
          (c) =>
              c.type == widget.type &&
              c.parentId == null &&
              c.id != widget.editCategory?.id,
        )
        .toList();

    final previewColor = parseHexColor(_selectedColor);

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                // Title
                Text(
                  _isEdit ? l10n.categoryEdit : l10n.categoryAdd,
                  style: TextStyleConstants.h7.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20.h),

                // Preview
                Center(
                  child: SakuCategoryIcon(
                    iconName: _selectedIcon,
                    color: parseHexColor(_selectedColor),
                    backgroundFill: parseHexColor(_selectedBackgroundColor),
                    size: 56,
                    iconSize: 24,
                    borderRadius: 16,
                  ),
                ),
                SizedBox(height: 20.h),

                // Nama kategori
                SakuTextField(
                  controller: _nameController,
                  label: l10n.categoryName,
                  hint: l10n.categoryName,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.categoryNameRequired;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),

                // Icon, icon color & background pickers
                Row(
                  children: [
                    Expanded(
                      child: _PickerTile(
                        label: l10n.categoryIconPicker,
                        child: SakuCategoryIcon(
                          iconName: _selectedIcon,
                          color: parseHexColor(_selectedColor),
                          backgroundFill: parseHexColor(_selectedBackgroundColor),
                          size: 28,
                          iconSize: 12,
                          borderRadius: 8,
                        ),
                        onTap: () => _pickIcon(context),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _PickerTile(
                        label: l10n.categoryColorPicker,
                        child: Container(
                          width: 24.w,
                          height: 24.w,
                          decoration: BoxDecoration(
                            color: previewColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.border,
                              width: 1.5,
                            ),
                          ),
                        ),
                        onTap: () => _pickColor(context),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _PickerTile(
                        label: l10n.walletBackground,
                        child: SizedBox(
                          width: 24.w,
                          height: 24.w,
                          child: ClipOval(
                            child: ColoredBox(
                              color: parseHexColor(_selectedBackgroundColor),
                            ),
                          ),
                        ),
                        onTap: () => _pickBackgroundColor(context),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Parent category dropdown
                if (!_isEdit || widget.editCategory?.isParent == true) ...[
                  SakuDropdown<String?>(
                    label: l10n.categoryParent,
                    value: _selectedParentId,
                    hint: l10n.categoryNoParent,
                    items: [
                      DropdownItem<String?>(
                        value: null,
                        child: Text(
                          l10n.categoryNoParent,
                          style: TextStyleConstants.b2,
                        ),
                      ),
                      ...parentOptions.map(
                        (p) => DropdownItem<String?>(
                          value: p.id,
                          child: Row(
                            children: [
                              p.toIcon(size: 14, showBackground: false),
                              SizedBox(width: 8.w),
                              Flexible(
                                child: Text(
                                  p.name,
                                  style: TextStyleConstants.b2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedParentId = value);
                    },
                  ),
                  SizedBox(height: 24.h),
                ],

                // Save button
                SakuButton(
                  text: l10n.categorySave,
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : () => _save(context),
                ),
                SizedBox(height: 8.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickIcon(BuildContext context) async {
    final icon = await SakuIconPickerSheet.show(
      context: context,
      selectedIcon: _selectedIcon,
    );
    if (icon != null) {
      setState(() => _selectedIcon = icon);
    }
  }

  Future<void> _pickColor(BuildContext context) async {
    final color = await SakuColorPickerSheet.show(
      context: appContext ?? context,
      selectedColor: _selectedColor,
    );
    if (color != null) {
      setState(() => _selectedColor = color);
    }
  }

  Future<void> _pickBackgroundColor(BuildContext context) async {
    final color = await SakuColorPickerSheet.show(
      context: appContext ?? context,
      selectedColor: _selectedBackgroundColor,
      customTabSupportsTransparency: true,
    );
    if (color != null) {
      setState(() => _selectedBackgroundColor = color);
    }
  }

  Future<void> _save(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = context.l10n;
    final name = _nameController.text.trim();

    setState(() => _isSaving = true);

    try {
      if (_isEdit) {
        final result = await ref
            .read(categoryControllerProvider.notifier)
            .updateCategory(
              categoryId: widget.editCategory!.id,
              name: name,
              icon: _selectedIcon,
              color: _selectedColor,
              backgroundColor: _selectedBackgroundColor,
            );

        if (!context.mounted) return;

        if (result.isSuccess()) {
          context.showAppAlert(
            l10n.categorySuccessEdit(name),
            alertType: AlertTypeEnum.success,
          );
          Navigator.pop(context);
        } else {
          final (message, _, _, _) = result.dataError()!;
          context.showAppAlert(message, alertType: AlertTypeEnum.error);
        }
      } else {
        final result = await ref
            .read(categoryControllerProvider.notifier)
            .createCategory(
              name: name,
              icon: _selectedIcon,
              color: _selectedColor,
              backgroundColor: _selectedBackgroundColor,
              type: widget.type,
              parentId: _selectedParentId,
            );

        if (!context.mounted) return;

        if (result.isSuccess()) {
          context.showAppAlert(
            l10n.categorySuccessAdd(name),
            alertType: AlertTypeEnum.success,
          );
          Navigator.pop(context);
        } else {
          final (message, _, _, _) = result.dataError()!;
          context.showAppAlert(message, alertType: AlertTypeEnum.error);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

/// Helper tile untuk icon/color picker.
class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.label,
    required this.child,
    required this.onTap,
  });

  final String label;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyleConstants.label1.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: 6.h),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            height: 48.h,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: colors.border),
            ),
            child: Center(child: child),
          ),
        ),
      ],
    );
  }
}
