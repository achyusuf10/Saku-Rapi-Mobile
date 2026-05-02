import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/debt_loan_kind_enum.dart';
import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/features/ocr/controllers/pending_ocr_prefill_provider.dart';
import 'package:app_saku_rapi/features/transaction/controllers/transaction_form_controller.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/contact_picker_sheet.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/contact_picker_tile.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/debt_loan_kind_selector.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/debt_loan_transaction_picker_tile.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_amount_section.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_category_picker_tile.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_date_picker_tile.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_form_save_bar.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_manual_multi_entry_list.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_multi_item_section.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_multi_manual_mode_header.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_optional_details_section.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_transfer_arrow.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_type_tabs.dart';
import 'package:app_saku_rapi/features/voice/controllers/pending_voice_prefill_provider.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:app_saku_rapi/global/widgets/saku_text_field.dart';
import 'package:app_saku_rapi/global/widgets/saku_wallet_picker_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import 'transaction_form_actions_mixin.dart';
import 'transaction_form_prefill_mixin.dart';

// ═══════════════════════════════════════════════
//  TransactionFormPage
// ═══════════════════════════════════════════════

/// Halaman form tambah/edit transaksi manual.
///
/// Mendukung 5 tipe: expense, income, transfer, debt, loan.
/// Form field berubah secara dinamis berdasarkan tipe yang dipilih.
/// Submit menggunakan RPC atomik dengan proteksi anti double-submit.
///
/// Logika prefill (voice/OCR/widget) → [TransactionFormPrefillMixin].
/// Aksi pengguna (simpan/hapus/picker) → [TransactionFormActionsMixin].
///
/// Cara pakai:
/// ```dart
/// context.push(AppRouter.transactionForm);
/// // Mode edit — kirim data transaksi via extra:
/// context.push(AppRouter.transactionForm, extra: existingTransaction);
/// ```
class TransactionFormPage extends ConsumerStatefulWidget {
  const TransactionFormPage({super.key, this.existingTransaction});

  /// Transaksi yang akan di-edit. Null berarti mode create baru.
  final TransactionModel? existingTransaction;

  @override
  ConsumerState<TransactionFormPage> createState() =>
      _TransactionFormPageState();
}

// ═══════════════════════════════════════════════
//  _TransactionFormPageState
// ═══════════════════════════════════════════════

class _TransactionFormPageState extends ConsumerState<TransactionFormPage>
    with TransactionFormPrefillMixin, TransactionFormActionsMixin {
  final _formKey = GlobalKey<FormState>();
  final _merchantController = TextEditingController();
  final _noteController = TextEditingController();

  // Auto-focus kolom amount hanya untuk transaksi baru yang kosong.
  // Mode edit, voice, OCR, dan image OCR semuanya melewati autofocus.
  late final bool _autoFocusAmount;

  // ─── Abstract getter implementations ───

  /// Diperlukan oleh [TransactionFormActionsMixin].
  @override
  GlobalKey<FormState> get formKey => _formKey;

  /// Diperlukan oleh [TransactionFormPrefillMixin].
  @override
  TextEditingController get merchantController => _merchantController;

  /// Diperlukan oleh [TransactionFormPrefillMixin].
  @override
  TextEditingController get noteController => _noteController;

  @override
  void initState() {
    super.initState();

    // Tentukan apakah ini transaksi baru tanpa prefill sama sekali
    final isNewBlank =
        widget.existingTransaction == null &&
        ref.read(pendingVoicePrefillProvider) == null &&
        ref.read(pendingOcrPrefillProvider) == null &&
        ref.read(pendingOcrImageFileProvider) == null;
    _autoFocusAmount = isNewBlank;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = ref.read(transactionFormControllerProvider.notifier);

      if (widget.existingTransaction != null) {
        // ── Mode edit: load data existing lalu resolve wallet/category ──
        final txn = widget.existingTransaction!;
        ctrl.loadExistingTransaction(txn);
        _merchantController.text = txn.merchantName ?? '';
        _noteController.text = txn.note ?? '';
        resolveEditLookups(ctrl, txn);
      } else {
        // ── Mode create: init satu item default, lalu terapkan prefill ──
        ctrl.initSingleItem();
        applyVoicePrefill(ctrl);
        applyOcrPrefill(ctrl);
        applyOcrImagePrefill(ctrl);
        applyWidgetWalletPrefill(ctrl);
      }

      // Pastikan daftar wallet sudah ter-load untuk picker
      ref.read(walletControllerProvider.notifier).loadWallets();
    });
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final formState = ref.watch(transactionFormControllerProvider);
    final isEditing = formState.isEditing;
    final isSaving = formState.isSaving;

    ref.listen<TransactionFormState>(transactionFormControllerProvider, (
      prev,
      next,
    ) {
      if (prev == null) return;
      if (prev.isMultiManualMode && !next.isMultiManualMode) {
        _merchantController.text = next.merchantName ?? '';
        _noteController.text = next.note ?? '';
      }
    });

    // Warna aksen mengikuti tipe transaksi aktif
    final typeColor = colorForType(formState.type, colors);

    final showMultiManualChrome =
        !isEditing &&
        !formState.isSettlementMode &&
        (formState.type == TransactionTypeEnum.expense ||
            formState.type == TransactionTypeEnum.income);
    final hideSingleMainFields =
        showMultiManualChrome && formState.isMultiManualMode;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        var res = await context.showConfirmDialog(
          title: l10n.exitWithoutSavingTitle,
          message: l10n.exitWithoutSavingMessage,
        );
        if (context.mounted) {
          if (res == true) {
            context.pop();
          }
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: colors.background,
          body: Form(
            key: _formKey,
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                // ─── AppBar ───
                SliverAppBar(
                  pinned: true,
                  backgroundColor: colors.surface,
                  foregroundColor: colors.textPrimary,
                  elevation: 0,
                  scrolledUnderElevation: 0.5,
                  leading: IconButton(
                    icon: FaIcon(FontAwesomeIcons.arrowLeft, size: 18.w),
                    onPressed: () async {
                      var res = await context.showConfirmDialog(
                        title: l10n.exitWithoutSavingTitle,
                        message: l10n.exitWithoutSavingMessage,
                      );
                      if (context.mounted) {
                        if (res == true) {
                          context.pop();
                        }
                      }
                    },
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
                          // Tombol hapus hanya muncul di mode edit
                          IconButton(
                            icon: FaIcon(
                              FontAwesomeIcons.trashCan,
                              size: 16.w,
                              color: colors.expense,
                            ),
                            onPressed: isSaving ? null : onConfirmDelete,
                          ),
                        ]
                      : null,
                ),

                // ─── Tab tipe transaksi (hanya pada mode create) ───
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

                // ─── Body form ───
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 120.h),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ─── Selector sub-tipe Hutang/Piutang ───
                      if (formState.isDebtLoanTab && !isEditing) ...[
                        DebtLoanKindSelector(
                          selected:
                              formState.debtLoanKind ?? DebtLoanKindEnum.debt,
                          onChanged: (kind) => ref
                              .read(transactionFormControllerProvider.notifier)
                              .setDebtLoanKind(kind),
                        ),
                        SizedBox(height: 16.h),
                      ],

                      // ─── Picker transaksi referensi (mode settlement) ───
                      if (formState.isSettlementMode && !isEditing) ...[
                        DebtLoanTransactionPickerTile(
                          selected: formState.referenceTransaction,
                          iconColor: typeColor,
                          onTap: () => pickReferenceTransaction(formState),
                        ),
                        SizedBox(height: 10.h),
                      ],

                      if (showMultiManualChrome) ...[
                        const TransactionMultiManualModeHeader(),
                        SizedBox(height: 12.h),
                      ],

                      if (showMultiManualChrome &&
                          formState.isMultiManualMode) ...[
                        TransactionManualMultiEntryList(
                          typeColor: typeColor,
                          type: formState.type,
                          onPickWalletFor: (i) => pickWallet(
                            isSource: true,
                            manualMultiEntryIndex: i,
                          ),
                          onPickCategoryFor: (i) =>
                              pickCategory(manualMultiEntryIndex: i),
                          onPickAttachmentFor: pickAttachmentForMultiEntry,
                        ),
                      ],

                      // ─── Field jumlah (single-item mode) ───
                      if (!hideSingleMainFields && !formState.isMultiItem) ...[
                        TransactionAmountSection(
                          autoFocus: _autoFocusAmount,
                          typeColor: typeColor,
                          initialValue: formState.totalAmount > 0
                              ? formState.totalAmount
                              : null,
                          onChanged: (val) => ref
                              .read(transactionFormControllerProvider.notifier)
                              .setTotalAmount(val),
                        ),
                        // Hint sisa hutang/piutang saat mode settlement
                        if (formState.isSettlementMode &&
                            formState.referenceTransaction != null)
                          Padding(
                            padding: EdgeInsets.only(top: 4.h, left: 4.w),
                            child: Text(
                              l10n.debtLoanFormRemainingAmount(
                                formState.referenceTransaction!.remaining
                                    .toCurrency(),
                              ),
                              style: TextStyleConstants.caption.copyWith(
                                color: typeColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        SizedBox(height: 16.h),
                      ],

                      // ─── Picker dompet sumber / transfer ───
                      if (!hideSingleMainFields) ...[
                        SakuWalletPickerTile(
                          label: formState.type == TransactionTypeEnum.transfer
                              ? l10n.transactionSourceWallet
                              : l10n.transactionWallet,
                          selected: formState.wallet,
                          onTap: () => pickWallet(isSource: true),
                          iconColor: colors.primary,
                          backgroundColor: colors.surface,
                          useBorder: true,
                        ),
                        if (formState.type == TransactionTypeEnum.transfer) ...[
                          TransactionTransferArrow(
                            color: colors.transfer,
                            onSwap: () => ref
                                .read(
                                  transactionFormControllerProvider.notifier,
                                )
                                .swapWallets(),
                          ),
                          SakuWalletPickerTile(
                            label: l10n.transactionDestWallet,
                            selected: formState.destinationWallet,
                            onTap: () => pickWallet(isSource: false),
                            iconColor: colors.transfer,
                            backgroundColor: colors.surface,
                            useBorder: true,
                          ),
                        ],
                        SizedBox(height: 10.h),
                      ],

                      // ─── Picker kategori (expense/income, non-settlement) ───
                      if (!hideSingleMainFields &&
                          !formState.isSettlementMode &&
                          (formState.type == TransactionTypeEnum.income ||
                              formState.type ==
                                  TransactionTypeEnum.expense)) ...[
                        TransactionCategoryPickerTile(
                          type: formState.type,
                          category: formState.category,
                          item: formState.items.isNotEmpty
                              ? formState.items.first
                              : null,
                          onTap: pickCategory,
                          iconColor: typeColor,
                        ),
                        SizedBox(height: 10.h),
                      ],

                      // ─── Picker kontak (hutang/piutang, non-settlement) ───
                      if (formState.type.requiresWithPerson &&
                          !formState.isSettlementMode) ...[
                        ContactPickerTile(
                          selected: formState.contact,
                          iconColor: typeColor,
                          onTap: () async {
                            final contact = await ContactPickerSheet.show(
                              context,
                            );
                            if (contact != null && mounted) {
                              ref
                                  .read(
                                    transactionFormControllerProvider.notifier,
                                  )
                                  .setContact(contact);
                            }
                          },
                          onClear: () {
                            FocusScope.of(context).unfocus();
                            ref
                                .read(
                                  transactionFormControllerProvider.notifier,
                                )
                                .setContact(null);
                          },
                        ),
                        SizedBox(height: 10.h),
                      ],

                      // ─── Picker tanggal ───
                      if (!hideSingleMainFields)
                        TransactionDatePickerTile(
                          date: formState.date,
                          onChanged: (date) {
                            FocusScope.of(context).unfocus();
                            ref
                                .read(
                                  transactionFormControllerProvider.notifier,
                                )
                                .setDate(date);
                          },
                        ),

                      if (!hideSingleMainFields) SizedBox(height: 14.h),

                      // ─── Detail opsional: merchant, note, lampiran (non-settlement) ───
                      if (!hideSingleMainFields && !formState.isSettlementMode)
                        TransactionOptionalDetailsSection(
                          merchantController: _merchantController,
                          noteController: _noteController,
                          attachmentUrl: formState.attachmentUrl,
                          localAttachmentPath: formState.localAttachmentPath,
                          onMerchantChanged: (val) => ref
                              .read(transactionFormControllerProvider.notifier)
                              .setMerchant(val.isEmpty ? null : val),
                          onNoteChanged: (val) => ref
                              .read(transactionFormControllerProvider.notifier)
                              .setNote(val.isEmpty ? null : val),
                          onPickAttachment: pickAttachment,
                          onRemoveAttachment: () => ref
                              .read(transactionFormControllerProvider.notifier)
                              .setLocalAttachment(null),
                        ),

                      // ─── Field catatan ringkas (mode settlement) ───
                      if (formState.isSettlementMode) ...[
                        SizedBox(height: 6.h),
                        SakuTextField(
                          controller: _noteController,
                          hint: l10n.debtLoanSettlementNote,
                          onChanged: (val) => ref
                              .read(transactionFormControllerProvider.notifier)
                              .setNote(val.isEmpty ? null : val),
                        ),
                      ],

                      // ─── Section multi-item (expense/income, non-settlement) ───
                      if (!hideSingleMainFields &&
                          !formState.isSettlementMode &&
                          (formState.type == TransactionTypeEnum.expense ||
                              formState.type ==
                                  TransactionTypeEnum.income)) ...[
                        SizedBox(height: 16.h),
                        const TransactionMultiItemSection(),
                      ],
                    ]),
                  ),
                ),
              ],
            ),
          ),

          // ─── Tombol simpan (sticky di bawah) ───
          bottomNavigationBar: TransactionFormSaveBar(
            formState: formState,
            onSave: onSave,
            typeColor: typeColor,
          ),
        ),
      ),
    );
  }
}
