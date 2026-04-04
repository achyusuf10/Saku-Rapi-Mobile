import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/investment/controllers/investment_controller.dart';
import 'package:app_saku_rapi/features/investment/models/investment_asset_model.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:app_saku_rapi/features/wallet/view/widgets/wallet_picker_sheet.dart';
import 'package:app_saku_rapi/global/widgets/calculator_keyboard/calculator_keyboard.dart';
import 'package:app_saku_rapi/global/widgets/saku_bottom_sheet.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:app_saku_rapi/global/widgets/saku_currency_field.dart';
import 'package:app_saku_rapi/global/widgets/saku_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Bottom sheet untuk menjual unit investasi.
class InvestmentSellSheet extends ConsumerStatefulWidget {
  const InvestmentSellSheet({super.key, required this.asset});
  final InvestmentAssetModel asset;

  /// Tampilkan sebagai BottomSheet.
  static Future<bool?> show(BuildContext context, InvestmentAssetModel asset) {
    return SakuBottomSheet.show<bool>(
      context: context,
      child: InvestmentSellSheet(asset: asset),
    );
  }

  @override
  ConsumerState<InvestmentSellSheet> createState() =>
      _InvestmentSellSheetState();
}

class _InvestmentSellSheetState extends ConsumerState<InvestmentSellSheet> {
  final _formKey = GlobalKey<FormState>();
  final _unitsController = TextEditingController();
  final _priceController = SakuCurrencyController();
  final _noteController = TextEditingController();
  late final TextEditingController _dateController;

  DateTime _selectedDate = DateTime.now();
  bool _creditWallet = false;
  WalletModel? _selectedWallet;
  bool _isSubmitting = false;

  InvestmentAssetModel get _asset => widget.asset;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(
      text:
          '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
    );
    // Pre-fill sell price with current market price
    if (_asset.currentPrice > 0) {
      _priceController.setDoubleValue(_asset.currentPrice);
    }
  }

  @override
  void dispose() {
    _unitsController.dispose();
    _priceController.dispose();
    _noteController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final isBtc = _asset.type == InvestmentType.bitcoin;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ───
            Text(
              l10n.investmentSellTitle,
              style: TextStyleConstants.h7.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              '${_asset.name} • ${_asset.totalUnits.toStringAsFixed(isBtc ? 8 : 2)} ${_asset.unitLabel}',
              style: TextStyleConstants.label2.copyWith(
                color: colors.textSecondary,
              ),
            ),
            SizedBox(height: 20.h),

            // ─── Units ───
            SakuTextField(
              controller: _unitsController,
              label: l10n.investmentSellUnits,
              hint: l10n.investmentSellUnitsHint(
                _asset.totalUnits.toStringAsFixed(isBtc ? 8 : 2),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              suffixIcon: TextButton(
                onPressed: () {
                  _unitsController.text = _asset.totalUnits.toStringAsFixed(
                    isBtc ? 8 : 2,
                  );
                },
                child: Text(l10n.investmentSellAll),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return l10n.investmentSellUnitsRequired;
                }
                final parsed = double.tryParse(v);
                if (parsed == null || parsed <= 0) {
                  return l10n.investmentSellUnitsRequired;
                }
                if (parsed > _asset.totalUnits) {
                  return l10n.investmentSellUnitsExceed(
                    _asset.totalUnits.toStringAsFixed(isBtc ? 8 : 2),
                  );
                }
                return null;
              },
            ),
            SizedBox(height: 16.h),

            // ─── Sell Price ───
            SakuCurrencyField(
              controller: _priceController,
              label: l10n.investmentSellPricePerUnit,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.investmentSellPriceRequired
                  : null,
            ),
            SizedBox(height: 16.h),

            // ─── Date ───
            SakuTextField(
              label: l10n.investmentFormDate,
              readOnly: true,
              controller: _dateController,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = picked;
                    _dateController.text =
                        '${picked.day}/${picked.month}/${picked.year}';
                  });
                }
              },
            ),
            SizedBox(height: 16.h),

            // ─── Note ───
            SakuTextField(
              controller: _noteController,
              label: l10n.investmentFormNote,
              maxLines: 2,
            ),
            SizedBox(height: 16.h),

            // ─── Credit Wallet ───
            _buildWalletSection(),
            SizedBox(height: 16.h),

            // ─── Total ───
            _buildTotalRow(),
            SizedBox(height: 24.h),

            // ─── Submit ───
            SakuButton(
              text: l10n.investmentSellConfirm,
              isLoading: _isSubmitting,
              onPressed: _submit,
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletSection() {
    final l10n = context.l10n;
    final colors = context.colors;

    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            l10n.investmentSellCreditWallet,
            style: TextStyleConstants.b2.copyWith(color: colors.textPrimary),
          ),
          subtitle: Text(
            l10n.investmentSellCreditWalletHint,
            style: TextStyleConstants.label2.copyWith(
              color: colors.textSecondary,
            ),
          ),
          value: _creditWallet,
          onChanged: (v) => setState(() {
            _creditWallet = v;
            if (!v) _selectedWallet = null;
          }),
        ),
        if (_creditWallet) ...[SizedBox(height: 8.h), _buildWalletPickerTile()],
      ],
    );
  }

  Widget _buildWalletPickerTile() {
    final l10n = context.l10n;
    final colors = context.colors;

    return GestureDetector(
      onTap: () async {
        FocusScope.of(context).unfocus();
        final result = await WalletPickerSheet.show(
          context,
          selectedWalletId: _selectedWallet?.id,
        );
        if (result != null) {
          setState(() => _selectedWallet = result);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: _selectedWallet != null ? colors.primary : colors.border,
            width: _selectedWallet != null ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: FaIcon(
                  FontAwesomeIcons.wallet,
                  size: 16.w,
                  color: colors.primary,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.investmentFormSelectWallet.toUpperCase(),
                    style: TextStyleConstants.overline.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    _selectedWallet?.name ?? l10n.investmentFormSelectWallet,
                    style: TextStyleConstants.b2.copyWith(
                      color: _selectedWallet != null
                          ? colors.textPrimary
                          : colors.textSecondary,
                      fontWeight: _selectedWallet != null
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            FaIcon(
              FontAwesomeIcons.chevronRight,
              size: 12.w,
              color: colors.textSecondary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow() {
    final colors = context.colors;
    final l10n = context.l10n;

    return ListenableBuilder(
      listenable: Listenable.merge([_unitsController, _priceController]),
      builder: (context, _) {
        final units = double.tryParse(_unitsController.text) ?? 0;
        final price = _priceController.numericValue;
        final total = units * price;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.investmentSellTotal,
              style: TextStyleConstants.b2.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            Text(
              total.toCurrency(),
              style: TextStyleConstants.h7.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.primary,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final l10n = context.l10n;
    final controller = ref.read(investmentControllerProvider.notifier);
    final units = double.parse(_unitsController.text);
    final pricePerUnit = _priceController.numericValue;

    try {
      final result = await controller.sellAsset(
        assetId: _asset.id,
        units: units,
        pricePerUnit: pricePerUnit,
        date: _selectedDate,
        note: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
        creditWallet: _creditWallet,
        walletId: _selectedWallet?.id,
      );

      if (!mounted) return;
      if (result.isSuccess()) {
        context.showAppAlert(
          l10n.investmentSuccessSell,
          alertType: AlertTypeEnum.success,
        );
        Navigator.of(context).pop(true);
      } else {
        final (msg, _, _, _) = result.dataError()!;
        context.showAppAlert(msg, alertType: AlertTypeEnum.error);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
