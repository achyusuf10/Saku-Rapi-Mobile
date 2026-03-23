import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/themes/app_colors.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/category/utils/category_icon_mapper.dart';
import 'package:app_saku_rapi/features/category/view/widgets/category_picker_sheet.dart';
import 'package:app_saku_rapi/features/transaction/controllers/transaction_form_controller.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_item_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_item_row.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:app_saku_rapi/features/wallet/view/widgets/wallet_picker_sheet.dart';
import 'package:app_saku_rapi/global/services/image_upload_service.dart';
import 'package:app_saku_rapi/global/widgets/image_source_picker_sheet.dart';
import 'package:app_saku_rapi/global/widgets/saku_button.dart';
import 'package:app_saku_rapi/global/widgets/saku_currency_field.dart';
import 'package:app_saku_rapi/global/widgets/saku_text_field.dart';
import 'package:app_saku_rapi/utils/function/compress_image_func.dart';
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
    final typeColor = _colorForType(formState.type, colors);

    return Scaffold(
      backgroundColor: colors.background,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            // ─── Compact AppBar ───
            SliverAppBar(
              expandedHeight: 100.h,
              pinned: true,
              backgroundColor: typeColor,
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: FaIcon(FontAwesomeIcons.arrowLeft, size: 18.w),
                onPressed: () => context.pop(),
              ),
              actions: isEditing
                  ? [
                      IconButton(
                        icon: FaIcon(
                          FontAwesomeIcons.trashCan,
                          size: 18.w,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        onPressed: isSaving ? null : _confirmDelete,
                      ),
                    ]
                  : null,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [typeColor, typeColor.withValues(alpha: 0.85)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 40.h, 16.w, 12.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            isEditing
                                ? l10n.transactionEditTitle
                                : l10n.transactionNewTitle,
                            style: TextStyleConstants.h6.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ─── Type selector chips ───
            if (!isEditing)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 16.h, bottom: 4.h),
                  child: _TransactionTypeChips(
                    selected: formState.type,
                    onChanged: (t) => ref
                        .read(transactionFormControllerProvider.notifier)
                        .setType(t),
                  ),
                ),
              ),

            // ─── Form content ───
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 120.h),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ─── Amount ───
                  if (!formState.isMultiItem) ...[
                    _AmountField(
                      typeColor: typeColor,
                      initialValue: formState.totalAmount > 0
                          ? formState.totalAmount
                          : null,
                      onChanged: (val) => ref
                          .read(transactionFormControllerProvider.notifier)
                          .setTotalAmount(val),
                    ),
                    SizedBox(height: 14.h),
                  ],

                  // ─── Wallet ───
                  _WalletPickerTile(
                    label: formState.type == TransactionTypeEnum.transfer
                        ? l10n.transactionSourceWallet
                        : l10n.transactionWallet,
                    selected: formState.wallet,
                    onTap: () => _pickWallet(isSource: true),
                  ),

                  // Destination wallet (transfer only)
                  if (formState.type == TransactionTypeEnum.transfer) ...[
                    _TransferArrowIndicator(color: colors.transfer),
                    _WalletPickerTile(
                      label: l10n.transactionDestWallet,
                      selected: formState.destinationWallet,
                      onTap: () => _pickWallet(isSource: false),
                      excludeWalletId: formState.wallet?.id,
                    ),
                  ],

                  SizedBox(height: 10.h),

                  // ─── Category (income/expense single-item mode) ───
                  if (!formState.isMultiItem &&
                      (formState.type == TransactionTypeEnum.income ||
                          formState.type == TransactionTypeEnum.expense)) ...[
                    _CategoryPickerTile(
                      type: formState.type,
                      item: formState.items.isNotEmpty
                          ? formState.items.first
                          : null,
                      onTap: _pickCategory,
                    ),
                    SizedBox(height: 10.h),
                  ],

                  // ─── With person (debt/loan) ───
                  if (formState.type.requiresWithPerson) ...[
                    SakuTextField(
                      controller: _withPersonController,
                      label: l10n.transactionWithPerson,
                      hint: l10n.transactionWithPersonHint,
                      onChanged: (val) => ref
                          .read(transactionFormControllerProvider.notifier)
                          .setWithPerson(val),
                    ),
                    SizedBox(height: 10.h),
                  ],

                  // ─── Date ───
                  _DatePickerTile(
                    date: formState.date,
                    onChanged: (date) => ref
                        .read(transactionFormControllerProvider.notifier)
                        .setDate(date),
                  ),

                  SizedBox(height: 14.h),

                  // ─── Optional details (merchant, note, attachment) ───
                  _OptionalDetailsSection(
                    merchantController: _merchantController,
                    noteController: _noteController,
                    attachmentUrl: formState.attachmentUrl,
                    onMerchantChanged: (val) => ref
                        .read(transactionFormControllerProvider.notifier)
                        .setMerchant(val.isEmpty ? null : val),
                    onNoteChanged: (val) => ref
                        .read(transactionFormControllerProvider.notifier)
                        .setNote(val.isEmpty ? null : val),
                    onPickAttachment: _pickAndUploadAttachment,
                    onRemoveAttachment: () => ref
                        .read(transactionFormControllerProvider.notifier)
                        .setAttachmentUrl(null),
                  ),

                  // ─── Multi-item section (expense only) ───
                  if (formState.type == TransactionTypeEnum.expense) ...[
                    SizedBox(height: 16.h),
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
                ]),
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
    final l10n = context.l10n;

    // UI validation
    if (formState.wallet == null) {
      if (!mounted) return;
      context.showAppAlert(
        l10n.transactionWalletRequired,
        alertType: AlertTypeEnum.error,
      );
      return;
    }

    if (formState.type == TransactionTypeEnum.transfer &&
        formState.destinationWallet == null) {
      if (!mounted) return;
      context.showAppAlert(
        l10n.transactionDestWalletRequired,
        alertType: AlertTypeEnum.error,
      );
      return;
    }

    final result = await ref
        .read(transactionFormControllerProvider.notifier)
        .submit();

    if (!mounted) return;

    if (result.isSuccess()) {
      context.showAppAlert(
        l10n.transactionSaveSuccess,
        alertType: AlertTypeEnum.success,
      );
      context.pop();
    } else {
      final (message, _, _, _) = result.dataError()!;
      context.showAppAlert(message, alertType: AlertTypeEnum.error);
    }
  }

  Future<void> _confirmDelete() async {
    if (!mounted) return;

    final l10n = context.l10n;

    final confirmed = await context.showConfirmDialog(
      title: l10n.transactionDeleteConfirm,
      message: l10n.transactionDeleteConfirm,
    );

    if (confirmed != true) return;
    if (!mounted) return;

    context.showLoadingOverlay();

    try {
      final result = await ref
          .read(transactionFormControllerProvider.notifier)
          .delete();

      if (!mounted) return;

      if (result.isSuccess()) {
        context.closeOverlay();
        context.showAppAlert(
          l10n.transactionDeleteSuccess,
          alertType: AlertTypeEnum.success,
        );
        context.pop();
      } else {
        context.closeOverlay();
        final (message, _, _, _) = result.dataError()!;
        context.showAppAlert(message, alertType: AlertTypeEnum.error);
      }
    } finally {
      if (mounted) {
        context.closeOverlay();
      }
    }
  }

  /// Pick image → compress → upload → set attachment URL.
  Future<void> _pickAndUploadAttachment() async {
    final file = await ImageSourcePickerSheet.show(context);
    if (file == null || !mounted) return;

    context.showLoadingOverlay();

    try {
      // Compress image
      final compressed = await CompressImageFunc.call(filePath: file.path);
      if (compressed == null || !mounted) {
        if (mounted) context.closeOverlay();
        return;
      }

      // Upload
      final service = ImageUploadService();
      final result = await service.uploadImage(
        imageBytes: compressed,
        fileName: 'attachment.jpg',
      );

      if (!mounted) return;
      context.closeOverlay();

      if (result.isSuccess()) {
        final url = result.dataSuccess()!;
        ref
            .read(transactionFormControllerProvider.notifier)
            .setAttachmentUrl(url);
      } else {
        final (message, _, _, _) = result.dataError()!;
        context.showAppAlert(message, alertType: AlertTypeEnum.error);
      }
    } catch (_) {
      if (mounted) context.closeOverlay();
    }
  }

  Color _colorForType(TransactionTypeEnum type, AppColorScheme colors) {
    return switch (type) {
      TransactionTypeEnum.expense => colors.expense,
      TransactionTypeEnum.income => colors.income,
      TransactionTypeEnum.transfer => colors.transfer,
      TransactionTypeEnum.debt => colors.debt,
      TransactionTypeEnum.loan => colors.loan,
      _ => colors.primary,
    };
  }
}

// ═══════════════ Sub-widgets ═══════════════

/// Transaction type selector with icon chips, built inline here
/// to replace the old TransactionTypeSelector.
class _TransactionTypeChips extends StatelessWidget {
  const _TransactionTypeChips({
    required this.selected,
    required this.onChanged,
  });

  final TransactionTypeEnum selected;
  final ValueChanged<TransactionTypeEnum> onChanged;

  static const _types = [
    TransactionTypeEnum.expense,
    TransactionTypeEnum.income,
    TransactionTypeEnum.transfer,
    TransactionTypeEnum.debt,
    TransactionTypeEnum.loan,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      height: 42.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: _types.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final type = _types[index];
          final isSelected = type == selected;
          final typeColor = _colorForType(type, colors);

          return GestureDetector(
            onTap: () => onChanged(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              decoration: BoxDecoration(
                color: isSelected
                    ? typeColor.withValues(alpha: 0.12)
                    : colors.surface,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isSelected
                      ? typeColor
                      : colors.border.withValues(alpha: 0.4),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(
                    _iconForType(type),
                    size: 12.w,
                    color: isSelected ? typeColor : colors.textSecondary,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    _labelForType(type, context),
                    style: TextStyleConstants.label1.copyWith(
                      color: isSelected ? typeColor : colors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _iconForType(TransactionTypeEnum type) {
    return switch (type) {
      TransactionTypeEnum.expense => FontAwesomeIcons.arrowTrendDown,
      TransactionTypeEnum.income => FontAwesomeIcons.arrowTrendUp,
      TransactionTypeEnum.transfer => FontAwesomeIcons.arrowRightArrowLeft,
      TransactionTypeEnum.debt => FontAwesomeIcons.handHoldingDollar,
      TransactionTypeEnum.loan => FontAwesomeIcons.moneyBillTransfer,
      _ => FontAwesomeIcons.coins,
    };
  }

  String _labelForType(TransactionTypeEnum type, BuildContext context) {
    final l10n = context.l10n;
    return switch (type) {
      TransactionTypeEnum.expense => l10n.transactionExpense,
      TransactionTypeEnum.income => l10n.transactionIncome,
      TransactionTypeEnum.transfer => l10n.transactionTransfer,
      TransactionTypeEnum.debt => l10n.transactionDebt,
      TransactionTypeEnum.loan => l10n.transactionLoan,
      TransactionTypeEnum.adjustment => l10n.transactionAdjustment,
      TransactionTypeEnum.transferToAsset => l10n.transactionTransfer,
    };
  }

  Color _colorForType(TransactionTypeEnum type, AppColorScheme colors) {
    return switch (type) {
      TransactionTypeEnum.expense => colors.expense,
      TransactionTypeEnum.income => colors.income,
      TransactionTypeEnum.transfer => colors.transfer,
      TransactionTypeEnum.debt => colors.debt,
      TransactionTypeEnum.loan => colors.loan,
      _ => colors.primary,
    };
  }
}

/// Simple amount field with label.
class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.typeColor,
    required this.onChanged,
    this.initialValue,
  });

  final Color typeColor;
  final ValueChanged<double> onChanged;
  final double? initialValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.transactionAmount,
          style: TextStyleConstants.label1.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colors.textPrimary,
          ),
        ),
        SizedBox(height: 6.h),
        SakuCurrencyField(
          initialValue: initialValue,
          onChanged: onChanged,
          autofocus: initialValue == null,
        ),
      ],
    );
  }
}

/// Wallet picker tile.
class _WalletPickerTile extends StatelessWidget {
  const _WalletPickerTile({
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
    final hasSelection = selected != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: hasSelection
                ? colors.primary.withValues(alpha: 0.3)
                : colors.border.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            FaIcon(
              FontAwesomeIcons.wallet,
              size: 16.w,
              color: hasSelection ? colors.primary : colors.textSecondary,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyleConstants.overline.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    selected?.name ?? context.l10n.transactionSelectWallet,
                    style: TextStyleConstants.b2.copyWith(
                      color: hasSelection
                          ? colors.textPrimary
                          : colors.textSecondary,
                      fontWeight: hasSelection
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (hasSelection)
              Text(
                selected!.balance.toCurrency(),
                style: TextStyleConstants.label2.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
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

/// Transfer arrow between source and destination wallet.
class _TransferArrowIndicator extends StatelessWidget {
  const _TransferArrowIndicator({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Center(
        child: FaIcon(
          FontAwesomeIcons.arrowDown,
          size: 14.w,
          color: color.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

/// Category picker tile.
class _CategoryPickerTile extends StatelessWidget {
  const _CategoryPickerTile({
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
    final hasCategory = item?.categoryName != null;
    final categoryColor = item?.categoryColor != null
        ? _parseColor(item!.categoryColor!)
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: hasCategory
                ? (categoryColor ?? colors.primary).withValues(alpha: 0.3)
                : colors.border.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            FaIcon(
              hasCategory
                  ? CategoryIconMapper.getIcon(item!.categoryIcon!)
                  : FontAwesomeIcons.layerGroup,
              size: 16.w,
              color: hasCategory
                  ? (categoryColor ?? colors.primary)
                  : colors.textSecondary,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.transactionCategory,
                    style: TextStyleConstants.overline.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    item?.categoryName ??
                        context.l10n.transactionSelectCategory,
                    style: TextStyleConstants.b2.copyWith(
                      color: hasCategory
                          ? colors.textPrimary
                          : colors.textSecondary,
                      fontWeight: hasCategory
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

/// Date picker tile.
class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({required this.date, required this.onChanged});

  final DateTime? date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final displayDate = date ?? DateTime.now();

    return GestureDetector(
      onTap: () => _pickDate(context, displayDate),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
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
              color: colors.info,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.transactionDate,
                    style: TextStyleConstants.overline.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    _formatDate(displayDate),
                    style: TextStyleConstants.b2.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: colors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                _isToday(displayDate) ? 'Hari ini' : _dayName(displayDate),
                style: TextStyleConstants.label2.copyWith(
                  color: colors.info,
                  fontWeight: FontWeight.w600,
                ),
              ),
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

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _dayName(DateTime date) {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return days[date.weekday - 1];
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

/// Optional details (merchant, note, attachment) with expand/collapse.
class _OptionalDetailsSection extends StatefulWidget {
  const _OptionalDetailsSection({
    required this.merchantController,
    required this.noteController,
    required this.onMerchantChanged,
    required this.onNoteChanged,
    required this.onPickAttachment,
    required this.onRemoveAttachment,
    this.attachmentUrl,
  });

  final TextEditingController merchantController;
  final TextEditingController noteController;
  final ValueChanged<String> onMerchantChanged;
  final ValueChanged<String> onNoteChanged;
  final VoidCallback onPickAttachment;
  final VoidCallback onRemoveAttachment;
  final String? attachmentUrl;

  @override
  State<_OptionalDetailsSection> createState() =>
      _OptionalDetailsSectionState();
}

class _OptionalDetailsSectionState extends State<_OptionalDetailsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              color: Colors.transparent,
              child: Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.ellipsis,
                    size: 14.w,
                    color: colors.textSecondary,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      context.l10n.transactionOptionalFields,
                      style: TextStyleConstants.b2.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: FaIcon(
                      FontAwesomeIcons.chevronDown,
                      size: 12.w,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
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
                        hint: '...',
                        maxLines: 2,
                        minLines: 2,
                        onChanged: (v) => widget.onNoteChanged(v),
                      ),
                      SizedBox(height: 10.h),
                      // Attachment
                      _AttachmentField(
                        attachmentUrl: widget.attachmentUrl,
                        onPick: widget.onPickAttachment,
                        onRemove: widget.onRemoveAttachment,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }
}

/// Attachment field: shows pick button or image preview.
class _AttachmentField extends StatelessWidget {
  const _AttachmentField({
    required this.onPick,
    required this.onRemove,
    this.attachmentUrl,
  });

  final String? attachmentUrl;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (attachmentUrl != null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: Image.network(
                attachmentUrl!,
                height: 120.h,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 120.h,
                  color: colors.background,
                  child: Center(
                    child: FaIcon(
                      FontAwesomeIcons.image,
                      size: 24.w,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 6.h,
              right: 6.w,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: colors.expense.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: FaIcon(
                    FontAwesomeIcons.xmark,
                    size: 10.w,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Pick button
    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.paperclip,
              size: 13.w,
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

/// Multi-item section for expense.
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

    if (!formState.isMultiItem) {
      return GestureDetector(
        onTap: onAddItem,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 14.w),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
          ),
          child: Center(
            child: Text(
              context.l10n.transactionAddItem,
              style: TextStyleConstants.b2.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    // Multi-item mode
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Text(
              context.l10n.transactionMultiItemToggle,
              style: TextStyleConstants.label1.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: formState.isTotalMatched
                    ? colors.income.withValues(alpha: 0.1)
                    : colors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6.r),
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
        SizedBox(height: 8.h),

        // Grand total
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: formState.isTotalMatched
                ? colors.income.withValues(alpha: 0.06)
                : colors.error.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Row(
            children: [
              Text(
                context.l10n.transactionGrandTotal,
                style: TextStyleConstants.label1.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                formState.itemsTotal.toCurrency(),
                style: TextStyleConstants.b1.copyWith(
                  fontWeight: FontWeight.bold,
                  color: formState.isTotalMatched
                      ? colors.income
                      : colors.error,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),

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
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
            ),
            child: Center(
              child: Text(
                context.l10n.transactionAddItem,
                style: TextStyleConstants.b2.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bottom save bar.
class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.formState, required this.onSave});

  final TransactionFormState formState;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    final isDisabled =
        formState.isSaving ||
        (formState.isMultiItem && !formState.isTotalMatched);

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SakuButton(
          text: l10n.transactionSave,
          onPressed: isDisabled ? null : onSave,
          isLoading: formState.isSaving,
        ),
      ),
    );
  }
}
