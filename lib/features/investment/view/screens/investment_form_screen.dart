import 'package:app_saku_rapi/core/constants/app_constants.dart';
import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/investment/controllers/investment_controller.dart';
import 'package:app_saku_rapi/features/investment/models/investment_model.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_wallet_picker.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:app_saku_rapi/global/widgets/saku_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Formulir untuk menambah atau mengedit aset investasi.
///
/// Dikirim via [GoRouter.push] dengan `extra: InvestmentModel?` —
/// `null` berarti mode tambah, non-null berarti mode edit.
class InvestmentFormScreen extends ConsumerStatefulWidget {
  const InvestmentFormScreen({super.key, this.investment});

  /// Investasi yang akan diedit. `null` = mode tambah.
  final InvestmentModel? investment;

  @override
  ConsumerState<InvestmentFormScreen> createState() =>
      _InvestmentFormScreenState();
}

class _InvestmentFormScreenState extends ConsumerState<InvestmentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _buyPriceCtrl;
  late final TextEditingController _currentPriceCtrl;
  late final TextEditingController _notesCtrl;

  InvestmentType _selectedType = InvestmentType.gold;
  bool _deductFromWallet = false;
  WalletModel? _selectedWallet;
  bool _isSaving = false;

  bool get _isEditMode => widget.investment != null;

  @override
  void initState() {
    super.initState();
    final inv = widget.investment;

    _selectedType = inv?.type ?? InvestmentType.gold;
    _deductFromWallet = false;
    _selectedWallet = null;

    _nameCtrl = TextEditingController(text: inv?.name ?? _defaultName());
    _amountCtrl = TextEditingController(
      text: inv != null ? _formatInput(inv.amount) : '',
    );
    _buyPriceCtrl = TextEditingController(
      text: inv != null ? inv.avgBuyPrice.toStringAsFixed(0) : '',
    );
    _currentPriceCtrl = TextEditingController(
      text: inv?.customCurrentPrice != null
          ? inv!.customCurrentPrice!.toStringAsFixed(0)
          : '',
    );
    _notesCtrl = TextEditingController(text: inv?.notes ?? '');

    // Perbarui estimasi biaya saat jumlah atau harga beli berubah.
    _amountCtrl.addListener(_onCostChanged);
    _buyPriceCtrl.addListener(_onCostChanged);
  }

  @override
  void dispose() {
    _amountCtrl.removeListener(_onCostChanged);
    _buyPriceCtrl.removeListener(_onCostChanged);
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _buyPriceCtrl.dispose();
    _currentPriceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _onCostChanged() => setState(() {});

  String _defaultName() {
    switch (_selectedType) {
      case InvestmentType.gold:
        return 'Emas';
      case InvestmentType.btc:
        return 'Bitcoin';
      case InvestmentType.custom:
        return '';
    }
  }

  String _formatInput(double value) {
    if (value == value.truncateToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '');
  }

  void _onTypeChanged(InvestmentType type) {
    setState(() {
      _selectedType = type;
      // Pre-fill nama untuk gold/btc
      if (!_isEditMode) {
        if (type == InvestmentType.gold) {
          _nameCtrl.text = 'Emas';
        } else if (type == InvestmentType.btc) {
          _nameCtrl.text = 'Bitcoin';
        } else {
          _nameCtrl.clear();
        }
      }
    });
  }

  double get _estimatedCost {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    final price = double.tryParse(_buyPriceCtrl.text) ?? 0;
    return amount * price;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: FaIcon(FontAwesomeIcons.xmark, size: 18.r),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isEditMode
              ? l10n.investmentFormTitleEdit
              : l10n.investmentFormTitleAdd,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Tipe aset ──
                _SectionCard(
                  children: [
                    _FormLabel(text: l10n.investmentFormType),
                    SizedBox(height: 10.h),
                    _TypeSelector(
                      selected: _selectedType,
                      onChanged: _isEditMode ? null : _onTypeChanged,
                      l10n: l10n,
                      colors: colors,
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                // ── Detail aset ──
                _SectionCard(
                  children: [
                    // Nama aset
                    _FormLabel(text: l10n.investmentFormName),
                    SizedBox(height: 8.h),
                    SakuTextField(
                      controller: _nameCtrl,
                      hintText: l10n.investmentFormNameHint,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return l10n.investmentFormNameRequired;
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 16.h),
                    Divider(color: colors.border, height: 1),
                    SizedBox(height: 16.h),

                    // Jumlah unit
                    _FormLabel(text: l10n.investmentFormAmount),
                    SizedBox(height: 8.h),
                    SakuTextField(
                      controller: _amountCtrl,
                      hintText: '0',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,8}'),
                        ),
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return l10n.investmentFormAmountRequired;
                        }
                        final val = double.tryParse(v);
                        if (val == null || val <= 0) {
                          return l10n.investmentFormAmountInvalid;
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 16.h),
                    Divider(color: colors.border, height: 1),
                    SizedBox(height: 16.h),

                    // Harga beli
                    _FormLabel(text: l10n.investmentFormBuyPrice),
                    SizedBox(height: 8.h),
                    SakuTextField(
                      controller: _buyPriceCtrl,
                      hintText: '0',
                      prefixText: AppConstants.currencySymbol,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return l10n.investmentFormBuyPriceRequired;
                        }
                        final val = double.tryParse(v);
                        if (val == null || val <= 0) {
                          return l10n.investmentFormBuyPriceInvalid;
                        }
                        return null;
                      },
                    ),

                    // Harga saat ini (hanya jika tipe custom)
                    if (_selectedType == InvestmentType.custom) ...[
                      SizedBox(height: 16.h),
                      Divider(color: colors.border, height: 1),
                      SizedBox(height: 16.h),
                      _FormLabel(text: l10n.investmentFormCurrentPrice),
                      SizedBox(height: 8.h),
                      SakuTextField(
                        controller: _currentPriceCtrl,
                        hintText: l10n.investmentFormCurrentPriceHint,
                        prefixText: AppConstants.currencySymbol,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ],

                    SizedBox(height: 16.h),
                    Divider(color: colors.border, height: 1),
                    SizedBox(height: 16.h),

                    // Catatan
                    _FormLabel(text: l10n.investmentFormNotes),
                    SizedBox(height: 8.h),
                    SakuTextField(
                      controller: _notesCtrl,
                      hintText: l10n.investmentFormNotesHint,
                      maxLines: 2,
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                // ── Estimasi biaya ──
                if (_estimatedCost > 0)
                  _EstimatedCostBanner(
                    cost: _estimatedCost,
                    l10n: l10n,
                    colors: colors,
                  ),

                SizedBox(height: 12.h),

                // ── Potong dari dompet (hanya saat tambah) ──
                if (!_isEditMode)
                  _SectionCard(
                    children: [
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          l10n.investmentFormDeductWallet,
                          style: TextStyleConstants.b2.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          l10n.investmentFormDeductWalletSubtitle,
                          style: TextStyleConstants.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        value: _deductFromWallet,
                        onChanged: (val) =>
                            setState(() => _deductFromWallet = val),
                      ),

                      // Wallet picker
                      if (_deductFromWallet) ...[
                        SizedBox(height: 8.h),
                        Divider(color: colors.border, height: 1),
                        SizedBox(height: 12.h),
                        _FormLabel(text: l10n.investmentFormWallet),
                        SizedBox(height: 8.h),
                        _WalletPickerTile(
                          selectedWallet: _selectedWallet,
                          onTap: () async {
                            final wallet = await TransactionWalletPicker.show(
                              context,
                              selectedId: _selectedWallet?.id,
                            );
                            if (wallet != null && mounted) {
                              setState(() => _selectedWallet = wallet);
                            }
                          },
                          colors: colors,
                          l10n: l10n,
                        ),
                      ],
                    ],
                  ),

                SizedBox(height: 24.h),

                // ── Tombol simpan ──
                SakuButton(
                  text: l10n.investmentSave,
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _onSave,
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = context.l10n;

    if (_deductFromWallet && _selectedWallet == null) {
      context.showAppAlert(
        l10n.investmentFormWalletRequired,
        alertType: AlertTypeEnum.error,
      );
      return;
    }

    setState(() => _isSaving = true);
    context.showLoadingOverlay();

    final userId = Supabase.instance.client.auth.currentUser!.id;
    final amount = double.parse(_amountCtrl.text.trim());
    final buyPrice = double.parse(_buyPriceCtrl.text.trim());
    final customPrice = _currentPriceCtrl.text.trim().isNotEmpty
        ? double.tryParse(_currentPriceCtrl.text.trim())
        : null;
    final notes = _notesCtrl.text.trim().isNotEmpty
        ? _notesCtrl.text.trim()
        : null;

    final now = DateTime.now();
    final controller = ref.read(investmentControllerProvider.notifier);

    try {
      if (_isEditMode) {
        final updated = widget.investment!.copyWith(
          name: _nameCtrl.text.trim(),
          amount: amount,
          avgBuyPrice: buyPrice,
          customCurrentPrice: customPrice,
          notes: notes,
        );

        final result = await controller.editInvestment(updated);

        if (!mounted) return;
        context.closeOverlay();

        if (result.isSuccess()) {
          context.showAppAlert(l10n.investmentSuccessEdit);
          context.pop();
        } else {
          context.showAppAlert(
            result.dataError()?.$1 ?? l10n.investmentErrorEdit,
            alertType: AlertTypeEnum.error,
          );
        }
      } else {
        final newInvestment = InvestmentModel(
          id: '',
          userId: userId,
          type: _selectedType,
          name: _nameCtrl.text.trim(),
          amount: amount,
          avgBuyPrice: buyPrice,
          customCurrentPrice: customPrice,
          linkedWalletId: _deductFromWallet ? _selectedWallet?.id : null,
          notes: notes,
          createdAt: now,
          updatedAt: now,
        );

        final result = await controller.addInvestment(
          investment: newInvestment,
          deductFromWallet: _deductFromWallet,
          walletId: _selectedWallet?.id,
          userId: userId,
        );

        if (!mounted) return;
        context.closeOverlay();

        if (result.isSuccess()) {
          context.showAppAlert(l10n.investmentSuccessAdd);
          context.pop();
        } else {
          context.showAppAlert(
            result.dataError()?.$1 ?? l10n.investmentErrorAdd,
            alertType: AlertTypeEnum.error,
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Private widgets
// ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyleConstants.label1.copyWith(
        color: context.colors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({
    required this.selected,
    required this.onChanged,
    required this.l10n,
    required this.colors,
  });

  final InvestmentType selected;
  final ValueChanged<InvestmentType>? onChanged;
  final dynamic l10n;
  final dynamic colors;

  @override
  Widget build(BuildContext context) {
    final types = [
      (InvestmentType.gold, FontAwesomeIcons.coins, const Color(0xFFD4A017)),
      (InvestmentType.btc, FontAwesomeIcons.bitcoin, const Color(0xFFF7931A)),
      (
        InvestmentType.custom,
        FontAwesomeIcons.chartLine,
        (colors as dynamic).primaryLight as Color,
      ),
    ];

    final l = l10n as dynamic;
    final c = colors as dynamic;

    String labelFor(InvestmentType t) {
      switch (t) {
        case InvestmentType.gold:
          return l.investmentTypeGold as String;
        case InvestmentType.btc:
          return l.investmentTypeBtc as String;
        case InvestmentType.custom:
          return l.investmentTypeCustom as String;
      }
    }

    return Row(
      children: types.map(((InvestmentType, IconData, Color) entry) {
        final (type, icon, tColor) = entry;
        final isSelected = selected == type;
        return Expanded(
          child: GestureDetector(
            onTap: onChanged != null ? () => onChanged!(type) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.only(
                right: type != InvestmentType.custom ? 6.w : 0,
              ),
              padding: EdgeInsets.symmetric(vertical: 10.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? tColor.withOpacity(0.12)
                    : (c.surfaceVariant as Color),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: isSelected ? tColor : (c.border as Color),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  FaIcon(
                    icon,
                    size: 16.r,
                    color: isSelected ? tColor : (c.textSecondary as Color),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    labelFor(type),
                    style: TextStyleConstants.label3.copyWith(
                      color: isSelected ? tColor : (c.textSecondary as Color),
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _EstimatedCostBanner extends StatelessWidget {
  const _EstimatedCostBanner({
    required this.cost,
    required this.l10n,
    required this.colors,
  });

  final double cost;
  final dynamic l10n;
  final dynamic colors;

  @override
  Widget build(BuildContext context) {
    final c = colors as dynamic;
    final l = l10n as dynamic;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: (c.primaryLight as Color).withOpacity(0.12),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: (c.primaryLight as Color).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          FaIcon(
            FontAwesomeIcons.calculator,
            size: 13.r,
            color: c.primary as Color,
          ),
          SizedBox(width: 8.w),
          Text(
            '${l.investmentFormEstimatedCost}: ',
            style: TextStyleConstants.caption.copyWith(
              color: c.textSecondary as Color,
            ),
          ),
          Text(
            cost.toCurrency(),
            style: TextStyleConstants.b2.copyWith(
              fontWeight: FontWeight.w700,
              color: c.primary as Color,
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletPickerTile extends StatelessWidget {
  const _WalletPickerTile({
    required this.selectedWallet,
    required this.onTap,
    required this.colors,
    required this.l10n,
  });

  final WalletModel? selectedWallet;
  final VoidCallback onTap;
  final dynamic colors;
  final dynamic l10n;

  @override
  Widget build(BuildContext context) {
    final c = colors as dynamic;
    final l = l10n as dynamic;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          border: Border.all(color: c.border as Color),
          borderRadius: BorderRadius.circular(8.r),
          color: c.surfaceVariant as Color,
        ),
        child: Row(
          children: [
            FaIcon(
              FontAwesomeIcons.wallet,
              size: 14.r,
              color: c.textSecondary as Color,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                selectedWallet?.name ?? (l.investmentFormWallet as String),
                style: TextStyleConstants.b2.copyWith(
                  color: selectedWallet != null
                      ? (c.textPrimary as Color)
                      : (c.textSecondary as Color),
                ),
              ),
            ),
            FaIcon(
              FontAwesomeIcons.chevronDown,
              size: 12.r,
              color: c.textSecondary as Color,
            ),
          ],
        ),
      ),
    );
  }
}
