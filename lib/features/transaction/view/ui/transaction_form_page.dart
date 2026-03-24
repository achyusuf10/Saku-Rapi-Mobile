import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/themes/app_colors.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/category/view/widgets/category_picker_sheet.dart';
import 'package:app_saku_rapi/features/transaction/controllers/transaction_form_controller.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_amount_section.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_category_picker_tile.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_date_picker_tile.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_form_save_bar.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_multi_item_section.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_optional_details_section.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_transfer_arrow.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_type_tabs.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_wallet_picker_tile.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:app_saku_rapi/features/wallet/view/widgets/wallet_picker_sheet.dart';
import 'package:app_saku_rapi/global/services/image_upload_service.dart';
import 'package:app_saku_rapi/global/widgets/image_source_picker_sheet.dart';
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
            // ─── Simple AppBar ───
            SliverAppBar(
              pinned: true,
              backgroundColor: colors.surface,
              foregroundColor: colors.textPrimary,
              elevation: 0,
              scrolledUnderElevation: 0.5,
              leading: IconButton(
                icon: FaIcon(FontAwesomeIcons.arrowLeft, size: 18.w),
                onPressed: () => context.pop(),
              ),
              title: Text(
                isEditing
                    ? l10n.transactionEditTitle
                    : l10n.transactionNewTitle,
                style: TextStyleConstants.h7.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              centerTitle: false,
              actions: isEditing
                  ? [
                      IconButton(
                        icon: FaIcon(
                          FontAwesomeIcons.trashCan,
                          size: 16.w,
                          color: colors.expense,
                        ),
                        onPressed: isSaving ? null : _confirmDelete,
                      ),
                    ]
                  : null,
            ),

            // ─── Type selector tabs ───
            if (!isEditing)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 8.h, bottom: 8.h),
                  child: TransactionTypeTabs(
                    selected: formState.type,
                    onChanged: (t) => ref
                        .read(transactionFormControllerProvider.notifier)
                        .setType(t),
                  ),
                ),
              ),

            // ─── Form content ───
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 120.h),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ─── Amount ───
                  if (!formState.isMultiItem) ...[
                    TransactionAmountSection(
                      typeColor: typeColor,
                      initialValue: formState.totalAmount > 0
                          ? formState.totalAmount
                          : null,
                      onChanged: (val) => ref
                          .read(transactionFormControllerProvider.notifier)
                          .setTotalAmount(val),
                    ),
                    SizedBox(height: 16.h),
                  ],

                  // ─── Wallet ───
                  TransactionWalletPickerTile(
                    label: formState.type == TransactionTypeEnum.transfer
                        ? l10n.transactionSourceWallet
                        : l10n.transactionWallet,
                    selected: formState.wallet,
                    onTap: () => _pickWallet(isSource: true),
                    iconColor: colors.primary,
                  ),

                  // Destination wallet (transfer only)
                  if (formState.type == TransactionTypeEnum.transfer) ...[
                    TransactionTransferArrow(color: colors.transfer),
                    TransactionWalletPickerTile(
                      label: l10n.transactionDestWallet,
                      selected: formState.destinationWallet,
                      onTap: () => _pickWallet(isSource: false),
                      excludeWalletId: formState.wallet?.id,
                      iconColor: colors.transfer,
                    ),
                  ],

                  SizedBox(height: 10.h),

                  // ─── Category (income/expense single-item mode) ───
                  if (!formState.isMultiItem &&
                      (formState.type == TransactionTypeEnum.income ||
                          formState.type == TransactionTypeEnum.expense)) ...[
                    TransactionCategoryPickerTile(
                      type: formState.type,
                      item: formState.items.isNotEmpty
                          ? formState.items.first
                          : null,
                      onTap: _pickCategory,
                      iconColor: typeColor,
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
                  TransactionDatePickerTile(
                    date: formState.date,
                    onChanged: (date) => ref
                        .read(transactionFormControllerProvider.notifier)
                        .setDate(date),
                  ),

                  SizedBox(height: 14.h),

                  // ─── Optional details (merchant, note, attachment) ───
                  TransactionOptionalDetailsSection(
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
                    TransactionMultiItemSection(
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
      bottomNavigationBar: TransactionFormSaveBar(
        formState: formState,
        onSave: _onSave,
        typeColor: typeColor,
      ),
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
