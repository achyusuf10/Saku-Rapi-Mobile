import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/investment/controllers/asset_type_controller.dart';
import 'package:app_saku_rapi/features/investment/controllers/investment_controller.dart';
import 'package:app_saku_rapi/features/investment/models/asset_type_model.dart';
import 'package:app_saku_rapi/features/investment/models/investment_model.dart';
import 'package:app_saku_rapi/features/investment/view/ui/asset_type_form_page.dart';
import 'package:app_saku_rapi/features/investment/view/widgets/investment_type_selector.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:app_saku_rapi/features/wallet/view/widgets/wallet_picker_sheet.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:app_saku_rapi/global/widgets/saku_currency_field.dart';
import 'package:app_saku_rapi/global/widgets/saku_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// Halaman form create/edit investasi.
///
/// Mode create: form kosong, opsi "Potong dari Dompet" tersedia.
/// Mode edit: form terisi data existing, tanpa opsi potong wallet.
class InvestmentFormPage extends ConsumerStatefulWidget {
  const InvestmentFormPage({super.key, this.existingInvestment});

  /// Jika diisi, form masuk mode edit.
  final InvestmentModel? existingInvestment;

  @override
  ConsumerState<InvestmentFormPage> createState() => _InvestmentFormPageState();
}

class _InvestmentFormPageState extends ConsumerState<InvestmentFormPage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _symbolCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingInvestment;
    _nameCtrl = TextEditingController(text: existing?.name ?? '');
    _symbolCtrl = TextEditingController(text: existing?.symbol ?? '');
    _amountCtrl = TextEditingController(
      text: existing != null && existing.amount > 0
          ? existing.amount.toString().replaceAll(RegExp(r'\.0$'), '')
          : '',
    );
    _notesCtrl = TextEditingController(text: existing?.notes ?? '');

    Future.microtask(() {
      if (existing != null) {
        ref
            .read(investmentFormControllerProvider.notifier)
            .loadExisting(existing);
      }
      // Load asset types for custom type picker
      ref.read(assetTypeControllerProvider.notifier).loadAssetTypes();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _symbolCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickWallet() async {
    final formState = ref.read(investmentFormControllerProvider);
    final wallet = await WalletPickerSheet.show(
      context,
      selectedWalletId: formState.linkedWallet?.id,
    );
    if (wallet != null) {
      ref
          .read(investmentFormControllerProvider.notifier)
          .setLinkedWallet(wallet);
    }
  }

  Future<void> _onDelete() async {
    final l10n = context.l10n;
    final investment = widget.existingInvestment;
    if (investment == null) return;

    final confirmed = await context.showConfirmDialog(
      title: l10n.investmentDeleteConfirmTitle,
      message: l10n.investmentDeleteConfirmMessage(investment.name),
    );

    if (confirmed != true || !mounted) return;

    context.showLoadingOverlay();
    try {
      final result = await ref
          .read(investmentControllerProvider.notifier)
          .deleteInvestment(investment.id);

      if (!mounted) return;
      context.closeOverlay();

      if (result.isSuccess()) {
        context.showAppAlert(l10n.investmentSuccessDelete);
        context.pop();
      } else {
        context.showAppAlert(l10n.investmentErrorDelete);
      }
    } finally {
      if (mounted) {
        context.closeOverlay();
      }
    }
  }

  Future<void> _onSubmit() async {
    final formCtrl = ref.read(investmentFormControllerProvider.notifier);
    final result = await formCtrl.submit();

    if (!mounted) return;

    final l10n = context.l10n;
    final isEditing = widget.existingInvestment != null;

    if (result.isSuccess()) {
      context.showAppAlert(
        isEditing ? l10n.investmentSuccessEdit : l10n.investmentSuccessAdd,
      );
      // Refresh list
      ref.read(investmentControllerProvider.notifier).refresh();
      context.pop();
    } else {
      final errorMsg = result.dataError()?.$1;
      context.showAppAlert(
        errorMsg ??
            (isEditing ? l10n.investmentErrorEdit : l10n.investmentErrorAdd),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final formState = ref.watch(investmentFormControllerProvider);
    final formCtrl = ref.read(investmentFormControllerProvider.notifier);
    final isEditing = formState.isEditing;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          isEditing
              ? l10n.investmentFormTitleEdit
              : l10n.investmentFormTitleAdd,
          style: TextStyleConstants.h6.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: FaIcon(FontAwesomeIcons.arrowLeft, size: 18.w),
        ),
        actions: [
          if (isEditing)
            IconButton(
              onPressed: _onDelete,
              tooltip: l10n.investmentDelete,
              icon: FaIcon(
                FontAwesomeIcons.trash,
                size: 16.w,
                color: colors.expense,
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Asset Type ───
            Text(
              l10n.investmentFormType,
              style: TextStyleConstants.label1.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: 10.h),
            InvestmentTypeSelector(
              selectedType: formState.type,
              onChanged: formCtrl.setType,
            ),

            SizedBox(height: 20.h),

            // ─── Custom Type: Asset Type Picker ───
            if (formState.type == 'custom') ...[
              _AssetTypePicker(
                selectedAssetType: formState.assetType,
                assetTypes: ref.watch(assetTypeListProvider),
                onChanged: formCtrl.setAssetType,
                onCreateNew: () async {
                  final result = await Navigator.of(context)
                      .push<AssetTypeModel>(
                        MaterialPageRoute(
                          builder: (_) => const AssetTypeFormPage(),
                        ),
                      );
                  if (result != null) {
                    formCtrl.setAssetType(result);
                  }
                },
              ),
              SizedBox(height: 16.h),
            ],

            // ─── Asset Name (hidden for custom — auto-populated from asset type) ───
            if (formState.type != 'custom') ...[
              _AutocompleteNameField(
                controller: _nameCtrl,
                label: l10n.investmentFormName,
                hint: l10n.investmentFormNameHint,
                suggestions: ref.watch(investmentSuggestionsProvider),
                onChanged: (v) => formCtrl.setName(v),
                onSuggestionSelected: (suggestion) {
                  _nameCtrl.text = suggestion.name;
                  formCtrl.setName(suggestion.name);
                  if (suggestion.symbol != null &&
                      suggestion.symbol!.isNotEmpty) {
                    _symbolCtrl.text = suggestion.symbol!;
                    formCtrl.setSymbol(suggestion.symbol);
                  }
                },
              ),
              SizedBox(height: 16.h),
            ],

            // ─── Amount (units) ───
            SakuTextField(
              controller: _amountCtrl,
              label: formState.type == 'gold'
                  ? '${l10n.investmentFormAmount} (${l10n.investmentGram})'
                  : l10n.investmentFormAmount,
              hint: '0',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              onChanged: (v) {
                final parsed = double.tryParse(v);
                if (parsed != null) formCtrl.setAmount(parsed);
              },
            ),

            SizedBox(height: 16.h),

            // ─── Buy Price per Unit ───
            SakuCurrencyField(
              key: ValueKey('buyPrice_${formState.existingInvestment?.id}'),
              label: l10n.investmentFormBuyPrice,
              initialValue: formState.avgBuyPrice > 0
                  ? formState.avgBuyPrice
                  : null,
              onChanged: (v) => formCtrl.setAvgBuyPrice(v),
            ),

            SizedBox(height: 16.h),

            // ─── Current Price (only for custom type WITHOUT asset type) ───
            if (formState.type == 'custom' && formState.assetType == null) ...[
              SakuCurrencyField(
                key: ValueKey(
                  'currentPrice_${formState.existingInvestment?.id}',
                ),
                label: l10n.investmentFormCurrentPrice,
                hint: l10n.investmentFormCurrentPriceHint,
                initialValue: formState.customCurrentPrice,
                onChanged: (v) =>
                    formCtrl.setCustomCurrentPrice(v > 0 ? v : null),
              ),
              SizedBox(height: 20.h),
            ] else ...[
              SizedBox(height: 4.h),
            ],

            // ─── Deduct from Wallet Toggle (only for create mode) ───
            if (!isEditing) ...[
              _DeductWalletSection(
                isEnabled: formState.deductFromWallet,
                wallet: formState.linkedWallet,
                onToggle: formCtrl.setDeductFromWallet,
                onPickWallet: _pickWallet,
              ),
              SizedBox(height: 16.h),
            ],

            // ─── Estimated Cost (shown when deduct is on) ───
            if (formState.deductFromWallet && formState.estimatedCost > 0) ...[
              _EstimatedCostBanner(
                estimatedCost: formState.estimatedCost,
                isSufficient: formState.isWalletSufficient,
              ),
              SizedBox(height: 16.h),
            ],

            // ─── Notes ───
            SakuTextField(
              controller: _notesCtrl,
              label: l10n.investmentFormNotes,
              hint: l10n.investmentFormNotesHint,
              maxLines: 3,
              onChanged: (v) => formCtrl.setNotes(v),
            ),

            SizedBox(height: 24.h),

            // ─── Submit Button ───
            SakuButton(
              text: l10n.investmentSave,
              onPressed: _onSubmit,
              isLoading: formState.isSaving,
              isEnabled: !formState.isSaving,
              icon: FaIcon(
                FontAwesomeIcons.floppyDisk,
                size: 16.w,
                color: colors.onPrimary,
              ),
            ),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}

/// Bagian toggle + wallet picker untuk "Potong dari Dompet".
class _DeductWalletSection extends StatelessWidget {
  const _DeductWalletSection({
    required this.isEnabled,
    required this.wallet,
    required this.onToggle,
    required this.onPickWallet,
  });

  final bool isEnabled;
  final WalletModel? wallet;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickWallet;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.wallet,
                size: 16.w,
                color: colors.primary,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.investmentFormDeductWallet,
                      style: TextStyleConstants.b2.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      l10n.investmentFormDeductWalletSubtitle,
                      style: TextStyleConstants.label3.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isEnabled,
                onChanged: onToggle,
                activeTrackColor: colors.primary,
              ),
            ],
          ),

          // Wallet picker (shown when enabled)
          if (isEnabled) ...[
            SizedBox(height: 12.h),
            GestureDetector(
              onTap: onPickWallet,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.buildingColumns,
                      size: 14.w,
                      color: wallet != null
                          ? colors.primary
                          : colors.textSecondary,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        wallet != null
                            ? '${wallet?.name} (${wallet?.balance.toCurrency()})'
                            : l10n.investmentFormWallet,
                        style: TextStyleConstants.b2.copyWith(
                          color: wallet != null
                              ? colors.textPrimary
                              : colors.textSecondary,
                        ),
                      ),
                    ),
                    FaIcon(
                      FontAwesomeIcons.chevronRight,
                      size: 12.w,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Banner estimasi total biaya.
class _EstimatedCostBanner extends StatelessWidget {
  const _EstimatedCostBanner({
    required this.estimatedCost,
    required this.isSufficient,
  });

  final double estimatedCost;
  final bool isSufficient;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final bgColor = isSufficient
        ? colors.primary.withValues(alpha: 0.08)
        : colors.expense.withValues(alpha: 0.08);
    final borderColor = isSufficient
        ? colors.primary.withValues(alpha: 0.3)
        : colors.expense.withValues(alpha: 0.3);
    final textColor = isSufficient ? colors.primary : colors.expense;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          FaIcon(
            isSufficient
                ? FontAwesomeIcons.circleCheck
                : FontAwesomeIcons.triangleExclamation,
            size: 16.w,
            color: textColor,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.investmentFormEstimatedCost,
                  style: TextStyleConstants.label3.copyWith(
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  estimatedCost.toCurrency(),
                  style: TextStyleConstants.b2.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Autocomplete field untuk nama aset — menampilkan saran dari investasi sebelumnya.
class _AutocompleteNameField extends StatefulWidget {
  const _AutocompleteNameField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.suggestions,
    required this.onChanged,
    required this.onSuggestionSelected,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final List<({String name, String? symbol})> suggestions;
  final ValueChanged<String> onChanged;
  final void Function(({String name, String? symbol})) onSuggestionSelected;

  @override
  State<_AutocompleteNameField> createState() => _AutocompleteNameFieldState();
}

class _AutocompleteNameFieldState extends State<_AutocompleteNameField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<({String name, String? symbol})>(
          textEditingController: widget.controller,
          focusNode: _focusNode,
          optionsBuilder: (textEditingValue) {
            final query = textEditingValue.text.toLowerCase();
            if (query.isEmpty) return const Iterable.empty();
            return widget.suggestions.where(
              (s) => s.name.toLowerCase().contains(query),
            );
          },
          displayStringForOption: (option) => option.name,
          onSelected: widget.onSuggestionSelected,
          fieldViewBuilder: (context, ctrl, focusNode, onFieldSubmitted) {
            return SakuTextField(
              controller: ctrl,
              focusNode: focusNode,
              label: widget.label,
              hint: widget.hint,
              onChanged: widget.onChanged,
              textCapitalization: TextCapitalization.words,
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12.r),
                color: colors.surface,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 200.h,
                    maxWidth: constraints.maxWidth,
                  ),
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: colors.border.withValues(alpha: 0.3),
                    ),
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        dense: true,
                        title: Text(
                          option.name,
                          style: TextStyleConstants.b2.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: option.symbol != null
                            ? Text(
                                option.symbol!,
                                style: TextStyleConstants.label2.copyWith(
                                  color: colors.textSecondary,
                                ),
                              )
                            : null,
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Autocomplete field untuk symbol — menampilkan saran symbol dari investasi sebelumnya.
class _AutocompleteSymbolField extends StatefulWidget {
  const _AutocompleteSymbolField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.suggestions,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final List<({String name, String? symbol})> suggestions;
  final ValueChanged<String> onChanged;

  @override
  State<_AutocompleteSymbolField> createState() =>
      _AutocompleteSymbolFieldState();
}

class _AutocompleteSymbolFieldState extends State<_AutocompleteSymbolField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Filter hanya yang punya symbol.
    final symbolSuggestions = widget.suggestions
        .where((s) => s.symbol != null && s.symbol!.isNotEmpty)
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<({String name, String? symbol})>(
          textEditingController: widget.controller,
          focusNode: _focusNode,
          optionsBuilder: (textEditingValue) {
            final query = textEditingValue.text.toLowerCase();
            if (query.isEmpty) return const Iterable.empty();
            return symbolSuggestions.where(
              (s) => s.symbol!.toLowerCase().contains(query),
            );
          },
          displayStringForOption: (option) => option.symbol ?? '',
          onSelected: (option) {
            widget.controller.text = option.symbol ?? '';
            widget.onChanged(option.symbol ?? '');
          },
          fieldViewBuilder: (context, ctrl, focusNode, onFieldSubmitted) {
            return SakuTextField(
              controller: ctrl,
              focusNode: focusNode,
              label: widget.label,
              hint: widget.hint,
              onChanged: widget.onChanged,
              textCapitalization: TextCapitalization.characters,
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12.r),
                color: colors.surface,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 200.h,
                    maxWidth: constraints.maxWidth,
                  ),
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: colors.border.withValues(alpha: 0.3),
                    ),
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        dense: true,
                        title: Text(
                          option.symbol ?? '',
                          style: TextStyleConstants.b2.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          option.name,
                          style: TextStyleConstants.label2.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Dropdown picker untuk memilih jenis aset kustom.
class _AssetTypePicker extends StatelessWidget {
  const _AssetTypePicker({
    required this.selectedAssetType,
    required this.assetTypes,
    required this.onChanged,
    required this.onCreateNew,
  });

  final AssetTypeModel? selectedAssetType;
  final List<AssetTypeModel> assetTypes;
  final ValueChanged<AssetTypeModel?> onChanged;
  final VoidCallback onCreateNew;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.investmentFormAssetType,
          style: TextStyleConstants.label1.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),

        // Picker button
        GestureDetector(
          onTap: () => _showAssetTypePicker(context),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: selectedAssetType != null
                    ? colors.primary.withValues(alpha: 0.5)
                    : colors.border.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Center(
                    child: FaIcon(
                      FontAwesomeIcons.layerGroup,
                      size: 16.w,
                      color: selectedAssetType != null
                          ? colors.primary
                          : colors.textSecondary,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: selectedAssetType != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedAssetType!.name,
                              style: TextStyleConstants.b2.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              selectedAssetType!.currentPrice.toCurrency(),
                              style: TextStyleConstants.label3.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          l10n.investmentFormAssetTypeHint,
                          style: TextStyleConstants.b2.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                ),
                FaIcon(
                  FontAwesomeIcons.chevronDown,
                  size: 12.w,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAssetTypePicker(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(top: 12.h),
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),

              // Title
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Text(
                  l10n.investmentFormAssetType,
                  style: TextStyleConstants.h6.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ),

              // Asset type list
              if (assetTypes.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 24.h,
                  ),
                  child: Text(
                    l10n.investmentFormAssetTypeEmpty,
                    style: TextStyleConstants.b2.copyWith(
                      color: colors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 300.h),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    itemCount: assetTypes.length,
                    itemBuilder: (_, index) {
                      final at = assetTypes[index];
                      final isSelected = selectedAssetType?.id == at.id;
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        selected: isSelected,
                        selectedTileColor: colors.primary.withValues(
                          alpha: isDark ? 0.15 : 0.08,
                        ),
                        leading: Container(
                          width: 36.w,
                          height: 36.w,
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(
                              alpha: isDark ? 0.2 : 0.1,
                            ),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Center(
                            child: FaIcon(
                              FontAwesomeIcons.chartLine,
                              size: 14.w,
                              color: colors.primary,
                            ),
                          ),
                        ),
                        title: Text(
                          at.name,
                          style: TextStyleConstants.b2.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          at.currentPrice.toCurrency(),
                          style: TextStyleConstants.label3.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        trailing: isSelected
                            ? FaIcon(
                                FontAwesomeIcons.circleCheck,
                                size: 18.w,
                                color: colors.primary,
                              )
                            : null,
                        onTap: () {
                          onChanged(at);
                          Navigator.of(ctx).pop();
                        },
                      );
                    },
                  ),
                ),

              // Create new button
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
                child: SakuButton(
                  text: l10n.investmentFormCreateAssetType,
                  isOutlined: true,
                  icon: FaIcon(
                    FontAwesomeIcons.plus,
                    size: 14.w,
                    color: colors.primary,
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    onCreateNew();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
