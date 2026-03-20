import 'package:app_saku_rapi/core/constants/app_constants.dart';
import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:app_saku_rapi/features/wallet/utils/wallet_icon_data.dart';
import 'package:app_saku_rapi/features/wallet/view/widgets/wallet_color_picker.dart';
import 'package:app_saku_rapi/features/wallet/view/widgets/wallet_icon_picker.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:app_saku_rapi/global/widgets/saku_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Form untuk menambah atau mengedit wallet.
///
/// Jika [wallet] diberikan (via GoRouter extra), mode = **edit**.
/// Jika tidak, mode = **create**.
class WalletFormScreen extends ConsumerStatefulWidget {
  const WalletFormScreen({super.key, this.wallet});

  /// Wallet yang akan diedit. `null` = mode create.
  final WalletModel? wallet;

  @override
  ConsumerState<WalletFormScreen> createState() => _WalletFormScreenState();
}

class _WalletFormScreenState extends ConsumerState<WalletFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _balanceCtrl;
  late bool _excludeFromTotal;
  late String _selectedIcon;
  late String _selectedColor;
  bool _isSaving = false;

  bool get _isEditMode => widget.wallet != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.wallet?.name ?? '');
    _balanceCtrl = TextEditingController(
      text: widget.wallet != null
          ? widget.wallet!.initialBalance.toStringAsFixed(0)
          : '',
    );
    _excludeFromTotal = widget.wallet?.excludeFromTotal ?? false;
    _selectedIcon = widget.wallet?.icon ?? 'wallet';
    _selectedColor = widget.wallet?.color ?? '#10B981';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;
    final l10n = context.l10n;

    final iconColor = _hexToColor(_selectedColor);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? l10n.walletEdit : l10n.walletAdd),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Icon Preview ──
                Center(
                  child: Container(
                    width: 72.r,
                    height: 72.r,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: FaIcon(
                        getWalletIcon(_selectedIcon),
                        size: 32.r,
                        color: iconColor,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20.h),

                // ── Icon & Color Pickers (Row) ──
                Row(
                  children: [
                    Expanded(
                      child: _PickerTile(
                        label: l10n.walletIcon,
                        icon: FontAwesomeIcons.icons,
                        onTap: _pickIcon,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _PickerTile(
                        label: l10n.walletColor,
                        icon: FontAwesomeIcons.palette,
                        trailing: Container(
                          width: 20.r,
                          height: 20.r,
                          decoration: BoxDecoration(
                            color: iconColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        onTap: _pickColor,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20.h),

                // ── Nama Dompet ──
                _Label(text: l10n.walletName),
                SizedBox(height: 6.h),
                SakuTextField(
                  controller: _nameCtrl,
                  hintText: l10n.walletNameHint,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.walletNameRequired;
                    }
                    return null;
                  },
                ),

                SizedBox(height: 20.h),

                // ── Saldo Awal ──
                _Label(text: l10n.walletInitialBalance),
                SizedBox(height: 6.h),
                SakuTextField(
                  controller: _balanceCtrl,
                  hintText: '0',
                  prefixText: AppConstants.currencySymbol,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.walletBalanceRequired;
                    }
                    return null;
                  },
                ),

                SizedBox(height: 20.h),

                // ── Switch Exclude from Total ──
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: appColors.surface,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l10n.walletExcludeFromTotal,
                      style: TextStyleConstants.b1.copyWith(
                        color: appColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      l10n.walletExcludeHint,
                      style: TextStyleConstants.caption.copyWith(
                        color: appColors.textSecondary,
                      ),
                    ),
                    value: _excludeFromTotal,
                    onChanged: (val) => setState(() => _excludeFromTotal = val),
                  ),
                ),

                SizedBox(height: 32.h),

                // ── Tombol Simpan ──
                SakuButton(
                  text: l10n.walletSave,
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _onSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Pickers
  // ─────────────────────────────────────────────────────────────

  Future<void> _pickIcon() async {
    final result = await WalletIconPicker.show(context, current: _selectedIcon);
    if (result != null) {
      setState(() => _selectedIcon = result);
    }
  }

  Future<void> _pickColor() async {
    final result = await WalletColorPicker.show(
      context,
      current: _selectedColor,
    );
    if (result != null) {
      setState(() => _selectedColor = result);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Aksi simpan
  // ─────────────────────────────────────────────────────────────

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final balance = double.tryParse(_balanceCtrl.text.trim()) ?? 0;
    final controller = ref.read(walletControllerProvider.notifier);
    final l10n = context.l10n;
    final now = DateTime.now();

    setState(() => _isSaving = true);

    try {
      if (_isEditMode) {
        final updated = widget.wallet!.copyWith(
          name: name,
          icon: _selectedIcon,
          color: _selectedColor,
          initialBalance: balance,
          excludeFromTotal: _excludeFromTotal,
          updatedAt: now,
        );
        final result = await controller.editWallet(updated);

        if (!mounted) return;
        if (result.isSuccess()) {
          context.showAppAlert(l10n.walletSuccessEdit(name));
          context.pop();
        } else {
          context.showAppAlert(
            result.dataError()?.$1 ?? l10n.walletErrorEdit,
            alertType: AlertTypeEnum.error,
          );
        }
      } else {
        final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
        final newWallet = WalletModel(
          id: '',
          userId: userId,
          name: name,
          icon: _selectedIcon,
          color: _selectedColor,
          balance: balance,
          initialBalance: balance,
          currency: 'IDR',
          excludeFromTotal: _excludeFromTotal,
          createdAt: now,
          updatedAt: now,
        );
        final result = await controller.addWallet(newWallet);

        if (!mounted) return;
        if (result.isSuccess()) {
          context.showAppAlert(l10n.walletSuccessAdd(name));
          context.pop();
        } else {
          context.showAppAlert(
            result.dataError()?.$1 ?? l10n.walletErrorAdd,
            alertType: AlertTypeEnum.error,
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Helper hex → Color
  // ─────────────────────────────────────────────────────────────

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('FF');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

// ═══════════════════════════════════════════════════════════════
// Helper widgets
// ═══════════════════════════════════════════════════════════════

class _Label extends StatelessWidget {
  const _Label({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;

    return Text(
      text,
      style: TextStyleConstants.label1.copyWith(
        fontWeight: FontWeight.w600,
        color: appColors.textPrimary,
      ),
    );
  }
}

/// Tile kecil untuk membuka picker (icon / color).
class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.label,
    required this.icon,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;

    return Material(
      color: appColors.surface,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Row(
            children: [
              FaIcon(icon, size: 16.r, color: appColors.textSecondary),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  label,
                  style: TextStyleConstants.b2.copyWith(
                    color: appColors.textPrimary,
                  ),
                ),
              ),
              ?trailing,
              SizedBox(width: 4.w),
              FaIcon(
                FontAwesomeIcons.chevronRight,
                size: 12.r,
                color: appColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
