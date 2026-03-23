import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/category/utils/category_icon_mapper.dart';
import 'package:app_saku_rapi/features/category/view/widgets/category_picker_sheet.dart';
import 'package:app_saku_rapi/features/transaction/controllers/transaction_form_controller.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_item_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_item_row.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_type_selector.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:app_saku_rapi/features/wallet/view/widgets/wallet_picker_sheet.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:app_saku_rapi/global/widgets/saku_currency_field.dart';
import 'package:app_saku_rapi/global/widgets/saku_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// Halaman form tambah/edit transaksi manual.
///
/// Mendukung 5 tipe: expense, income, transfer, debt, loan.
/// Form field berubah berdasarkan tipe yang dipilih.
/// Submit menggunakan RPC atomik anti double-submit.
///
/// Cara pakai:
/// ```dart
/// context.push(AppRouter.transactionForm);
/// // atau dengan transaksi existing untuk edit:
/// context.push(AppRouter.transactionForm, extra: existingTransaction);
/// ```
class TransactionFormPage extends ConsumerStatefulWidget {
  const TransactionFormPage({super.key, this.existingTransaction});

  /// Jika ada, form berada di mode edit.
  final TransactionModel? existingTransaction;

  @override
  ConsumerState<TransactionFormPage> createState() =>
      _TransactionFormPageState();
}

class _TransactionFormPageState extends ConsumerState<TransactionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _merchantController = TextEditingController();
  final _noteController = TextEditingController();
  final _withPersonController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = ref.read(transactionFormControllerProvider.notifier);

      if (widget.existingTransaction != null) {
        ctrl.loadExistingTransaction(widget.existingTransaction!);
        // Pre-fill text fields
        _merchantController.text =
            widget.existingTransaction!.merchantName ?? '';
        _noteController.text = widget.existingTransaction!.note ?? '';
        _withPersonController.text =
            widget.existingTransaction!.withPerson ?? '';
      } else {
        // Single-item mode default
        ctrl.initSingleItem();
      }

      // Ensure wallets are loaded
      ref.read(walletControllerProvider.notifier).loadWallets();
    });
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _noteController.dispose();
    _withPersonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final formState = ref.watch(transactionFormControllerProvider);
    final isEditing = formState.isEditing;
    final isSaving = formState.isSaving;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          isEditing ? l10n.transactionNewTitle : l10n.transactionNewTitle,
          style: TextStyleConstants.h6.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: isEditing
            ? [
                IconButton(
                  icon: FaIcon(
                    FontAwesomeIcons.trashCan,
                    size: 18.w,
                    color: colors.error,
                  ),
                  onPressed: isSaving ? null : _confirmDelete,
                ),
              ]
            : null,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.only(bottom: 100.h),
          children: [
            // ─── Type selector ───
            SizedBox(height: 12.h),
            TransactionTypeSelector(
              selected: formState.type,
              onChanged: isEditing
                  ? (_) {}
                  : (t) => ref
                        .read(transactionFormControllerProvider.notifier)
                        .setType(t),
              enabled: !isEditing,
            ),
            SizedBox(height: 20.h),

            // ─── Main fields ───
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount (single-item only; multi-item auto-calc)
                  if (!formState.isMultiItem)
                    _AmountSection(
                      initialValue: formState.totalAmount > 0
                          ? formState.totalAmount
                          : null,
                      type: formState.type,
                      onChanged: (val) => ref
                          .read(transactionFormControllerProvider.notifier)
                          .setTotalAmount(val),
                    ),

                  // Source wallet
                  SizedBox(height: 16.h),
                  _WalletPickerField(
                    label: formState.type == TransactionTypeEnum.transfer
                        ? l10n.transactionSourceWallet
                        : l10n.transactionWallet,
                    selected: formState.wallet,
                    onTap: () => _pickWallet(isSource: true),
                  ),

                  // Destination wallet (transfer only)
                  if (formState.type == TransactionTypeEnum.transfer) ...[
                    SizedBox(height: 12.h),
                    _WalletPickerField(
                      label: l10n.transactionDestWallet,
                      selected: formState.destinationWallet,
                      onTap: () => _pickWallet(isSource: false),
                      excludeWalletId: formState.wallet?.id,
                    ),
                  ],

                  // Category (income/expense single-item mode)
                  if (!formState.isMultiItem &&
                      (formState.type == TransactionTypeEnum.income ||
                          formState.type == TransactionTypeEnum.expense)) ...[
                    SizedBox(height: 12.h),
                    _CategoryPickerField(
                      type: formState.type,
                      item: formState.items.isNotEmpty
                          ? formState.items.first
                          : null,
                      onTap: _pickCategory,
                    ),
                  ],

                  // With person (debt/loan)
                  if (formState.type.requiresWithPerson) ...[
                    SizedBox(height: 12.h),
                    SakuTextField(
                      controller: _withPersonController,
                      label: l10n.transactionWithPerson,
                      hint: l10n.transactionWithPersonHint,
                      prefixIcon: FaIcon(FontAwesomeIcons.userTie, size: 16.w),
                      onChanged: (val) => ref
                          .read(transactionFormControllerProvider.notifier)
                          .setWithPerson(val),
                    ),
                  ],

                  // Date picker
                  SizedBox(height: 12.h),
                  _DatePickerField(
                    date: formState.date,
                    onChanged: (date) => ref
                        .read(transactionFormControllerProvider.notifier)
                        .setDate(date),
                  ),

                  // ─── Optional fields (collapsible) ───
                  SizedBox(height: 12.h),
                  _OptionalFieldsExpansion(
                    merchantController: _merchantController,
                    noteController: _noteController,
                    onMerchantChanged: (val) => ref
                        .read(transactionFormControllerProvider.notifier)
                        .setMerchant(val.isEmpty ? null : val),
                    onNoteChanged: (val) => ref
                        .read(transactionFormControllerProvider.notifier)
                        .setNote(val.isEmpty ? null : val),
                  ),

                  // ─── Multi-item section (expense only) ───
                  if (formState.type == TransactionTypeEnum.expense) ...[
                    SizedBox(height: 20.h),
                    _MultiItemSection(
                      formState: formState,
                      onAddItem: () => ref
                          .read(transactionFormControllerProvider.notifier)
                          .addItem(),
                      onUpdateItem: (index, item) => ref
                          .read(transactionFormControllerProvider.notifier)
                          .updateItem(index, item),
                      onRemoveItem: (index) => ref
                          .read(transactionFormControllerProvider.notifier)
                          .removeItem(index),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),

      // ─── Save button ───
      bottomNavigationBar: _SaveBar(formState: formState, onSave: _onSave),
    );
  }

  // ─── Actions ───

  Future<void> _pickWallet({required bool isSource}) async {
    final formState = ref.read(transactionFormControllerProvider);
    final ctrl = ref.read(transactionFormControllerProvider.notifier);

    final result = await WalletPickerSheet.show(
      context,
      selectedWalletId: isSource
          ? formState.wallet?.id
          : formState.destinationWallet?.id,
      excludeWalletId: isSource ? null : formState.wallet?.id,
    );

    if (result != null) {
      if (isSource) {
        ctrl.setWallet(result);
      } else {
        ctrl.setDestinationWallet(result);
      }
    }
  }

  Future<void> _pickCategory() async {
    final formState = ref.read(transactionFormControllerProvider);
    final ctrl = ref.read(transactionFormControllerProvider.notifier);

    final catType = formState.type == TransactionTypeEnum.income
        ? CategoryType.income
        : CategoryType.expense;

    final selectedId = formState.items.isNotEmpty
        ? formState.items.first.categoryId
        : null;

    final result = await CategoryPickerSheet.show(
      context: context,
      type: catType,
      selectedId: selectedId,
    );

    if (result != null) {
      ctrl.setCategory(result);
    }
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final formState = ref.read(transactionFormControllerProvider);

    // UI validation
    if (formState.wallet == null) {
      context.showAppAlert(
        context.l10n.transactionWalletRequired,
        alertType: AlertTypeEnum.error,
      );
      return;
    }

    if (formState.type == TransactionTypeEnum.transfer &&
        formState.destinationWallet == null) {
      context.showAppAlert(
        context.l10n.transactionDestWalletRequired,
        alertType: AlertTypeEnum.error,
      );
      return;
    }

    final result = await ref
        .read(transactionFormControllerProvider.notifier)
        .submit();

    if (!context.mounted) return;

    if (result.isSuccess()) {
      context.showAppAlert(
        context.l10n.transactionSaveSuccess,
        alertType: AlertTypeEnum.success,
      );
      context.pop();
    } else {
      final (message, _, _, _) = result.dataError()!;
      context.showAppAlert(message, alertType: AlertTypeEnum.error);
    }
  }

  Future<void> _confirmDelete() async {
    if (!context.mounted) return;

    final confirmed = await context.showConfirmDialog(
      title: context.l10n.transactionDeleteConfirm,
      message: context.l10n.transactionDeleteConfirm,
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    context.showLoadingOverlay();

    try {
      final result = await ref
          .read(transactionFormControllerProvider.notifier)
          .delete();

      if (!context.mounted) return;

      if (result.isSuccess()) {
        context.closeOverlay();
        context.showAppAlert(
          context.l10n.transactionDeleteSuccess,
          alertType: AlertTypeEnum.success,
        );
        context.pop();
      } else {
        context.closeOverlay();
        final (message, _, _, _) = result.dataError()!;
        context.showAppAlert(message, alertType: AlertTypeEnum.error);
      }
    } finally {
      if (context.mounted) {
        context.closeOverlay();
      }
    }
  }
}

// ═══════════════ Sub-widgets ═══════════════

/// Amount input section.
class _AmountSection extends StatelessWidget {
  const _AmountSection({
    required this.type,
    required this.onChanged,
    this.initialValue,
  });

  final TransactionTypeEnum type;
  final ValueChanged<double> onChanged;
  final double? initialValue;

  @override
  Widget build(BuildContext context) {
    return SakuCurrencyField(
      label: context.l10n.transactionAmount,
      initialValue: initialValue,
      onChanged: onChanged,
      autofocus: initialValue == null,
    );
  }
}

/// Wallet picker field — menampilkan wallet terpilih atau placeholder.
class _WalletPickerField extends StatelessWidget {
  const _WalletPickerField({
    required this.label,
    required this.onTap,
    this.selected,
    this.excludeWalletId,
  });

  final String label;
  final WalletModel? selected;
  final VoidCallback onTap;
  final String? excludeWalletId;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            FaIcon(
              FontAwesomeIcons.wallet,
              size: 16.w,
              color: selected != null ? colors.primary : colors.textSecondary,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyleConstants.label2.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    selected?.name ?? context.l10n.transactionSelectWallet,
                    style: TextStyleConstants.b2.copyWith(
                      color: selected != null
                          ? colors.textPrimary
                          : colors.textSecondary,
                    ),
                  ),
                ],
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
    );
  }
}

/// Category picker field — menampilkan kategori terpilih atau placeholder.
class _CategoryPickerField extends StatelessWidget {
  const _CategoryPickerField({
    required this.type,
    required this.onTap,
    this.item,
  });

  final TransactionTypeEnum type;
  final TransactionItemModel? item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            if (item?.categoryIcon != null)
              FaIcon(
                CategoryIconMapper.getIcon(item!.categoryIcon!),
                size: 16.w,
                color: item!.categoryColor != null
                    ? _parseColor(item!.categoryColor!)
                    : colors.textSecondary,
              )
            else
              FaIcon(
                FontAwesomeIcons.layerGroup,
                size: 16.w,
                color: colors.textSecondary,
              ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.transactionCategory,
                    style: TextStyleConstants.label2.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    item?.categoryName ??
                        context.l10n.transactionSelectCategory,
                    style: TextStyleConstants.b2.copyWith(
                      color: item?.categoryName != null
                          ? colors.textPrimary
                          : colors.textSecondary,
                    ),
                  ),
                ],
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
    );
  }

  Color _parseColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }
}

/// Date picker field.
class _DatePickerField extends StatelessWidget {
  const _DatePickerField({required this.date, required this.onChanged});

  final DateTime? date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final displayDate = date ?? DateTime.now();

    return GestureDetector(
      onTap: () => _pickDate(context, displayDate),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            FaIcon(
              FontAwesomeIcons.calendarDay,
              size: 16.w,
              color: colors.primary,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.transactionDate,
                    style: TextStyleConstants.label2.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    _formatDate(displayDate),
                    style: TextStyleConstants.b2.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ],
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
    );
  }

  Future<void> _pickDate(BuildContext context, DateTime current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      onChanged(picked);
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

/// Optional fields (merchant name, note) dalam expansion tile.
class _OptionalFieldsExpansion extends StatefulWidget {
  const _OptionalFieldsExpansion({
    required this.merchantController,
    required this.noteController,
    required this.onMerchantChanged,
    required this.onNoteChanged,
  });

  final TextEditingController merchantController;
  final TextEditingController noteController;
  final ValueChanged<String> onMerchantChanged;
  final ValueChanged<String> onNoteChanged;

  @override
  State<_OptionalFieldsExpansion> createState() =>
      _OptionalFieldsExpansionState();
}

class _OptionalFieldsExpansionState extends State<_OptionalFieldsExpansion> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              color: Colors.transparent,
              child: Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.ellipsis,
                    size: 16.w,
                    color: colors.textSecondary,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      context.l10n.transactionOptionalFields,
                      style: TextStyleConstants.b2.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  FaIcon(
                    _expanded
                        ? FontAwesomeIcons.chevronUp
                        : FontAwesomeIcons.chevronDown,
                    size: 12.w,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(height: 1, color: colors.border.withValues(alpha: 0.3)),
            Padding(
              padding: EdgeInsets.all(14.w),
              child: Column(
                children: [
                  SakuTextField(
                    controller: widget.merchantController,
                    label: context.l10n.transactionMerchant,
                    hint: context.l10n.transactionMerchantHint,
                    onChanged: (v) => widget.onMerchantChanged(v),
                  ),
                  SizedBox(height: 10.h),
                  SakuTextField(
                    controller: widget.noteController,
                    label: context.l10n.transactionNote,
                    maxLines: 2,
                    minLines: 2,
                    onChanged: (v) => widget.onNoteChanged(v),
                  ),
                  // Attachment placeholder
                  SizedBox(height: 10.h),
                  _AttachmentPlaceholder(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Placeholder untuk attachment field (P1 feature).
class _AttachmentPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: () {
        // TODO(P1): Implement attachment picker
        context.showAppAlert(
          'Fitur lampiran akan segera hadir',
          alertType: AlertTypeEnum.info,
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: colors.border.withValues(alpha: 0.5),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.paperclip,
              size: 14.w,
              color: colors.textSecondary,
            ),
            SizedBox(width: 8.w),
            Text(
              context.l10n.transactionAttachmentAdd,
              style: TextStyleConstants.b2.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section multi-item untuk expense.
class _MultiItemSection extends StatelessWidget {
  const _MultiItemSection({
    required this.formState,
    required this.onAddItem,
    required this.onUpdateItem,
    required this.onRemoveItem,
  });

  final TransactionFormState formState;
  final VoidCallback onAddItem;
  final void Function(int, TransactionItemModel) onUpdateItem;
  final void Function(int) onRemoveItem;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle multi-item hint
        if (!formState.isMultiItem) ...[
          GestureDetector(
            onTap: onAddItem,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 14.w),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    FontAwesomeIcons.plus,
                    size: 12.w,
                    color: colors.primary,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    context.l10n.transactionAddItem,
                    style: TextStyleConstants.b2.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          // Multi-item mode header
          Row(
            children: [
              Text(
                context.l10n.transactionMultiItemToggle,
                style: TextStyleConstants.label1.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Grand total indicator
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: formState.isTotalMatched
                      ? colors.income.withValues(alpha: 0.1)
                      : colors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '${formState.items.length} item',
                  style: TextStyleConstants.label2.copyWith(
                    color: formState.isTotalMatched
                        ? colors.income
                        : colors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Items list
          ...formState.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return TransactionItemRow(
              key: ValueKey('item_$index'),
              item: item,
              index: index,
              onChanged: (updated) => onUpdateItem(index, updated),
              onRemove: () => onRemoveItem(index),
              canRemove: formState.items.length > 1,
              categoryType: CategoryType.expense,
            );
          }),

          // Add more items
          SizedBox(height: 4.h),
          GestureDetector(
            onTap: onAddItem,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    FontAwesomeIcons.plus,
                    size: 12.w,
                    color: colors.primary,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    context.l10n.transactionAddItem,
                    style: TextStyleConstants.b2.copyWith(
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Bottom bar dengan tombol simpan dan indikator total.
class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.formState, required this.onSave});

  final TransactionFormState formState;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    // Multi-item: tombol disabled jika total tidak cocok
    final isDisabled =
        formState.isSaving ||
        (formState.isMultiItem && !formState.isTotalMatched);

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(
          top: BorderSide(color: colors.border.withValues(alpha: 0.3)),
        ),
      ),
      child: SakuButton(
        text: l10n.transactionSave,
        onPressed: isDisabled ? null : onSave,
        isLoading: formState.isSaving,
      ),
    );
  }
}
