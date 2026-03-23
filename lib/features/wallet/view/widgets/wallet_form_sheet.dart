import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/category/utils/category_icon_mapper.dart';
import 'package:app_saku_rapi/features/category/view/widgets/category_color_picker_sheet.dart';
import 'package:app_saku_rapi/features/category/view/widgets/category_icon_picker_sheet.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:app_saku_rapi/global/widgets/saku_currency_field.dart';
import 'package:app_saku_rapi/global/widgets/saku_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Bottom sheet form untuk menambah atau mengedit wallet.
///
/// Menampilkan form: nama, saldo awal (hanya saat create),
/// icon picker, color picker, exclude_from_total toggle.
class WalletFormSheet extends ConsumerStatefulWidget {
  const WalletFormSheet({super.key, this.editWallet});

  /// Jika tidak null, form dalam mode edit.
  final WalletModel? editWallet;

  /// Helper untuk menampilkan form sebagai bottom sheet.
  static Future<void> show(BuildContext context, {WalletModel? editWallet}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WalletFormSheet(editWallet: editWallet),
    );
  }

  @override
  ConsumerState<WalletFormSheet> createState() => _WalletFormSheetState();
}

class _WalletFormSheetState extends ConsumerState<WalletFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;

  late String _selectedIcon;
  late String _selectedColor;
  late bool _excludeFromTotal;
  double _initialBalance = 0;
  bool _isSaving = false;

  bool get _isEdit => widget.editWallet != null;

  @override
  void initState() {
    super.initState();
    final w = widget.editWallet;
    _nameController = TextEditingController(text: w?.name ?? '');
    _balanceController = TextEditingController(
      text: w != null && w.initialBalance > 0
          ? ThousandInputFormatter.formatNumber(w.initialBalance)
          : '',
    );
    _selectedIcon = w?.icon ?? 'wallet';
    _selectedColor = w?.color ?? '#10B981';
    _excludeFromTotal = w?.excludeFromTotal ?? false;
    _initialBalance = w?.initialBalance ?? 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Handle bar ───
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

                // ─── Title ───
                Text(
                  _isEdit ? l10n.walletEdit : l10n.walletAdd,
                  style: TextStyleConstants.h6.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20.h),

                // ─── Nama ───
                SakuTextField(
                  controller: _nameController,
                  label: l10n.walletName,
                  hint: l10n.walletNameHint,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.walletNameRequired;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),

                // ─── Saldo Awal (hanya saat create) ───
                if (!_isEdit) ...[
                  SakuCurrencyField(
                    controller: _balanceController,
                    label: l10n.walletInitialBalance,
                    initialValue: _initialBalance > 0 ? _initialBalance : null,
                    onChanged: (value) => _initialBalance = value,
                    validator: (value) {
                      // Saldo awal boleh 0
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),
                ],

                // ─── Icon & Color pickers ───
                Row(
                  children: [
                    Expanded(
                      child: _PickerTile(
                        label: l10n.walletIcon,
                        child: FaIcon(
                          CategoryIconMapper.getIcon(_selectedIcon),
                          size: 20.w,
                          color: colors.textPrimary,
                        ),
                        onTap: () => _pickIcon(context),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _PickerTile(
                        label: l10n.walletColor,
                        child: Container(
                          width: 24.w,
                          height: 24.w,
                          decoration: BoxDecoration(
                            color: _parseColor(_selectedColor),
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
                  ],
                ),
                SizedBox(height: 16.h),

                // ─── Exclude from total toggle ───
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.walletExcludeFromTotal,
                              style: TextStyleConstants.b2.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              l10n.walletExcludeHint,
                              style: TextStyleConstants.label2.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _excludeFromTotal,
                        activeTrackColor: colors.primary,
                        onChanged: (val) {
                          setState(() => _excludeFromTotal = val);
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),

                // ─── Save button ───
                SakuButton(
                  text: l10n.walletSave,
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : () => _save(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────── Actions ─────────────────

  Future<void> _pickIcon(BuildContext context) async {
    final result = await CategoryIconPickerSheet.show(
      context: context,
      selectedIcon: _selectedIcon,
    );
    if (result != null && mounted) {
      setState(() => _selectedIcon = result);
    }
  }

  Future<void> _pickColor(BuildContext context) async {
    final result = await CategoryColorPickerSheet.show(
      context: context,
      selectedColor: _selectedColor,
    );
    if (result != null && mounted) {
      setState(() => _selectedColor = result);
    }
  }

  Future<void> _save(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final l10n = context.l10n;
    final name = _nameController.text.trim();

    try {
      if (_isEdit) {
        final result = await ref
            .read(walletControllerProvider.notifier)
            .updateWallet(
              walletId: widget.editWallet!.id,
              name: name,
              icon: _selectedIcon,
              color: _selectedColor,
              excludeFromTotal: _excludeFromTotal,
            );

        if (!context.mounted) return;

        if (result.isSuccess()) {
          context.showAppAlert(
            l10n.walletSuccessEdit(name),
            alertType: AlertTypeEnum.success,
          );
          Navigator.pop(context);
        } else {
          final (message, _, _, _) = result.dataError()!;
          context.showAppAlert(message, alertType: AlertTypeEnum.error);
        }
      } else {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        final result = await ref
            .read(walletControllerProvider.notifier)
            .createWallet(
              userId: userId,
              name: name,
              icon: _selectedIcon,
              color: _selectedColor,
              initialBalance: _initialBalance,
              excludeFromTotal: _excludeFromTotal,
            );

        if (!context.mounted) return;

        if (result.isSuccess()) {
          context.showAppAlert(
            l10n.walletSuccessAdd(name),
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

  Color _parseColor(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }
}

/// Tile helper untuk icon / color picker.
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
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
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
