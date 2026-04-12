import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/date_time_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/investment/controllers/investment_controller.dart';
import 'package:app_saku_rapi/features/investment/controllers/investment_form_controller.dart';
import 'package:app_saku_rapi/features/investment/models/custom_asset_category_model.dart';
import 'package:app_saku_rapi/features/investment/models/investment_asset_model.dart';
import 'package:app_saku_rapi/features/investment/view/widgets/custom_asset_category_dialog.dart';
import 'package:app_saku_rapi/features/investment/view/widgets/custom_gold_type_dialog.dart';
import 'package:app_saku_rapi/global/widgets/calculator_keyboard/calculator_keyboard.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:app_saku_rapi/global/widgets/saku_currency_field.dart';
import 'package:app_saku_rapi/global/widgets/saku_dialog.dart';
import 'package:app_saku_rapi/global/widgets/saku_dropdown.dart';
import 'package:app_saku_rapi/global/widgets/saku_text_field.dart';
import 'package:app_saku_rapi/global/widgets/saku_wallet_picker_sheet.dart';
import 'package:app_saku_rapi/global/widgets/saku_wallet_picker_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// Page form investasi multi-mode.
///
/// Extra via GoRouter:
/// - null → mode create
/// - `Map{'mode': 'topup', 'asset': InvestmentAssetModel}` → mode topup
/// - `Map{'mode': 'edit', 'asset': ..., 'transaction': ...}` → mode edit
class InvestmentSmartFormPage extends ConsumerStatefulWidget {
  const InvestmentSmartFormPage({super.key, this.extra});
  final Object? extra;

  @override
  ConsumerState<InvestmentSmartFormPage> createState() =>
      _InvestmentSmartFormPageState();
}

class _InvestmentSmartFormPageState
    extends ConsumerState<InvestmentSmartFormPage> {
  final _formKey = GlobalKey<FormState>();

  // TextEditingControllers tetap di page layer karena
  // mereka manage text state sendiri (tidak perlu masuk Riverpod).
  final _nameController = TextEditingController();
  final _unitsController = TextEditingController();
  final _priceController = SakuCurrencyController();
  final _feeController = SakuCurrencyController();
  final _noteController = TextEditingController();
  final _currentPriceController = SakuCurrencyController();

  @override
  void initState() {
    super.initState();
    // ref belum tersedia di initState, tunda ke post-frame callback.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initForm());
  }

  void _initForm() {
    final ctrl = ref.read(investmentFormControllerProvider.notifier);
    ctrl.initFromExtra(widget.extra);

    // Prefill text controllers jika mode edit
    final formState = ref.read(investmentFormControllerProvider);
    if (formState.mode == InvestmentFormMode.edit &&
        formState.existingTx != null) {
      final tx = formState.existingTx!;
      _unitsController.text = tx.units.toString();
      _priceController.setDoubleValue(tx.pricePerUnit);
      if (tx.fee > 0) {
        _feeController.setDoubleValue(tx.fee);
      }
      _noteController.text = tx.note ?? '';
    }

    // Load master data
    ref.read(customGoldTypesProvider.notifier).load();
    ref.read(customAssetCategoriesProvider.notifier).load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitsController.dispose();
    _priceController.dispose();
    _feeController.dispose();
    _noteController.dispose();
    _currentPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Hanya watch mode — jarang berubah, aman di top level.
    final mode = ref.watch(
      investmentFormControllerProvider.select((s) => s.mode),
    );

    return Scaffold(
      backgroundColor: colors.background,
      appBar: _buildAppBar(mode),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            // ─── Create-only fields ───
            if (mode == InvestmentFormMode.create) ...[
              _buildNameField(),
              SizedBox(height: 16.h),
              const _TypeSelectorSection(),
              SizedBox(height: 16.h),
              const _GoldFieldsSection(),
              const _CustomCategorySection(),
            ],

            // ─── Shared fields ───
            _buildUnitsField(),
            SizedBox(height: 16.h),
            _buildPriceField(),
            SizedBox(height: 16.h),
            _buildFeeField(),
            SizedBox(height: 16.h),
            _CurrentPriceSection(controller: _currentPriceController),
            const _DatePickerSection(),
            SizedBox(height: 16.h),
            _buildNoteField(),
            SizedBox(height: 16.h),
            if (mode != InvestmentFormMode.edit) const _WalletSection(),
            SizedBox(height: 24.h),
            _SubmitButtonSection(
              formKey: _formKey,
              nameController: _nameController,
              unitsController: _unitsController,
              priceController: _priceController,
              feeController: _feeController,
              noteController: _noteController,
              currentPriceController: _currentPriceController,
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────

  AppBar _buildAppBar(InvestmentFormMode mode) {
    final l10n = context.l10n;
    final colors = context.colors;

    String title;
    switch (mode) {
      case InvestmentFormMode.create:
        title = l10n.investmentFormCreateTitle;
      case InvestmentFormMode.topup:
        title = l10n.investmentFormTopUpTitle;
      case InvestmentFormMode.edit:
        title = l10n.investmentFormEditTitle;
    }

    return AppBar(
      title: Text(title),
      actions: [
        if (mode == InvestmentFormMode.edit)
          IconButton(
            icon: FaIcon(
              FontAwesomeIcons.trashCan,
              size: 18.w,
              color: colors.error,
            ),
            onPressed: _confirmDeleteTransaction,
          ),
      ],
    );
  }

  // ─── Static Fields (tidak perlu rebuild dari controller) ───

  Widget _buildNameField() {
    final l10n = context.l10n;
    return SakuTextField(
      controller: _nameController,
      label: l10n.investmentFormAssetName,
      hint: l10n.investmentFormAssetNameHint,
      validator: (v) => (v == null || v.trim().isEmpty)
          ? l10n.investmentFormAssetNameRequired
          : null,
    );
  }

  Widget _buildUnitsField() {
    final l10n = context.l10n;
    return SakuTextField(
      controller: _unitsController,
      label: l10n.investmentFormUnits,
      hint: l10n.investmentFormUnitsHint,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return l10n.investmentFormUnitsRequired;
        }
        final parsed = double.tryParse(v);
        if (parsed == null || parsed <= 0) {
          return l10n.investmentFormUnitsRequired;
        }
        return null;
      },
    );
  }

  Widget _buildPriceField() {
    final l10n = context.l10n;
    return SakuCurrencyField(
      controller: _priceController,
      label: l10n.investmentFormPricePerUnit,
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return l10n.investmentFormPricePerUnitRequired;
        }
        return null;
      },
    );
  }

  Widget _buildFeeField() {
    final l10n = context.l10n;
    return SakuCurrencyField(
      controller: _feeController,
      label: l10n.investmentFormFee,
      hint: l10n.investmentFormFeeHint,
    );
  }

  Widget _buildNoteField() {
    final l10n = context.l10n;
    return SakuTextField(
      controller: _noteController,
      label: l10n.investmentFormNote,
      maxLines: 2,
    );
  }

  // ─── Delete Transaction (Edit mode, PRD §3.3C) ────────

  void _confirmDeleteTransaction() {
    final l10n = context.l10n;
    final colors = context.colors;
    final ctrl = ref.read(investmentFormControllerProvider.notifier);

    SakuDialog.show(
      context,
      title: l10n.investmentDeleteTransaction,
      icon: Icons.delete_outline_rounded,
      positiveColor: colors.error,
      content: Text(
        l10n.investmentDeleteTransactionConfirm,
        style: TextStyleConstants.b2.copyWith(color: colors.textSecondary),
        textAlign: TextAlign.center,
      ),
      labelNegative: l10n.confirmCancel,
      onTapNegative: () => Navigator.of(context).pop(),
      labelPositive: l10n.investmentDeleteTransaction,
      onTapPositive: () async {
        Navigator.of(context).pop();

        context.showLoadingOverlay();
        try {
          final result = await ctrl.deleteTransaction();

          if (!mounted) return;
          context.closeOverlay();

          if (result.isSuccess()) {
            context.showAppAlert(
              l10n.investmentSuccessDeleteTransaction,
              alertType: AlertTypeEnum.success,
            );
            context.pop();
          } else {
            final (msg, _, _, _) = result.dataError()!;
            context.showAppAlert(msg, alertType: AlertTypeEnum.error);
          }
        } catch (_) {
          if (mounted) context.closeOverlay();
        }
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  SECTION WIDGETS — masing-masing ConsumerWidget, rebuild mandiri
// ═══════════════════════════════════════════════════════════

// ─── Type Selector ──────────────────────────────────────

/// Selector tipe investasi (Gold / Bitcoin / Custom).
/// Rebuild hanya saat `selectedType` berubah.
class _TypeSelectorSection extends ConsumerWidget {
  const _TypeSelectorSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final selectedType = ref.watch(
      investmentFormControllerProvider.select((s) => s.selectedType),
    );
    final ctrl = ref.read(investmentFormControllerProvider.notifier);

    final types = [
      (InvestmentType.gold, l10n.investmentTypeGold, FontAwesomeIcons.coins),
      (
        InvestmentType.bitcoin,
        l10n.investmentTypeBitcoin,
        FontAwesomeIcons.bitcoin,
      ),
      (
        InvestmentType.custom,
        l10n.investmentTypeCustom,
        FontAwesomeIcons.boxesStacked,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.investmentFormType,
          style: TextStyleConstants.label1.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: types.map((t) {
            final isSelected = selectedType == t.$1;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: InkWell(
                  onTap: () => ctrl.setType(t.$1),
                  borderRadius: BorderRadius.circular(12.r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      vertical: 12.h,
                      horizontal: 4.w,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isSelected ? colors.primary : colors.border,
                        width: isSelected ? 2 : 1,
                      ),
                      color: isSelected
                          ? colors.primary.withValues(alpha: 0.1)
                          : colors.surfaceVariant,
                    ),
                    child: Column(
                      children: [
                        FaIcon(
                          t.$3,
                          size: 20.w,
                          color: isSelected
                              ? colors.primary
                              : colors.textSecondary,
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          t.$2,
                          style: TextStyleConstants.label2.copyWith(
                            color: isSelected
                                ? colors.primary
                                : colors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Gold Fields (Gold Type + Price Source) ──────────────

/// Gold type dropdown + price source dropdown.
/// Rebuild saat `selectedType` berubah (show/hide).
class _GoldFieldsSection extends ConsumerWidget {
  const _GoldFieldsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedType = ref.watch(
      investmentFormControllerProvider.select((s) => s.selectedType),
    );

    if (selectedType != InvestmentType.gold) return const SizedBox.shrink();

    return Column(
      children: [
        const _GoldTypeDropdown(),
        SizedBox(height: 16.h),
        const _PriceSourceDropdown(),
        SizedBox(height: 16.h),
      ],
    );
  }
}

/// Dropdown jenis emas (Antam, Perhiasan, Custom).
/// Rebuild saat `selectedGoldType` berubah.
class _GoldTypeDropdown extends ConsumerWidget {
  const _GoldTypeDropdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final selectedGoldType = ref.watch(
      investmentFormControllerProvider.select((s) => s.selectedGoldType),
    );
    final customGoldTypesState = ref.watch(customGoldTypesProvider);
    final ctrl = ref.read(investmentFormControllerProvider.notifier);

    final List<_DropdownOption> options = [
      _DropdownOption(label: l10n.investmentGoldAntam, value: 'antam'),
      _DropdownOption(label: l10n.investmentGoldPerhiasan, value: 'perhiasan'),
    ];

    if (customGoldTypesState.isSuccess()) {
      final customTypes = customGoldTypesState.dataSuccess()!;
      for (final ct in customTypes) {
        options.add(
          _DropdownOption(
            customGoldTypeId: ct.id,
            label: ct.name,
            value: ct.name.toLowerCase(),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.investmentFormGoldType,
              style: TextStyleConstants.label1.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextButton.icon(
              onPressed: () => CustomGoldTypeDialog.show(context),
              icon: FaIcon(FontAwesomeIcons.plus, size: 12.w),
              label: Text(
                l10n.investmentManageGoldTypes,
                style: TextStyleConstants.label2,
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        SakuDropdown<String>(
          value: selectedGoldType,
          hint: l10n.investmentFormGoldTypeHint,
          items: options
              .map(
                (o) =>
                    DropdownItem<String>(value: o.value, child: Text(o.label)),
              )
              .toList(),
          onChanged: (value) {
            final selected = options.where((o) => o.value == value).firstOrNull;
            ctrl.setGoldType(
              value,
              customGoldTypeId: selected?.customGoldTypeId,
            );
          },
        ),
      ],
    );
  }
}

/// Dropdown sumber harga (antaremas / logammulia / manual).
/// Rebuild saat `selectedPriceSource` atau `isPriceSourceLocked` berubah.
class _PriceSourceDropdown extends ConsumerWidget {
  const _PriceSourceDropdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final selectedPriceSource = ref.watch(
      investmentFormControllerProvider.select((s) => s.selectedPriceSource),
    );
    final isLocked = ref.watch(
      investmentFormControllerProvider.select((s) => s.isPriceSourceLocked),
    );
    final ctrl = ref.read(investmentFormControllerProvider.notifier);

    final sources = [
      (l10n.investmentPriceSourceAntaremas, 'antaremas'),
      (l10n.investmentPriceSourceLogammulia, 'logammulia'),
      (l10n.investmentPriceSourceManual, 'manual'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.investmentFormPriceSource,
          style: TextStyleConstants.label1.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        SakuDropdown<String>(
          value: selectedPriceSource,
          enabled: !isLocked,
          items: sources
              .map((s) => DropdownItem<String>(value: s.$2, child: Text(s.$1)))
              .toList(),
          onChanged: (v) {
            if (v != null) ctrl.setPriceSource(v);
          },
        ),
        if (isLocked) ...[
          SizedBox(height: 4.h),
          Text(
            l10n.investmentPriceSourceLocked,
            style: TextStyleConstants.label3.copyWith(
              color: colors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Custom Category Dropdown ───────────────────────────

/// Wrapper yang show/hide berdasarkan `selectedType`.
class _CustomCategorySection extends ConsumerWidget {
  const _CustomCategorySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedType = ref.watch(
      investmentFormControllerProvider.select((s) => s.selectedType),
    );

    if (selectedType != InvestmentType.custom) return const SizedBox.shrink();

    return Column(
      children: [
        const _CustomCategoryDropdown(),
        SizedBox(height: 16.h),
      ],
    );
  }
}

/// Dropdown kategori custom asset.
/// Rebuild saat `selectedCustomCategoryId` berubah.
class _CustomCategoryDropdown extends ConsumerWidget {
  const _CustomCategoryDropdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final selectedId = ref.watch(
      investmentFormControllerProvider.select(
        (s) => s.selectedCustomCategoryId,
      ),
    );
    final categoriesState = ref.watch(customAssetCategoriesProvider);
    final ctrl = ref.read(investmentFormControllerProvider.notifier);

    List<CustomAssetCategoryModel> categories = [];
    if (categoriesState.isSuccess()) {
      categories = categoriesState.dataSuccess()!;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.investmentFormCustomCategory,
              style: TextStyleConstants.label1.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextButton(
              onPressed: () => CustomAssetCategoryDialog.show(context),
              child: Text(l10n.investmentCategoryManage),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        SakuDropdown<String>(
          value: selectedId,
          hint: l10n.investmentFormCustomCategoryHint,
          items: categories
              .map(
                (c) => DropdownItem<String>(
                  value: c.id,
                  child: Text('${c.name} (${c.unitLabel})'),
                ),
              )
              .toList(),
          onChanged: (value) => ctrl.setCustomCategory(value),
        ),
      ],
    );
  }
}

// ─── Current Price Section ──────────────────────────────

/// Menampilkan field current price hanya jika price source = manual & mode create.
/// Rebuild saat `showCurrentPriceField` berubah.
class _CurrentPriceSection extends ConsumerWidget {
  const _CurrentPriceSection({required this.controller});

  final SakuCurrencyController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final show = ref.watch(
      investmentFormControllerProvider.select((s) => s.showCurrentPriceField),
    );

    if (!show) return const SizedBox.shrink();

    return Column(
      children: [
        SakuCurrencyField(
          controller: controller,
          label: context.l10n.investmentFormCurrentPrice,
        ),
        SizedBox(height: 16.h),
      ],
    );
  }
}

// ─── Date Picker ────────────────────────────────────────

/// Date picker yang rebuild saat `selectedDate` berubah.
class _DatePickerSection extends ConsumerWidget {
  const _DatePickerSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selectedDate = ref.watch(
      investmentFormControllerProvider.select((s) => s.selectedDate),
    );
    final ctrl = ref.read(investmentFormControllerProvider.notifier);
    final date = selectedDate ?? DateTime.now();

    return SakuTextField(
      label: l10n.investmentFormDate,
      readOnly: true,
      controller: TextEditingController(
        text: date.extToFormattedString(outputDateFormat: 'dd/MM/yyyy HH:mm'),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 1)),
        );
        if (picked == null || !context.mounted) return;

        final pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(date),
        );
        if (!context.mounted) return;

        final resolvedTime = pickedTime ?? TimeOfDay.fromDateTime(date);
        ctrl.setDate(
          DateTime(
            picked.year,
            picked.month,
            picked.day,
            resolvedTime.hour,
            resolvedTime.minute,
          ),
        );
      },
    );
  }
}

// ─── Wallet Section ─────────────────────────────────────

/// Toggle deduct wallet + wallet picker tile.
/// Rebuild saat `deductWallet` berubah.
class _WalletSection extends ConsumerWidget {
  const _WalletSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final deductWallet = ref.watch(
      investmentFormControllerProvider.select((s) => s.deductWallet),
    );
    final ctrl = ref.read(investmentFormControllerProvider.notifier);

    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            l10n.investmentFormDeductWallet,
            style: TextStyleConstants.b2.copyWith(color: colors.textPrimary),
          ),
          subtitle: Text(
            l10n.investmentFormDeductWalletHint,
            style: TextStyleConstants.label2.copyWith(
              color: colors.textSecondary,
            ),
          ),
          value: deductWallet,
          onChanged: (v) => ctrl.setDeductWallet(v),
        ),
        if (deductWallet) ...[SizedBox(height: 8.h), const _WalletPickerTile()],
      ],
    );
  }
}

/// Tile wallet picker (tap untuk buka SakuWalletPickerSheet).
/// Rebuild hanya saat `selectedWallet` berubah.
class _WalletPickerTile extends ConsumerWidget {
  const _WalletPickerTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selectedWallet = ref.watch(
      investmentFormControllerProvider.select((s) => s.selectedWallet),
    );
    final ctrl = ref.read(investmentFormControllerProvider.notifier);

    return SakuWalletPickerTile(
      label: l10n.investmentFormSelectWallet,
      selected: selectedWallet,
      placeholder: l10n.investmentFormSelectWallet,
      useBorder: true,
      onTap: () async {
        FocusScope.of(context).unfocus();
        final result = await SakuWalletPickerSheet.show(
          context,
          selectedWalletId: selectedWallet?.id,
        );
        if (result != null) ctrl.setWallet(result);
      },
    );
  }
}

// ─── Submit Button ──────────────────────────────────────

/// Submit button yang rebuild saat `status` berubah (saving indicator).
class _SubmitButtonSection extends ConsumerWidget {
  const _SubmitButtonSection({
    required this.formKey,
    required this.nameController,
    required this.unitsController,
    required this.priceController,
    required this.feeController,
    required this.noteController,
    required this.currentPriceController,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController unitsController;
  final SakuCurrencyController priceController;
  final SakuCurrencyController feeController;
  final TextEditingController noteController;
  final SakuCurrencyController currentPriceController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isSaving = ref.watch(
      investmentFormControllerProvider.select((s) => s.isSaving),
    );

    // Listen untuk navigasi setelah saved/error
    ref.listen(investmentFormControllerProvider.select((s) => s.status), (
      prev,
      next,
    ) {
      if (next == InvestmentFormStatus.saved) {
        final mode = ref.read(investmentFormControllerProvider).mode;
        switch (mode) {
          case InvestmentFormMode.create:
            context.showAppAlert(
              l10n.investmentSuccessCreate(nameController.text.trim()),
              alertType: AlertTypeEnum.success,
            );
          case InvestmentFormMode.topup:
            context.showAppAlert(
              l10n.investmentSuccessTopUp,
              alertType: AlertTypeEnum.success,
            );
          case InvestmentFormMode.edit:
            context.showAppAlert(
              l10n.investmentSuccessEdit,
              alertType: AlertTypeEnum.success,
            );
        }
        context.pop();
      } else if (next == InvestmentFormStatus.error) {
        final error = ref.read(investmentFormControllerProvider).errorMessage;
        if (error != null) {
          context.showAppAlert(error, alertType: AlertTypeEnum.error);
        }
      }
    });

    return SakuButton(
      text: l10n.investmentFormSave,
      isLoading: isSaving,
      onPressed: () => _submit(context, ref),
    );
  }

  void _submit(BuildContext context, WidgetRef ref) {
    if (!formKey.currentState!.validate()) return;

    final formState = ref.read(investmentFormControllerProvider);
    if (formState.deductWallet && formState.selectedWallet == null) {
      context.showAppAlert(
        context.l10n.investmentWalletRequired,
        alertType: AlertTypeEnum.error,
      );
      return;
    }

    final ctrl = ref.read(investmentFormControllerProvider.notifier);
    ctrl.submit(
      name: nameController.text.trim(),
      units: double.tryParse(unitsController.text) ?? 0,
      pricePerUnit: priceController.numericValue,
      fee: feeController.numericValue,
      currentPrice: currentPriceController.numericValue,
      note: noteController.text.trim().isNotEmpty
          ? noteController.text.trim()
          : null,
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Shared helpers
// ═══════════════════════════════════════════════════════════

/// Helper model untuk dropdown options.
class _DropdownOption {
  const _DropdownOption({
    this.customGoldTypeId,
    required this.label,
    required this.value,
  });

  final String? customGoldTypeId;
  final String label;
  final String value;
}
