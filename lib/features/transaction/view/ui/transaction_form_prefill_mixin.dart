import 'package:app_saku_rapi/core/enums/debt_loan_kind_enum.dart';
import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/features/category/controllers/category_controller.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/home_widget/home_widget_deep_link_handler.dart';
import 'package:app_saku_rapi/features/ocr/controllers/pending_ocr_prefill_provider.dart';
import 'package:app_saku_rapi/features/ocr/models/ocr_parse_result_model.dart';
import 'package:app_saku_rapi/features/ocr/repositories/ocr_repository.dart';
import 'package:app_saku_rapi/features/transaction/controllers/transaction_form_controller.dart';
import 'package:app_saku_rapi/features/transaction/models/manual_transaction_entry_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_item_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:app_saku_rapi/features/voice/models/voice_parse_result_model.dart';
import 'package:app_saku_rapi/global/models/ai_parse_transaction_slice.dart';
import 'package:app_saku_rapi/features/voice/controllers/pending_voice_prefill_provider.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'transaction_form_page.dart';

// ═══════════════════════════════════════════════
//  TransactionFormPrefillMixin
// ═══════════════════════════════════════════════

/// Mixin yang menangani seluruh logika *prefill* form transaksi.
///
/// Di-mix ke [_TransactionFormPageState] agar `initState` tetap ringkas.
/// Menggunakan [ref] dan [context] dari [ConsumerState] secara langsung.
///
/// Metode yang tersedia (dipanggil dari [initState]):
/// - [applyVoicePrefill]        — prefill dari hasil AI voice
/// - [applyOcrPrefill]          — prefill dari hasil OCR struk
/// - [applyOcrImagePrefill]     — set lampiran foto OCR
/// - [applyWidgetWalletPrefill] — pre-select wallet dari home widget
/// - [resolveEditLookups]       — resolve wallet/category saat mode edit
mixin TransactionFormPrefillMixin on ConsumerState<TransactionFormPage> {
  // ─── Abstract getters ───
  // Harus diimplementasikan oleh class yang menggunakan mixin ini.

  /// Controller untuk field merchant name di UI.
  TextEditingController get merchantController;

  /// Controller untuk field catatan di UI.
  TextEditingController get noteController;

  // ═══════════════════════════════════════════════
  //  Voice Prefill
  // ═══════════════════════════════════════════════

  /// Terapkan data voice parse ke form (prefill only, bukan auto-save).
  ///
  /// Membaca [pendingVoicePrefillProvider]. Jika ada data:
  /// - Set type (expense/income/transfer/debt/loan)
  /// - Set debtLoanKind (debt/loan/debt_payment/loan_collection)
  /// - Set total amount (dari items total jika multi-item)
  /// - Set note (prefer note > rawTranscript)
  /// - Set date dan merchant
  /// - Set wallet / destination wallet (match by UUID dari AI)
  /// - Set withPerson (debt/loan)
  /// - Set category (lookup via categoryId → fallback categoryKeyword)
  /// - Prefill items jika expense/income > 1 item
  /// - Clear provider setelah dibaca agar tidak ke-apply ulang
  void applyVoicePrefill(TransactionFormController ctrl) {
    final voiceResult = ref.read(pendingVoicePrefillProvider);
    if (voiceResult == null) return;

    // Clear provider agar tidak ke-apply ulang saat rebuild
    ref.read(pendingVoicePrefillProvider.notifier).state = null;

    if (voiceResult.isAiMultiTransaction &&
        (voiceResult.type == TransactionTypeEnum.expense ||
            voiceResult.type == TransactionTypeEnum.income)) {
      _applyVoiceAiMultiPrefill(ctrl, voiceResult);
      return;
    }

    // Set tipe transaksi
    ctrl.setType(voiceResult.type);

    // Set debtLoanKind dari hasil AI (pelunasan/penerimaan)
    if (voiceResult.debtLoanKind != null &&
        voiceResult.debtLoanKind!.isNotEmpty) {
      try {
        final kind = DebtLoanKindEnum.fromString(voiceResult.debtLoanKind!);
        ctrl.setDebtLoanKind(kind);
      } catch (_) {
        // Unknown kind → abaikan, pakai default dari setType
      }
    }

    // Gunakan itemsTotal jika multi-item, fallback ke amount top-level
    final effectiveAmount = voiceResult.items.length > 1
        ? voiceResult.itemsTotal
        : voiceResult.amount;
    if (effectiveAmount != null && effectiveAmount > 0) {
      ctrl.setTotalAmount(effectiveAmount);
    }

    // Prefer note AI daripada raw transcript
    final note = voiceResult.note ?? voiceResult.rawTranscript;
    if (note != null && note.isNotEmpty) {
      ctrl.setNote(note);
      noteController.text = note;
    }

    if (voiceResult.date != null) {
      ctrl.setDate(voiceResult.date!);
    }

    if (voiceResult.merchantName != null &&
        voiceResult.merchantName!.isNotEmpty) {
      ctrl.setMerchant(voiceResult.merchantName);
      merchantController.text = voiceResult.merchantName!;
    }

    // Cocokkan wallet sumber by UUID
    final wallets = ref.read(walletListProvider);
    if (voiceResult.suggestedWalletId != null &&
        voiceResult.suggestedWalletId!.isNotEmpty) {
      final matched = wallets.where(
        (w) => w.id == voiceResult.suggestedWalletId,
      );
      if (matched.isNotEmpty) ctrl.setWallet(matched.first);
    }

    // Cocokkan wallet tujuan untuk transfer
    if (voiceResult.type == TransactionTypeEnum.transfer &&
        voiceResult.destinationWalletId != null &&
        voiceResult.destinationWalletId!.isNotEmpty) {
      final matched = wallets.where(
        (w) => w.id == voiceResult.destinationWalletId,
      );
      if (matched.isNotEmpty) ctrl.setDestinationWallet(matched.first);
    }

    if (voiceResult.withPerson != null && voiceResult.withPerson!.isNotEmpty) {
      ctrl.setWithPerson(voiceResult.withPerson);
    }

    // Set kategori + prefill items untuk expense/income saja
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
      final categoryLookup = {for (final c in allCategories) c.id: c};

      // Multi-item voice: bangun TransactionItemModel per baris AI
      if (voiceResult.items.length > 1) {
        final txItems = voiceResult.items.asMap().entries.map((e) {
          final voiceItem = e.value;
          return TransactionItemModel(
            itemName: voiceItem.name,
            qty: voiceItem.qty,
            unitPrice: voiceItem.unitPrice,
            amount: voiceItem.subtotal,
            sortOrder: e.key,
          );
        }).toList();
        ctrl.prefillItems(txItems);
      }

      // Match kategori level root (categoryId prioritas, keyword fallback)
      final matched = _matchCategory(
        categoryId: voiceResult.categoryId,
        keyword: voiceResult.categoryKeyword,
        allCategories: allCategories,
        lookup: categoryLookup,
      );
      if (matched != null) ctrl.setCategory(matched);
    }
  }

  // ═══════════════════════════════════════════════
  //  OCR Prefill
  // ═══════════════════════════════════════════════

  /// Terapkan data OCR parse ke form (prefill only, bukan auto-save).
  ///
  /// Membaca [pendingOcrPrefillProvider]. Jika ada data:
  /// - Set type sesuai hasil AI (termasuk settlement → debt/loan)
  /// - Set debtLoanKind jika settlement (debt_payment/loan_collection)
  /// - Set merchant name, date, note
  /// - Set wallet/destination wallet/person by UUID
  /// - Prefill items (multi-item jika expense > 1 baris)
  /// - Balance items jika total mismatch (expense multi-item)
  /// - Match kategori root dari categoryId/categoryKeyword
  /// - Clear provider setelah dibaca
  void applyOcrPrefill(TransactionFormController ctrl) {
    final ocrResult = ref.read(pendingOcrPrefillProvider);
    if (ocrResult == null) return;

    // Clear provider agar tidak ke-apply ulang
    ref.read(pendingOcrPrefillProvider.notifier).state = null;

    // Tentukan type dan debtLoanKind dari OCR result
    final type = _parseOcrType(ocrResult.type);
    ctrl.setType(type);

    final ocrDebtLoanKind = _parseOcrDebtLoanKind(ocrResult.type);
    if (ocrDebtLoanKind != null) {
      ctrl.setDebtLoanKind(ocrDebtLoanKind);
    }

    if (ocrResult.isAiMultiTransaction &&
        (type == TransactionTypeEnum.expense ||
            type == TransactionTypeEnum.income)) {
      _applyOcrAiMultiPrefill(ctrl, ocrResult, type);
      return;
    }

    // Merchant dan catatan
    if (ocrResult.merchantName != null && ocrResult.merchantName!.isNotEmpty) {
      ctrl.setMerchant(ocrResult.merchantName);
      merchantController.text = ocrResult.merchantName!;
    }
    if (ocrResult.note != null && ocrResult.note!.isNotEmpty) {
      noteController.text = ocrResult.note!;
      ctrl.setNote(ocrResult.note);
    }

    if (ocrResult.date != null) ctrl.setDate(ocrResult.date!);

    // Cocokkan wallet sumber by UUID
    final wallets = ref.read(walletListProvider);
    if (ocrResult.suggestedWalletId != null &&
        ocrResult.suggestedWalletId!.isNotEmpty) {
      final matched = wallets.where((w) => w.id == ocrResult.suggestedWalletId);
      if (matched.isNotEmpty) ctrl.setWallet(matched.first);
    }

    // Cocokkan wallet tujuan untuk transfer
    if (type == TransactionTypeEnum.transfer &&
        ocrResult.destinationWalletId != null &&
        ocrResult.destinationWalletId!.isNotEmpty) {
      final matched = wallets.where(
        (w) => w.id == ocrResult.destinationWalletId,
      );
      if (matched.isNotEmpty) ctrl.setDestinationWallet(matched.first);
    }

    // Person untuk hutang/piutang
    if (ocrResult.withPerson != null && ocrResult.withPerson!.isNotEmpty) {
      ctrl.setWithPerson(ocrResult.withPerson);
    }

    // Kategori + amount hanya untuk expense/income
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

      if (type == TransactionTypeEnum.expense) {
        _applyOcrExpenseItems(ctrl, ocrResult, categoryLookup);
      }

      if (type == TransactionTypeEnum.income) {
        // Income: hanya total + kategori root
        if (ocrResult.grandTotal != null && ocrResult.grandTotal! > 0) {
          ctrl.setTotalAmount(ocrResult.grandTotal!);
        }
      }

      // Match kategori level root untuk expense & income
      _matchOcrTopLevelCategory(ctrl, ocrResult, allCategories, categoryLookup);
    } else {
      // Transfer/Debt/Loan: hanya total
      if (ocrResult.grandTotal != null && ocrResult.grandTotal! > 0) {
        ctrl.setTotalAmount(ocrResult.grandTotal!);
      }
    }
  }

  /// Terapkan items OCR untuk tipe expense.
  ///
  /// - Single item → single-item mode (gunakan grandTotal jika ada)
  /// - Multi-item  → balance dulu via [OcrRepository.balanceResult], lalu prefill
  /// - Tidak ada items tapi ada grandTotal → set totalAmount saja
  void _applyOcrExpenseItems(
    TransactionFormController ctrl,
    OcrParseResultModel ocrResult,
    Map<String, CategoryModel> categoryLookup,
  ) {
    if (ocrResult.items.length == 1) {
      // ── Single item: cek SEBELUM balance agar 1-item receipt tidak berubah jadi multi-item ──
      final item = ocrResult.items.first;

      // Pakai grandTotal jika ada (lebih akurat, sudah termasuk tax/tip)
      final amount = (ocrResult.grandTotal != null && ocrResult.grandTotal! > 0)
          ? ocrResult.grandTotal!
          : item.subtotal;
      if (amount > 0) ctrl.setTotalAmount(amount);

      // Gabungkan nama item + note AI sebagai catatan
      final parts = <String>[];
      if (item.name != null && item.name!.isNotEmpty) parts.add(item.name!);
      if (ocrResult.note != null && ocrResult.note!.isNotEmpty) {
        parts.add(ocrResult.note!);
      }
      if (parts.isNotEmpty) {
        final combinedNote = parts.join(' — ');
        ctrl.setNote(combinedNote);
        noteController.text = combinedNote;
      }

      // Kategori dari item jika AI berhasil mengklasifikasikan per baris
      if (item.categoryId != null) {
        final cat = categoryLookup[item.categoryId];
        if (cat != null) ctrl.setCategory(cat);
      }
    } else if (ocrResult.items.length > 1) {
      // ── Multi-item: balance total dulu, lalu prefill ──
      final balanced = OcrRepository.balanceResult(ocrResult);
      final txItems = balanced.items.asMap().entries.map((e) {
        final ocrItem = e.value;
        return TransactionItemModel(
          itemName: ocrItem.name,
          qty: ocrItem.qty,
          unitPrice: ocrItem.unitPrice,
          amount: ocrItem.subtotal,
          sortOrder: e.key,
        );
      }).toList();
      ctrl.prefillItems(txItems);
    } else if (ocrResult.grandTotal != null && ocrResult.grandTotal! > 0) {
      // Tidak ada items tapi ada total → single-item mode
      ctrl.setTotalAmount(ocrResult.grandTotal!);
    }
  }

  // ═══════════════════════════════════════════════
  //  OCR Image Prefill
  // ═══════════════════════════════════════════════

  /// Set lampiran dari file OCR (jika ada) ke local attachment.
  ///
  /// Membaca [pendingOcrImageFileProvider]. Jika ada file:
  /// - Set sebagai [localAttachmentPath] di form state
  /// - Clear provider setelah dibaca
  void applyOcrImagePrefill(TransactionFormController ctrl) {
    final imageFile = ref.read(pendingOcrImageFileProvider);
    if (imageFile == null) return;

    ref.read(pendingOcrImageFileProvider.notifier).state = null;
    if (ctrl.isMultiManualModeActive) {
      ctrl.setManualMultiEntryLocalAttachment(0, imageFile.path);
    } else {
      ctrl.setLocalAttachment(imageFile.path);
    }
  }

  // ═══════════════════════════════════════════════
  //  Widget Wallet Prefill
  // ═══════════════════════════════════════════════

  /// Pre-select wallet dari home widget deep link.
  ///
  /// Membaca [pendingWidgetWalletIdProvider]. Jika ada walletId:
  /// - Cocokkan ke wallet list by ID
  /// - Set sebagai wallet sumber
  /// - Clear provider setelah dibaca
  void applyWidgetWalletPrefill(TransactionFormController ctrl) {
    final walletId = ref.read(pendingWidgetWalletIdProvider);
    if (walletId == null || walletId.isEmpty) return;

    ref.read(pendingWidgetWalletIdProvider.notifier).state = null;

    final wallets = ref.read(walletListProvider);
    final matched = wallets.where((w) => w.id == walletId);
    if (matched.isNotEmpty) ctrl.setWallet(matched.first);
  }

  // ═══════════════════════════════════════════════
  //  Edit Lookups
  // ═══════════════════════════════════════════════

  /// Resolve wallet, destination wallet, dan category untuk mode edit.
  ///
  /// Dipanggil setelah [TransactionFormController.loadExistingTransaction]
  /// karena controller tidak punya akses ke provider wallet/category.
  ///
  /// Logika:
  /// - Cari wallet sumber by walletId
  /// - Cari wallet tujuan by destinationWalletId (transfer saja)
  /// - Cari kategori dari item pertama yang punya categoryId
  void resolveEditLookups(
    TransactionFormController ctrl,
    TransactionModel txn,
  ) {
    final wallets = ref.read(walletListProvider);
    final wallet = wallets.where((w) => w.id == txn.walletId).firstOrNull;

    // Destination wallet hanya ada pada transfer
    WalletModel? destWallet;
    if (txn.destinationWalletId != null) {
      destWallet = wallets
          .where((w) => w.id == txn.destinationWalletId)
          .firstOrNull;
    }

    // Ambil categoryId dari baris item pertama yang memilikinya
    // (legacy support: dulu setiap item bisa punya kategori berbeda)
    String? resolvedCatId;
    for (final it in txn.items) {
      final id = it.categoryId;
      if (id != null && id.isNotEmpty) {
        resolvedCatId = id;
        break;
      }
    }

    CategoryModel? category;
    if (resolvedCatId != null) {
      category = ref
          .read(categoryControllerProvider)
          .categories
          .where((c) => c.id == resolvedCatId)
          .firstOrNull;
    }

    ctrl.resolveEditLookups(
      wallet: wallet,
      destinationWallet: destWallet,
      category: category,
    );
  }

  // ═══════════════════════════════════════════════
  //  Private Helpers
  // ═══════════════════════════════════════════════

  void _applyVoiceAiMultiPrefill(
    TransactionFormController ctrl,
    VoiceParseResultModel voiceResult,
  ) {
    ctrl.setType(voiceResult.type);
    if (voiceResult.debtLoanKind != null &&
        voiceResult.debtLoanKind!.isNotEmpty) {
      try {
        final kind = DebtLoanKindEnum.fromString(voiceResult.debtLoanKind!);
        ctrl.setDebtLoanKind(kind);
      } catch (_) {}
    }

    final txs = voiceResult.aiTransactions!;
    final categoryType = voiceResult.type == TransactionTypeEnum.income
        ? CategoryType.income
        : CategoryType.expense;
    final allCategories = ref
        .read(categoryControllerProvider)
        .categories
        .where((c) => c.type == categoryType)
        .toList();
    final lookup = {for (final c in allCategories) c.id: c};

    final wallets = ref.read(walletListProvider);

    if (voiceResult.type == TransactionTypeEnum.transfer &&
        voiceResult.destinationWalletId != null &&
        voiceResult.destinationWalletId!.isNotEmpty) {
      final matched = wallets.where(
        (w) => w.id == voiceResult.destinationWalletId,
      );
      if (matched.isNotEmpty) ctrl.setDestinationWallet(matched.first);
    }

    if (voiceResult.withPerson != null &&
        voiceResult.withPerson!.isNotEmpty) {
      ctrl.setWithPerson(voiceResult.withPerson);
    }

    final entries = <ManualTransactionEntryModel>[];
    for (var i = 0; i < txs.length; i++) {
      final slice = txs[i];
      final entryWallet = _walletForAiMultiSlice(
        slice.suggestedWalletId,
        voiceResult.suggestedWalletId,
        wallets,
      );
      final matched = _matchCategory(
        categoryId: slice.categoryId,
        keyword: slice.categoryKeyword,
        allCategories: allCategories,
        lookup: lookup,
      );
      final items = _withCategoryOnItems(
        matched,
        _transactionItemsFromAiSlice(slice),
      );
      final total = TransactionFormController.sumItemsForTest(items);
      entries.add(
        ManualTransactionEntryModel(
          entryKey: 0,
          wallet: entryWallet,
          category: matched,
          items: items,
          itemKeys: const [0],
          date: voiceResult.date,
          merchantName: slice.merchantName ??
              (i == 0 ? voiceResult.merchantName : null),
          note: slice.note,
          totalAmount: total,
        ),
      );
    }

    ctrl.prefillMultiManualEntries(entries);

    for (final e in entries) {
      if (e.wallet != null) {
        ctrl.setWallet(e.wallet!);
        break;
      }
    }

    final firstMerchant = entries.first.merchantName;
    if (firstMerchant != null && firstMerchant.isNotEmpty) {
      ctrl.setMerchant(firstMerchant);
      merchantController.text = firstMerchant;
    }
  }

  void _applyOcrAiMultiPrefill(
    TransactionFormController ctrl,
    OcrParseResultModel ocrResult,
    TransactionTypeEnum type,
  ) {
    final categoryType = type == TransactionTypeEnum.income
        ? CategoryType.income
        : CategoryType.expense;
    final allCategories = ref
        .read(categoryControllerProvider)
        .categories
        .where((c) => c.type == categoryType)
        .toList();
    final lookup = {for (final c in allCategories) c.id: c};

    final wallets = ref.read(walletListProvider);

    if (type == TransactionTypeEnum.transfer &&
        ocrResult.destinationWalletId != null &&
        ocrResult.destinationWalletId!.isNotEmpty) {
      final matched = wallets.where(
        (w) => w.id == ocrResult.destinationWalletId,
      );
      if (matched.isNotEmpty) ctrl.setDestinationWallet(matched.first);
    }

    if (ocrResult.withPerson != null && ocrResult.withPerson!.isNotEmpty) {
      ctrl.setWithPerson(ocrResult.withPerson);
    }

    final txs = ocrResult.aiTransactions!;
    final entries = <ManualTransactionEntryModel>[];
    for (var i = 0; i < txs.length; i++) {
      final slice = txs[i];
      final entryWallet = _walletForAiMultiSlice(
        slice.suggestedWalletId,
        ocrResult.suggestedWalletId,
        wallets,
      );
      final matched = _matchCategory(
        categoryId: slice.categoryId,
        keyword: slice.categoryKeyword,
        allCategories: allCategories,
        lookup: lookup,
      );
      final items = _withCategoryOnItems(
        matched,
        _transactionItemsFromAiSlice(slice),
      );
      final total = TransactionFormController.sumItemsForTest(items);
      final note = slice.note ?? (i == 0 ? ocrResult.note : null);
      entries.add(
        ManualTransactionEntryModel(
          entryKey: 0,
          wallet: entryWallet,
          category: matched,
          items: items,
          itemKeys: const [0],
          date: ocrResult.date,
          merchantName: slice.merchantName ??
              (i == 0 ? ocrResult.merchantName : null),
          note: note,
          totalAmount: total,
        ),
      );
    }

    ctrl.prefillMultiManualEntries(entries);

    for (final e in entries) {
      if (e.wallet != null) {
        ctrl.setWallet(e.wallet!);
        break;
      }
    }

    final firstMerchant = entries.first.merchantName;
    if (firstMerchant != null && firstMerchant.isNotEmpty) {
      ctrl.setMerchant(firstMerchant);
      merchantController.text = firstMerchant;
    }
    final firstNote = entries.first.note;
    if (firstNote != null && firstNote.isNotEmpty) {
      ctrl.setNote(firstNote);
      noteController.text = firstNote;
    }
  }

  /// Dompet per entri multi: slice menang, lalu fallback ke dompet root AI.
  WalletModel? _walletForAiMultiSlice(
    String? sliceWalletId,
    String? rootWalletId,
    List<WalletModel> wallets,
  ) {
    final id = (sliceWalletId != null && sliceWalletId.isNotEmpty)
        ? sliceWalletId
        : rootWalletId;
    if (id == null || id.isEmpty) return null;
    return wallets.where((w) => w.id == id).firstOrNull;
  }

  List<TransactionItemModel> _transactionItemsFromAiSlice(
    AiParseTransactionSlice slice,
  ) {
    if (slice.items.length > 1) {
      return slice.items.asMap().entries.map((e) {
        final li = e.value;
        return TransactionFormController.resolveItemAmountForTest(
          TransactionItemModel(
            itemName: li.name,
            qty: li.qty,
            unitPrice: li.unitPrice,
            amount: li.subtotal,
            sortOrder: e.key,
          ),
        );
      }).toList();
    }
    if (slice.items.length == 1) {
      final li = slice.items.first;
      final amt = li.subtotal > 0 ? li.subtotal : (slice.amount ?? 0);
      return [
        TransactionFormController.resolveItemAmountForTest(
          TransactionItemModel(
            itemName: li.name,
            qty: li.qty,
            unitPrice: li.unitPrice,
            amount: amt,
            sortOrder: 0,
          ),
        ),
      ];
    }
    return [
      TransactionItemModel(
        amount: slice.amount ?? 0,
        sortOrder: 0,
        itemName: slice.note,
      ),
    ];
  }

  List<TransactionItemModel> _withCategoryOnItems(
    CategoryModel? cat,
    List<TransactionItemModel> items,
  ) {
    if (cat == null) return items;
    return items
        .map(
          (i) => i.copyWith(
            categoryId: cat.id,
            categoryName: cat.name,
            categoryIcon: cat.icon,
            categoryColor: cat.color,
            categoryBackgroundColor: cat.backgroundColor,
          ),
        )
        .toList();
  }

  /// Match kategori OCR level root ke kategori milik user.
  ///
  /// Urutan prioritas:
  /// 1. Exact match by categoryId dari AI
  /// 2. Exact name match by categoryKeyword
  /// 3. Partial name match by categoryKeyword
  void _matchOcrTopLevelCategory(
    TransactionFormController ctrl,
    OcrParseResultModel ocrResult,
    List<CategoryModel> allCategories,
    Map<String, CategoryModel> categoryLookup,
  ) {
    final matched = _matchCategory(
      categoryId: ocrResult.categoryId,
      keyword: ocrResult.categoryKeyword,
      allCategories: allCategories,
      lookup: categoryLookup,
    );
    if (matched != null) ctrl.setCategory(matched);
  }

  /// Cari [CategoryModel] berdasarkan [categoryId] atau fuzzy [keyword].
  ///
  /// Mengembalikan null jika tidak ditemukan.
  CategoryModel? _matchCategory({
    required String? categoryId,
    required String? keyword,
    required List<CategoryModel> allCategories,
    required Map<String, CategoryModel> lookup,
  }) {
    // 1) Exact match by UUID
    if (categoryId != null && categoryId.isNotEmpty) {
      final found = lookup[categoryId];
      if (found != null) return found;
    }

    // 2) Exact name match
    if (keyword != null && keyword.isNotEmpty) {
      final kw = keyword.toLowerCase();
      for (final cat in allCategories) {
        if (cat.name.toLowerCase() == kw) return cat;
      }
      // 3) Partial name match (fallback)
      for (final cat in allCategories) {
        if (cat.name.toLowerCase().contains(kw) ||
            kw.contains(cat.name.toLowerCase())) {
          return cat;
        }
      }
    }

    return null;
  }

  /// Parse string tipe OCR ke [TransactionTypeEnum].
  ///
  /// Settlement types (debt_payment, loan_collection) di-map ke base type
  /// (debt, loan). Gunakan [_parseOcrDebtLoanKind] untuk detail sub-tipe.
  TransactionTypeEnum _parseOcrType(String rawType) {
    return switch (rawType.toLowerCase()) {
      'income' => TransactionTypeEnum.income,
      'expense' => TransactionTypeEnum.expense,
      'transfer' => TransactionTypeEnum.transfer,
      'debt' => TransactionTypeEnum.debt,
      'debt_payment' => TransactionTypeEnum.debt,
      'loan' => TransactionTypeEnum.loan,
      'loan_collection' => TransactionTypeEnum.loan,
      _ => TransactionTypeEnum.expense, // default fallback
    };
  }

  /// Parse string tipe OCR ke [DebtLoanKindEnum] jika applicable.
  ///
  /// Mengembalikan null untuk tipe non-debt/loan (expense, income, transfer).
  DebtLoanKindEnum? _parseOcrDebtLoanKind(String rawType) {
    return switch (rawType.toLowerCase()) {
      'debt' => DebtLoanKindEnum.debt,
      'loan' => DebtLoanKindEnum.loan,
      'debt_payment' => DebtLoanKindEnum.debtPayment,
      'loan_collection' => DebtLoanKindEnum.loanCollection,
      _ => null,
    };
  }
}
