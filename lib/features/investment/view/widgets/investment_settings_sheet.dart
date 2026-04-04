import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/investment/controllers/investment_controller.dart';
import 'package:app_saku_rapi/features/investment/models/custom_asset_category_model.dart';
import 'package:app_saku_rapi/features/investment/models/investment_asset_model.dart';
import 'package:app_saku_rapi/features/investment/view/widgets/custom_asset_category_dialog.dart';
import 'package:app_saku_rapi/global/widgets/calculator_keyboard/calculator_keyboard.dart';
import 'package:app_saku_rapi/global/widgets/saku_bottom_sheet.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:app_saku_rapi/global/widgets/saku_currency_field.dart';
import 'package:app_saku_rapi/global/widgets/saku_dialog.dart';
import 'package:app_saku_rapi/global/widgets/saku_dropdown.dart';
import 'package:app_saku_rapi/global/widgets/saku_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Bottom sheet untuk mengedit metadata aset investasi.
///
/// Untuk tipe `custom`: menyediakan dropdown kategori (FK) agar user bisa
/// memindahkan aset ke kategori lain — `unit_label` otomatis mengikuti parent.
class InvestmentSettingsSheet extends ConsumerStatefulWidget {
  const InvestmentSettingsSheet({super.key, required this.asset});
  final InvestmentAssetModel asset;

  /// Tampilkan sebagai BottomSheet. Kembalikan `true` jika ada perubahan / delete.
  static Future<bool?> show(BuildContext context, InvestmentAssetModel asset) {
    return SakuBottomSheet.show<bool>(
      context: context,
      child: InvestmentSettingsSheet(asset: asset),
    );
  }

  @override
  ConsumerState<InvestmentSettingsSheet> createState() =>
      _InvestmentSettingsSheetState();
}

class _InvestmentSettingsSheetState
    extends ConsumerState<InvestmentSettingsSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late SakuCurrencyController _priceController;

  String? _selectedCategoryId;
  String? _selectedPriceSource;
  bool _isSaving = false;
  bool _isDeleting = false;

  InvestmentAssetModel get _asset => widget.asset;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _asset.name);
    _priceController = SakuCurrencyController(
      initialValue: _asset.currentPrice > 0 ? _asset.currentPrice : null,
    );
    _selectedCategoryId = _asset.customCategoryId;
    _selectedPriceSource = _asset.priceSource;

    // Load custom categories jika tipe custom
    if (_asset.type == InvestmentType.custom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(customAssetCategoriesProvider.notifier).load();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final categoriesState = ref.watch(customAssetCategoriesProvider);
    final categories = categoriesState.isSuccess()
        ? categoriesState.dataSuccess()!
        : <CustomAssetCategoryModel>[];

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Title ───
            Text(
              l10n.investmentSettingsTitle,
              style: TextStyleConstants.h7.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: 20.h),

            // ─── Name ───
            SakuTextField(
              controller: _nameController,
              label: l10n.investmentSettingsName,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.investmentFormAssetNameRequired
                  : null,
            ),
            SizedBox(height: 16.h),

            // ─── Current Price ───
            SakuCurrencyField(
              controller: _priceController,
              label: l10n.investmentSettingsCurrentPrice,
            ),
            SizedBox(height: 16.h),

            // ─── Price Source (Gold & Bitcoin only, PRD §3.5) ───
            if (_asset.type == InvestmentType.gold ||
                _asset.type == InvestmentType.bitcoin) ...[
              _buildPriceSourceSection(),
              SizedBox(height: 16.h),
            ],

            // ─── Category Dropdown (custom type only) ───
            if (_asset.type == InvestmentType.custom) ...[
              Text(
                l10n.investmentSettingsCategory,
                style: TextStyleConstants.label1.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: 6.h),
              _buildCategoryDropdown(categories),
              SizedBox(height: 4.h),
              Text(
                l10n.investmentSettingsCategoryHint,
                style: TextStyleConstants.label3.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              SizedBox(height: 16.h),
            ],

            // ─── Save ───
            SakuButton(
              text: l10n.investmentSettingsSave,
              isLoading: _isSaving,
              onPressed: _save,
            ),
            SizedBox(height: 16.h),

            // ─── Delete ───
            SakuButton(
              text: l10n.investmentSettingsDelete,
              isLoading: _isDeleting,
              isOutlined: true,
              onPressed: () => _confirmDelete(context),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  /// Dropdown kategori + tombol manage categories.
  Widget _buildCategoryDropdown(List<CustomAssetCategoryModel> categories) {
    final l10n = context.l10n;

    return SakuDropdown<String>(
      value: _selectedCategoryId,
      hint: l10n.investmentSettingsCategoryHint,
      suffixIcon: IconButton(
        icon: FaIcon(FontAwesomeIcons.gear, size: 18.w),
        tooltip: l10n.investmentCategoryManage,
        onPressed: () {
          CustomAssetCategoryDialog.show(context);
        },
      ),
      items: categories
          .map(
            (c) => DropdownItem<String>(
              value: c.id,
              child: Text('${c.name} (${c.unitLabel})'),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => _selectedCategoryId = v),
    );
  }

  /// Price source selection (gold: antaremas/logammulia/manual, bitcoin: indodax/coingecko/manual)
  Widget _buildPriceSourceSection() {
    final l10n = context.l10n;
    final colors = context.colors;

    final sources = _asset.type == InvestmentType.gold
        ? [
            (l10n.investmentPriceSourceAntaremas, 'antaremas'),
            (l10n.investmentPriceSourceLogammulia, 'logammulia'),
            (l10n.investmentPriceSourceManual, 'manual'),
          ]
        : [
            (l10n.investmentPriceSourceIndodax, 'indodax'),
            (l10n.investmentPriceSourceCoingecko, 'coingecko'),
            (l10n.investmentPriceSourceManual, 'manual'),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.investmentSettingsPriceSource,
          style: TextStyleConstants.label1.copyWith(color: colors.textPrimary),
        ),
        SizedBox(height: 6.h),
        SakuDropdown<String>(
          value: _selectedPriceSource,
          items: sources
              .map((s) => DropdownItem<String>(value: s.$2, child: Text(s.$1)))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _selectedPriceSource = v);
          },
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final l10n = context.l10n;
    final controller = ref.read(investmentControllerProvider.notifier);

    // Resolve unit_label from selected category for custom type
    String unitLabel = _asset.unitLabel;
    String? categoryId = _asset.customCategoryId;

    if (_asset.type == InvestmentType.custom && _selectedCategoryId != null) {
      categoryId = _selectedCategoryId;
      final catState = ref.read(customAssetCategoriesProvider);
      final catList = catState.isSuccess()
          ? catState.dataSuccess()!
          : <CustomAssetCategoryModel>[];
      final selected = catList
          .where((c) => c.id == _selectedCategoryId)
          .firstOrNull;
      if (selected != null) {
        unitLabel = selected.unitLabel;
      }
    }

    final updated = _asset.copyWith(
      name: _nameController.text.trim(),
      currentPrice: _priceController.numericValue,
      customCategoryId: categoryId,
      unitLabel: unitLabel,
      priceSource: _selectedPriceSource ?? _asset.priceSource,
    );

    try {
      final result = await controller.updateAsset(updated);

      if (!mounted) return;
      if (result.isSuccess()) {
        context.showAppAlert(
          l10n.investmentSuccessUpdate,
          alertType: AlertTypeEnum.success,
        );
        Navigator.of(context).pop(true);
      } else {
        final (msg, _, _, _) = result.dataError()!;
        context.showAppAlert(msg, alertType: AlertTypeEnum.error);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _confirmDelete(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    bool revertWallet = true;

    SakuDialog.show(
      context,
      title: l10n.investmentSettingsDelete,
      icon: Icons.delete_outline_rounded,
      positiveColor: colors.error,
      content: StatefulBuilder(
        builder: (ctx, setDialogState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.investmentSettingsDeleteConfirm(_asset.name),
              style: TextStyleConstants.b2.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            // PRD §3.5 — Optional checkbox
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: revertWallet,
              onChanged: (v) => setDialogState(() => revertWallet = v ?? true),
              title: Text(
                l10n.investmentSettingsRevertWallet,
                style: TextStyleConstants.label2.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      labelNegative: l10n.confirmCancel,
      onTapNegative: () => Navigator.of(context).pop(),
      labelPositive: l10n.walletDelete,
      onTapPositive: () {
        Navigator.of(context).pop();
        _delete(revertWallet: revertWallet);
      },
    );
  }

  Future<void> _delete({bool revertWallet = true}) async {
    setState(() => _isDeleting = true);

    final l10n = context.l10n;
    final controller = ref.read(investmentControllerProvider.notifier);

    try {
      final result = await controller.deleteAsset(
        assetId: _asset.id,
        revertWallet: revertWallet,
      );

      if (!mounted) return;
      if (result.isSuccess()) {
        context.showAppAlert(
          l10n.investmentSuccessDelete,
          alertType: AlertTypeEnum.success,
        );
        // Pop both sheet and detail page
        Navigator.of(context).pop(true);
      } else {
        final (msg, _, _, _) = result.dataError()!;
        context.showAppAlert(msg, alertType: AlertTypeEnum.error);
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }
}
