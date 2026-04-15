import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/enums/debt_loan_kind_enum.dart';
import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/double_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/themes/app_colors.dart';
import 'package:app_saku_rapi/features/category/controllers/category_controller.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/category/view/widgets/category_picker_sheet.dart';
import 'package:app_saku_rapi/features/dashboard/controllers/dashboard_controller.dart';
import 'package:app_saku_rapi/features/history/controllers/history_controller.dart';
import 'package:app_saku_rapi/features/ocr/controllers/pending_ocr_prefill_provider.dart';
import 'package:app_saku_rapi/features/ocr/models/ocr_parse_result_model.dart';
import 'package:app_saku_rapi/features/ocr/repositories/ocr_repository.dart';
import 'package:app_saku_rapi/features/transaction/controllers/transaction_form_controller.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_item_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/contact_picker_sheet.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/contact_picker_tile.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/debt_loan_kind_selector.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/debt_loan_transaction_picker_tile.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_amount_section.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_category_picker_tile.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_date_picker_tile.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_form_save_bar.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_multi_item_section.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_optional_details_section.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_transfer_arrow.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_type_tabs.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/unpaid_transaction_picker_sheet.dart';
import 'package:app_saku_rapi/features/voice/controllers/pending_voice_prefill_provider.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:app_saku_rapi/global/services/image_upload_service.dart';
import 'package:app_saku_rapi/global/widgets/image_source_picker_sheet.dart';
import 'package:app_saku_rapi/global/widgets/saku_text_field.dart';
import 'package:app_saku_rapi/global/widgets/saku_wallet_picker_sheet.dart';
import 'package:app_saku_rapi/global/widgets/saku_wallet_picker_tile.dart';
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

  // Auto-focus the amount field only for a brand-new transaction with no
  // pre-filled data (edit, voice, OCR, and image OCR all skip autofocus).
  late final bool _autoFocusAmount;

  @override
  void initState() {
    super.initState();

    final isNewBlank =
        widget.existingTransaction == null &&
        ref.read(pendingVoicePrefillProvider) == null &&
        ref.read(pendingOcrPrefillProvider) == null &&
        ref.read(pendingOcrImageFileProvider) == null;
    _autoFocusAmount = isNewBlank;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = ref.read(transactionFormControllerProvider.notifier);

      if (widget.existingTransaction != null) {
        final txn = widget.existingTransaction!;
        ctrl.loadExistingTransaction(txn);
        // Pre-fill text fields
        _merchantController.text = txn.merchantName ?? '';
        _noteController.text = txn.note ?? '';

        // ── Resolve wallet, destWallet, category dari provider ──
        _resolveEditLookups(ctrl, txn);
      } else {
        // Single-item mode default
        ctrl.initSingleItem();

        // ── Voice prefill (jika ada) ──
        _applyVoicePrefill(ctrl);

        // ── OCR prefill (jika ada) ──
        _applyOcrPrefill(ctrl);
        _applyOcrImagePrefill(ctrl);
      }

      // Ensure wallets are loaded
      ref.read(walletControllerProvider.notifier).loadWallets();
    });
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Terapkan data voice parse ke form (prefill only, bukan auto-save).
  ///
  /// Membaca [pendingVoicePrefillProvider], jika ada data:
  /// - Set type (expense/income/transfer/debt/loan)
  /// - Set debtLoanKind (debt/loan/debt_payment/loan_collection)
  /// - Set total amount
  /// - Set note
  /// - Set date
  /// - Set merchant
  /// - Set wallet (match by name)
  /// - Set destination wallet (transfer)
  /// - Set withPerson (debt/loan)
  /// - Set category (lookup via categoryKeyword)
  /// - Clear provider setelah dibaca
  void _applyVoicePrefill(TransactionFormController ctrl) {
    final voiceResult = ref.read(pendingVoicePrefillProvider);
    if (voiceResult == null) return;

    // Clear provider agar tidak ke-apply ulang
    ref.read(pendingVoicePrefillProvider.notifier).state = null;

    // Set type
    ctrl.setType(voiceResult.type);

    // Set debtLoanKind (pelunasan/penerimaan dari AI)
    if (voiceResult.debtLoanKind != null &&
        voiceResult.debtLoanKind!.isNotEmpty) {
      try {
        final kind = DebtLoanKindEnum.fromString(voiceResult.debtLoanKind!);
        ctrl.setDebtLoanKind(kind);
      } catch (_) {
        // Unknown kind → abaikan, pakai default dari setType
      }
    }

    // Set amount
    if (voiceResult.amount != null && voiceResult.amount! > 0) {
      ctrl.setTotalAmount(voiceResult.amount!);
    }

    // Set note (prefer note > rawTranscript)
    final note = voiceResult.note ?? voiceResult.rawTranscript;
    if (note != null && note.isNotEmpty) {
      ctrl.setNote(note);
      _noteController.text = note;
    }

    // Set date
    if (voiceResult.date != null) {
      ctrl.setDate(voiceResult.date!);
    }

    // Set merchant
    if (voiceResult.merchantName != null &&
        voiceResult.merchantName!.isNotEmpty) {
      ctrl.setMerchant(voiceResult.merchantName);
      _merchantController.text = voiceResult.merchantName!;
    }

    // Set wallet (match by name, case-insensitive)
    final wallets = ref.read(walletListProvider);
    if (voiceResult.suggestedWallet != null &&
        voiceResult.suggestedWallet!.isNotEmpty) {
      final walletName = voiceResult.suggestedWallet!.toLowerCase();
      final matched = wallets.where((w) => w.name.toLowerCase() == walletName);
      if (matched.isNotEmpty) {
        ctrl.setWallet(matched.first);
      }
    }

    // Set destination wallet (transfer)
    if (voiceResult.type == TransactionTypeEnum.transfer &&
        voiceResult.destinationWallet != null &&
        voiceResult.destinationWallet!.isNotEmpty) {
      final destName = voiceResult.destinationWallet!.toLowerCase();
      final matched = wallets.where((w) => w.name.toLowerCase() == destName);
      if (matched.isNotEmpty) {
        ctrl.setDestinationWallet(matched.first);
      }
    }

    // Set withPerson (debt/loan)
    if (voiceResult.withPerson != null && voiceResult.withPerson!.isNotEmpty) {
      ctrl.setWithPerson(voiceResult.withPerson);
    }

    // Set category (prefer categoryId exact match → fallback categoryKeyword)
    if (voiceResult.type == TransactionTypeEnum.expense ||
        voiceResult.type == TransactionTypeEnum.income) {
      final categoryType = voiceResult.type == TransactionTypeEnum.income
          ? CategoryType.income
          : CategoryType.expense;
      final allCategories = ref
          .read(categoryControllerProvider)
          .categories
          .where((c) => c.type == categoryType)
          .toList();

      CategoryModel? matched;

      // 1) Exact match by categoryId (dari AI)
      if (voiceResult.categoryId != null &&
          voiceResult.categoryId!.isNotEmpty) {
        matched = allCategories
            .where((c) => c.id == voiceResult.categoryId)
            .firstOrNull;
      }

      // 2) Fallback: fuzzy match by categoryKeyword
      if (matched == null &&
          voiceResult.categoryKeyword != null &&
          voiceResult.categoryKeyword!.isNotEmpty) {
        final kw = voiceResult.categoryKeyword!.toLowerCase();
        for (final cat in allCategories) {
          if (cat.name.toLowerCase() == kw) {
            matched = cat;
            break;
          }
        }
        // Partial match jika exact name tidak ditemukan
        if (matched == null) {
          for (final cat in allCategories) {
            if (cat.name.toLowerCase().contains(kw) ||
                kw.contains(cat.name.toLowerCase())) {
              matched = cat;
              break;
            }
          }
        }
      }

      if (matched != null) {
        ctrl.setCategory(matched);
      }
    }
  }

  /// Terapkan data OCR parse ke form (prefill only, bukan auto-save).
  ///
  /// Membaca [pendingOcrPrefillProvider], jika ada data:
  /// - Set type sesuai hasil AI (expense/income/transfer/debt/loan)
  /// - Set debtLoanKind jika settlement (debt_payment/loan_collection)
  /// - Set merchant name
  /// - Set date
  /// - Set total amount
  /// - Prefill items (multi-item mode jika expense > 1 item)
  /// - Auto-assign kategori per item dari AI
  /// - Match wallet/person sesuai tipe transaksi
  /// - Balance items jika total mismatch (expense only)
  /// - Clear provider setelah dibaca
  void _applyOcrPrefill(TransactionFormController ctrl) {
    final ocrResult = ref.read(pendingOcrPrefillProvider);
    if (ocrResult == null) return;

    // Clear provider agar tidak ke-apply ulang
    ref.read(pendingOcrPrefillProvider.notifier).state = null;

    // Set type dari OCR result (termasuk settlement → debt/loan)
    final type = _parseOcrType(ocrResult.type);
    ctrl.setType(type);

    // Set debtLoanKind untuk settlement (debt_payment / loan_collection)
    final ocrDebtLoanKind = _parseOcrDebtLoanKind(ocrResult.type);
    if (ocrDebtLoanKind != null) {
      ctrl.setDebtLoanKind(ocrDebtLoanKind);
    }

    // Merchant / note
    if (ocrResult.merchantName != null && ocrResult.merchantName!.isNotEmpty) {
      ctrl.setMerchant(ocrResult.merchantName);
      _merchantController.text = ocrResult.merchantName!;
    }
    if (ocrResult.note != null && ocrResult.note!.isNotEmpty) {
      _noteController.text = ocrResult.note!;
      ctrl.setNote(ocrResult.note);
    }

    // Date
    if (ocrResult.date != null) {
      ctrl.setDate(ocrResult.date!);
    }

    // Wallet matching (by name, case-insensitive)
    final wallets = ref.read(walletListProvider);
    if (ocrResult.suggestedWallet != null &&
        ocrResult.suggestedWallet!.isNotEmpty) {
      final walletName = ocrResult.suggestedWallet!.toLowerCase();
      final matched = wallets.where((w) => w.name.toLowerCase() == walletName);
      if (matched.isNotEmpty) {
        ctrl.setWallet(matched.first);
      }
    }

    // Destination wallet (transfer only)
    if (type == TransactionTypeEnum.transfer &&
        ocrResult.destinationWallet != null &&
        ocrResult.destinationWallet!.isNotEmpty) {
      final destName = ocrResult.destinationWallet!.toLowerCase();
      final matched = wallets.where((w) => w.name.toLowerCase() == destName);
      if (matched.isNotEmpty) {
        ctrl.setDestinationWallet(matched.first);
      }
    }

    // Person (debt/loan only)
    if (ocrResult.withPerson != null && ocrResult.withPerson!.isNotEmpty) {
      ctrl.setWithPerson(ocrResult.withPerson);
    }

    // Category matching for expense/income
    if (type == TransactionTypeEnum.expense ||
        type == TransactionTypeEnum.income) {
      final categoryType = type == TransactionTypeEnum.income
          ? CategoryType.income
          : CategoryType.expense;
      final allCategories = ref
          .read(categoryControllerProvider)
          .categories
          .where((c) => c.type == categoryType)
          .toList();
      final categoryLookup = {for (final c in allCategories) c.id: c};

      // Expense: per-item categories + items + balancing
      if (type == TransactionTypeEnum.expense) {
        if (ocrResult.items.length == 1) {
          // ── Single item → single-item mode ──
          // Cek SEBELUM balanceResult agar balance item tidak
          // membuat 1 item receipt menjadi multi-item.
          final item = ocrResult.items.first;

          // Pakai grandTotal jika ada (lebih akurat, termasuk tax/tip)
          final amount =
              (ocrResult.grandTotal != null && ocrResult.grandTotal! > 0)
              ? ocrResult.grandTotal!
              : item.subtotal;
          if (amount > 0) ctrl.setTotalAmount(amount);

          // Nama item → note (gabungkan dengan note AI jika ada)
          final parts = <String>[];
          if (item.name != null && item.name!.isNotEmpty) {
            parts.add(item.name!);
          }
          if (ocrResult.note != null && ocrResult.note!.isNotEmpty) {
            parts.add(ocrResult.note!);
          }
          if (parts.isNotEmpty) {
            final combinedNote = parts.join(' — ');
            ctrl.setNote(combinedNote);
            _noteController.text = combinedNote;
          }

          // Kategori dari item jika ada
          if (item.categoryId != null) {
            final cat = categoryLookup[item.categoryId];
            if (cat != null) {
              ctrl.setCategory(cat);
            }
          }
        } else if (ocrResult.items.length > 1) {
          // ── Multi-item → balance dulu, lalu prefill ──
          final balanced = OcrRepository.balanceResult(ocrResult);
          final txItems = balanced.items.asMap().entries.map((e) {
            final ocrItem = e.value;
            final cat = ocrItem.categoryId != null
                ? categoryLookup[ocrItem.categoryId]
                : null;

            return TransactionItemModel(
              itemName: ocrItem.name,
              qty: ocrItem.qty,
              unitPrice: ocrItem.unitPrice,
              amount: ocrItem.subtotal,
              sortOrder: e.key,
              categoryId: cat?.id,
              categoryName: cat?.name,
              categoryIcon: cat?.icon,
              categoryColor: cat?.color,
            );
          }).toList();
          ctrl.prefillItems(txItems);
        } else if (ocrResult.grandTotal != null && ocrResult.grandTotal! > 0) {
          // Tidak ada items tapi ada total → single-item mode
          ctrl.setTotalAmount(ocrResult.grandTotal!);
        }

        // Top-level category for expense (from categoryId or keyword)
        _matchOcrTopLevelCategory(
          ctrl,
          ocrResult,
          allCategories,
          categoryLookup,
        );
      }

      // Income: just total + top-level category
      if (type == TransactionTypeEnum.income) {
        if (ocrResult.grandTotal != null && ocrResult.grandTotal! > 0) {
          ctrl.setTotalAmount(ocrResult.grandTotal!);
        }
        _matchOcrTopLevelCategory(
          ctrl,
          ocrResult,
          allCategories,
          categoryLookup,
        );
      }
    } else {
      // Transfer/Debt/Loan: just total
      if (ocrResult.grandTotal != null && ocrResult.grandTotal! > 0) {
        ctrl.setTotalAmount(ocrResult.grandTotal!);
      }
    }
  }

  /// Set lampiran dari file OCR (jika ada) ke local attachment.
  ///
  /// Membaca [pendingOcrImageFileProvider], jika ada file:
  /// - Set sebagai localAttachmentPath di form state
  /// - Clear provider setelah dibaca
  void _applyOcrImagePrefill(TransactionFormController ctrl) {
    final imageFile = ref.read(pendingOcrImageFileProvider);
    if (imageFile == null) return;

    ref.read(pendingOcrImageFileProvider.notifier).state = null;
    ctrl.setLocalAttachment(imageFile.path);
  }

  /// Resolve wallet, destination wallet, dan category untuk mode edit.
  ///
  /// Dipanggil setelah [TransactionFormController.loadExistingTransaction]
  /// karena controller tidak punya akses ke provider wallet/category.
  void _resolveEditLookups(
    TransactionFormController ctrl,
    TransactionModel txn,
  ) {
    // ── Wallet ──
    final wallets = ref.read(walletListProvider);
    final wallet = wallets.where((w) => w.id == txn.walletId).firstOrNull;

    // ── Destination wallet (transfer) ──
    WalletModel? destWallet;
    if (txn.destinationWalletId != null) {
      destWallet = wallets
          .where((w) => w.id == txn.destinationWalletId)
          .firstOrNull;
    }

    // ── Category (dari item pertama — single-item atau top-level) ──
    CategoryModel? category;
    final firstCatId = txn.items.isNotEmpty ? txn.items.first.categoryId : null;
    if (firstCatId != null) {
      category = ref
          .read(categoryControllerProvider)
          .categories
          .where((c) => c.id == firstCatId)
          .firstOrNull;
    }

    ctrl.resolveEditLookups(
      wallet: wallet,
      destinationWallet: destWallet,
      category: category,
    );
  }

  /// Match top-level categoryId/categoryKeyword ke kategori user.
  void _matchOcrTopLevelCategory(
    TransactionFormController ctrl,
    OcrParseResultModel ocrResult,
    List<CategoryModel> allCategories,
    Map<String, CategoryModel> categoryLookup,
  ) {
    CategoryModel? matched;

    // 1) Exact match by categoryId
    if (ocrResult.categoryId != null && ocrResult.categoryId!.isNotEmpty) {
      matched = categoryLookup[ocrResult.categoryId];
    }

    // 2) Fallback: match by categoryKeyword
    if (matched == null &&
        ocrResult.categoryKeyword != null &&
        ocrResult.categoryKeyword!.isNotEmpty) {
      final kw = ocrResult.categoryKeyword!.toLowerCase();
      for (final cat in allCategories) {
        if (cat.name.toLowerCase() == kw) {
          matched = cat;
          break;
        }
      }
      // Partial match
      if (matched == null) {
        for (final cat in allCategories) {
          if (cat.name.toLowerCase().contains(kw) ||
              kw.contains(cat.name.toLowerCase())) {
            matched = cat;
            break;
          }
        }
      }
    }

    if (matched != null) {
      ctrl.setCategory(matched);
    }
  }

  /// Parse OCR type string ke [TransactionTypeEnum].
  ///
  /// Settlement types (debt_payment, loan_collection) di-map ke base type
  /// (debt, loan). Gunakan [_parseOcrDebtLoanKind] untuk mendapatkan
  /// [DebtLoanKindEnum] yang spesifik.
  TransactionTypeEnum _parseOcrType(String rawType) {
    return switch (rawType.toLowerCase()) {
      'income' => TransactionTypeEnum.income,
      'expense' => TransactionTypeEnum.expense,
      'transfer' => TransactionTypeEnum.transfer,
      'debt' => TransactionTypeEnum.debt,
      'debt_payment' => TransactionTypeEnum.debt,
      'loan' => TransactionTypeEnum.loan,
      'loan_collection' => TransactionTypeEnum.loan,
      _ => TransactionTypeEnum.expense,
    };
  }

  /// Parse OCR type string ke [DebtLoanKindEnum] jika applicable.
  ///
  /// Returns null untuk non-debt/loan types.
  DebtLoanKindEnum? _parseOcrDebtLoanKind(String rawType) {
    return switch (rawType.toLowerCase()) {
      'debt' => DebtLoanKindEnum.debt,
      'loan' => DebtLoanKindEnum.loan,
      'debt_payment' => DebtLoanKindEnum.debtPayment,
      'loan_collection' => DebtLoanKindEnum.loanCollection,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final formState = ref.watch(transactionFormControllerProvider);
    final isEditing = formState.isEditing;
    final isSaving = formState.isSaving;
    final typeColor = _colorForType(formState.type, colors);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: colors.background,
        body: Form(
          key: _formKey,
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                    // ─── Debt/Loan sub-category selector ───
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

                    // ─── Settlement: reference transaction picker ───
                    if (formState.isSettlementMode && !isEditing) ...[
                      DebtLoanTransactionPickerTile(
                        selected: formState.referenceTransaction,
                        iconColor: typeColor,
                        onTap: () => _pickReferenceTransaction(formState),
                      ),
                      SizedBox(height: 10.h),
                    ],

                    // ─── Amount ───
                    if (!formState.isMultiItem) ...[
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
                      // Settlement amount hint
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

                    // ─── Wallet ───
                    SakuWalletPickerTile(
                      label: formState.type == TransactionTypeEnum.transfer
                          ? l10n.transactionSourceWallet
                          : l10n.transactionWallet,
                      selected: formState.wallet,
                      onTap: () => _pickWallet(isSource: true),
                      iconColor: colors.primary,
                    ),

                    // Destination wallet (transfer only)
                    if (formState.type == TransactionTypeEnum.transfer) ...[
                      TransactionTransferArrow(
                        color: colors.transfer,
                        onSwap: () => ref
                            .read(transactionFormControllerProvider.notifier)
                            .swapWallets(),
                      ),
                      SakuWalletPickerTile(
                        label: l10n.transactionDestWallet,
                        selected: formState.destinationWallet,
                        onTap: () => _pickWallet(isSource: false),
                        iconColor: colors.transfer,
                      ),
                    ],

                    SizedBox(height: 10.h),

                    // ─── Category (income/expense single-item mode) ───
                    if (!formState.isSettlementMode &&
                        !formState.isMultiItem &&
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

                    // ─── With person (debt/loan — not in settlement mode) ───
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
                              .read(transactionFormControllerProvider.notifier)
                              .setContact(null);
                        },
                      ),
                      SizedBox(height: 10.h),
                    ],

                    // ─── Date ───
                    TransactionDatePickerTile(
                      date: formState.date,
                      onChanged: (date) {
                        FocusScope.of(context).unfocus();
                        ref
                            .read(transactionFormControllerProvider.notifier)
                            .setDate(date);
                      },
                    ),

                    SizedBox(height: 14.h),

                    // ─── Optional details (merchant, note, attachment) ───
                    if (!formState.isSettlementMode)
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
                        onPickAttachment: _pickAttachment,
                        onRemoveAttachment: () => ref
                            .read(transactionFormControllerProvider.notifier)
                            .setLocalAttachment(null),
                      ),

                    // ─── Settlement note (simplified) ───
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

                    // ─── Multi-item section (expense & income, non-settlement) ───
                    if (!formState.isSettlementMode &&
                        (formState.type == TransactionTypeEnum.expense ||
                            formState.type == TransactionTypeEnum.income)) ...[
                      SizedBox(height: 16.h),
                      const TransactionMultiItemSection(),
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
      ),
    );
  }

  // ─── Actions ───

  Future<void> _pickWallet({required bool isSource}) async {
    FocusScope.of(context).unfocus();
    final formState = ref.read(transactionFormControllerProvider);
    final ctrl = ref.read(transactionFormControllerProvider.notifier);

    final result = await SakuWalletPickerSheet.show(
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
    FocusScope.of(context).unfocus();
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

  Future<void> _pickReferenceTransaction(TransactionFormState formState) async {
    FocusScope.of(context).unfocus();
    final subCat = formState.debtLoanKind;
    if (subCat == null || !subCat.isSettlement) return;

    final result = await UnpaidTransactionPickerSheet.show(
      context,
      type: subCat.referenceType,
      selectedId: formState.referenceTransaction?.id,
    );

    if (result != null && mounted) {
      ref
          .read(transactionFormControllerProvider.notifier)
          .setReferenceTransaction(result);
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

    // Settlement-specific validations
    if (formState.isSettlementMode) {
      if (formState.referenceTransaction == null) {
        if (!mounted) return;
        context.showAppAlert(
          l10n.debtLoanFormPickTransaction,
          alertType: AlertTypeEnum.error,
        );
        return;
      }

      final remaining = formState.referenceTransaction!.remaining;
      if (formState.totalAmount > remaining) {
        if (!mounted) return;
        context.showAppAlert(
          l10n.debtLoanFormAmountExceedsRemaining(remaining.toCurrency()),
          alertType: AlertTypeEnum.error,
        );
        return;
      }
    }

    context.showLoadingOverlay();

    try {
      // Upload lampiran lokal jika ada (lazy upload)
      if (formState.localAttachmentPath != null) {
        final url = await _uploadLocalAttachment(
          formState.localAttachmentPath!,
        );
        if (!mounted) return;
        if (url != null) {
          ref
              .read(transactionFormControllerProvider.notifier)
              .setAttachmentUrl(url);
        }
        // Jika upload gagal, tetap lanjut simpan tanpa lampiran
      }

      final result = await ref
          .read(transactionFormControllerProvider.notifier)
          .submit();

      if (!mounted) return;
      context.closeOverlay();

      if (result.isSuccess()) {
        ref.read(walletControllerProvider.notifier).loadWallets();
        ref.read(dashboardControllerProvider.notifier).loadDashboard();
        ref.read(historyControllerProvider.notifier).loadTransactions();
        context.showAppAlert(
          l10n.transactionSaveSuccess,
          alertType: AlertTypeEnum.success,
        );
        context.pop(true);
      } else {
        final (message, _, _, _) = result.dataError()!;
        context.showAppAlert(message, alertType: AlertTypeEnum.error);
      }
    } finally {
      if (mounted) context.closeOverlay();
    }
  }

  Future<void> _confirmDelete() async {
    if (!mounted) return;

    final l10n = context.l10n;

    final confirmed = await context.showConfirmDialog(
      title: l10n.transactionDeleteConfirmTitle,
      message: l10n.transactionDeleteConfirmMessage,
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
        ref.read(walletControllerProvider.notifier).loadWallets();
        ref.read(dashboardControllerProvider.notifier).loadDashboard();
        ref.read(historyControllerProvider.notifier).loadTransactions();
        context.closeOverlay();
        context.showAppAlert(
          l10n.transactionDeleteSuccess,
          alertType: AlertTypeEnum.success,
        );
        context.pop(true);
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

  /// Pick image → simpan path local → upload terjadi saat simpan.
  Future<void> _pickAttachment() async {
    FocusScope.of(context).unfocus();
    final file = await ImageSourcePickerSheet.show(context);
    if (file == null || !mounted) return;

    ref
        .read(transactionFormControllerProvider.notifier)
        .setLocalAttachment(file.path);
  }

  /// Upload attachment lokal (compress → Supabase) dan return URL.
  /// Dipanggil dari [_onSave] sebelum submit ke DB.
  Future<String?> _uploadLocalAttachment(String localPath) async {
    final compressed = await CompressImageFunc.call(filePath: localPath);
    if (compressed == null) return null;

    final service = ImageUploadService();
    final result = await service.uploadImage(
      imageBytes: compressed,
      fileName: 'attachment.jpg',
    );

    if (result.isSuccess()) return result.dataSuccess()!;
    return null;
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
