import 'package:app_saku_rapi/core/enums/debt_loan_kind_enum.dart';
import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/debt_loan/models/debt_loan_transaction_model.dart';
import 'package:app_saku_rapi/features/transaction/controllers/transaction_form_multi_manual_coordinator.dart';
import 'package:app_saku_rapi/features/transaction/controllers/transaction_form_state.dart';
import 'package:app_saku_rapi/features/transaction/models/contact_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_item_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:app_saku_rapi/features/transaction/repositories/transaction_repository.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// Re-export state agar file lain yang mengimport controller ini
// tetap dapat mengakses TransactionFormState & TransactionFormStatus
// tanpa perlu ganti path import.
export 'transaction_form_state.dart';

// ═══════════════════════════════════════════════
//  Providers
// ═══════════════════════════════════════════════

/// Provider singleton untuk [TransactionRepository].
final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(),
);

/// Provider controller form transaksi, auto-disposed saat halaman ditutup.
///
/// Gunakan `ref.watch(transactionFormControllerProvider)` untuk membaca state.
/// Gunakan `ref.read(transactionFormControllerProvider.notifier)` untuk mutasi.
final transactionFormControllerProvider =
    StateNotifierProvider.autoDispose<
      TransactionFormController,
      TransactionFormState
    >(
      (ref) => TransactionFormController(
        repository: ref.watch(transactionRepositoryProvider),
      ),
    );

// ═══════════════════════════════════════════════
//  Controller
// ═══════════════════════════════════════════════

/// Controller form transaksi.
///
/// Mengelola semua state form: type selection, wallet/category picker,
/// multi-item management, dan submit create/update/delete.
class TransactionFormController extends StateNotifier<TransactionFormState> {
  TransactionFormController({required TransactionRepository repository})
    : _repository = repository,
      super(TransactionFormState(date: DateTime.now()));

  final TransactionRepository _repository;
  int _nextItemKey = 0;

  int _generateKey() => _nextItemKey++;

  /// Expense/income memakai satu kategori parent untuk semua baris item.
  bool _usesParentCategory() {
    return state.type == TransactionTypeEnum.expense ||
        state.type == TransactionTypeEnum.income;
  }

  /// Terapkan [category] ke setiap elemen [items] (untuk RPC / join kategori).
  List<TransactionItemModel> _itemsWithCategoryApplied(
    CategoryModel category,
    List<TransactionItemModel> items,
  ) {
    return items
        .map(
          (i) => i.copyWith(
            categoryId: category.id,
            categoryName: category.name,
            categoryIcon: category.icon,
            categoryColor: category.color,
          ),
        )
        .toList();
  }

  /// Sinkronkan `state.category` ke semua item (no-op jika tidak relevan).
  void _syncCategoryToAllItems() {
    final cat = state.category;
    if (cat == null || !_usesParentCategory()) return;
    state = state.copyWith(items: _itemsWithCategoryApplied(cat, state.items));
  }

  // ─── Setters ───

  void setType(TransactionTypeEnum type) {
    // Saat ganti type, clear field yang tidak relevan
    final isDebtLoan =
        type == TransactionTypeEnum.debt || type == TransactionTypeEnum.loan;
    state = state
        .copyWith(
          type: type,
          // Default sub-category saat masuk tab Hutang/Piutang
          debtLoanKind: isDebtLoan
              ? (type == TransactionTypeEnum.loan
                    ? DebtLoanKindEnum.loan
                    : DebtLoanKindEnum.debt)
              : null,
        )
        .clearFields(
          clearDestWallet: !type.requiresDestinationWallet,
          clearWithPerson: !type.requiresWithPerson,
          clearContact: !type.requiresWithPerson,
          clearDueDate: !type.requiresWithPerson,
          clearCategory: true,
          clearError: true,
          clearDebtLoanKind: !isDebtLoan,
          clearReferenceTransaction: true,
        )
        .copyWith(isMultiManualMode: false, manualMultiEntries: const []);
  }

  /// Set sub-kategori untuk tab Hutang/Piutang.
  ///
  /// Mengubah type sesuai sub-kategori:
  /// - debt / debtPayment → TransactionTypeEnum.debt
  /// - loan / loanCollection → TransactionTypeEnum.loan
  /// Clear referenceTransaction saat ganti sub-kategori.
  void setDebtLoanKind(DebtLoanKindEnum subCat) {
    final newType =
        (subCat == DebtLoanKindEnum.loan ||
            subCat == DebtLoanKindEnum.loanCollection)
        ? TransactionTypeEnum.loan
        : TransactionTypeEnum.debt;

    state = state
        .copyWith(
          type: newType,
          debtLoanKind: subCat,
          isMultiManualMode: false,
          manualMultiEntries: const [],
        )
        .clearFields(clearReferenceTransaction: true, clearError: true);
  }

  /// Set transaksi referensi untuk mode pelunasan/penerimaan.
  void setReferenceTransaction(DebtLoanTransactionModel? txn) {
    if (txn == null) {
      state = state.clearFields(clearReferenceTransaction: true);
    } else {
      state = state.copyWith(referenceTransaction: txn);
    }
  }

  void setWallet(WalletModel wallet) {
    state = state.copyWith(wallet: wallet).clearFields(clearError: true);
  }

  void setDestinationWallet(WalletModel wallet) {
    state = state
        .copyWith(destinationWallet: wallet)
        .clearFields(clearError: true);
  }

  /// Tukar dompet sumber dan dompet tujuan.
  void swapWallets() {
    final source = state.wallet;
    final dest = state.destinationWallet;
    if (source == null && dest == null) return;
    state = state.copyWith(wallet: dest, destinationWallet: source);
  }

  void setTotalAmount(double amount) {
    state = state.copyWith(totalAmount: amount);
    // Jika single item, juga update item amount agar match
    if (state.items.length == 1) {
      state = state.copyWith(
        items: [state.items.first.copyWith(amount: amount)],
      );
    }
  }

  void setDate(DateTime date) {
    state = state.copyWith(date: date);
  }

  void setMerchant(String? merchant) {
    state = state.copyWith(merchantName: merchant);
  }

  void setNote(String? note) {
    state = state.copyWith(note: note);
  }

  void setAttachmentUrl(String? url) {
    if (url == null) {
      state = state.clearFields(clearAttachment: true);
    } else {
      state = state.copyWith(attachmentUrl: url);
    }
  }

  /// Simpan path lokal lampiran (belum upload).
  void setLocalAttachment(String? path) {
    if (path == null) {
      state = state.clearFields(clearAttachment: true);
    } else {
      // Simpan path lokal, hapus URL lama (akan di-upload saat simpan)
      state = TransactionFormState(
        status: state.status,
        type: state.type,
        wallet: state.wallet,
        destinationWallet: state.destinationWallet,
        totalAmount: state.totalAmount,
        date: state.date,
        merchantName: state.merchantName,
        note: state.note,
        attachmentUrl: null,
        localAttachmentPath: path,
        withPerson: state.withPerson,
        contact: state.contact,
        dueDate: state.dueDate,
        category: state.category,
        items: state.items,
        itemKeys: state.itemKeys,
        errorMessage: state.errorMessage,
        existingTransaction: state.existingTransaction,
        debtLoanKind: state.debtLoanKind,
        referenceTransaction: state.referenceTransaction,
        isMultiManualMode: state.isMultiManualMode,
        manualMultiEntries: state.manualMultiEntries,
      );
    }
  }

  void setWithPerson(String? person) {
    state = state.copyWith(withPerson: person);
  }

  /// Pilih kontak (dari picker sheet). Juga sync withPerson ke nama kontak.
  void setContact(ContactModel? contact) {
    if (contact == null) {
      state = state.clearFields(clearWithPerson: true, clearContact: true);
    } else {
      state = state.copyWith(contact: contact, withPerson: contact.name);
    }
  }

  void setDueDate(DateTime? dueDate) {
    state = state.copyWith(dueDate: dueDate);
  }

  void setCategory(CategoryModel category) {
    final newItems = _usesParentCategory()
        ? _itemsWithCategoryApplied(category, state.items)
        : state.items;
    state = state.copyWith(category: category, items: newItems);
  }

  // ─── Item Management ───

  /// Inisialisasi 1 item default (single-item mode).
  void initSingleItem() {
    if (state.items.isEmpty) {
      state = state.copyWith(
        items: [const TransactionItemModel(amount: 0)],
        itemKeys: [_generateKey()],
      );
    }
  }

  /// Tambah item baru (switch ke multi-item mode).
  void addItem() {
    var newItem = TransactionItemModel(
      amount: 0,
      sortOrder: state.items.length,
    );
    final cat = state.category;
    if (cat != null && _usesParentCategory()) {
      newItem = newItem.copyWith(
        categoryId: cat.id,
        categoryName: cat.name,
        categoryIcon: cat.icon,
        categoryColor: cat.color,
      );
    }
    final newItems = [...state.items, newItem];
    state = state.copyWith(
      items: newItems,
      itemKeys: [...state.itemKeys, _generateKey()],
    );
  }

  /// Update item di index tertentu.
  ///
  /// Jika `qty` dan `unitPrice` keduanya tersedia, `amount = qty * unitPrice`.
  /// Jika hanya `amount` yang diisi manual, tetap pakai amount apa adanya.
  /// Auto-recalc total dari semua items.
  void updateItem(int index, TransactionItemModel item) {
    if (index < 0 || index >= state.items.length) return;

    // Auto-calc amount dari qty * unitPrice jika keduanya ada
    var resolved = _resolveItemAmount(item);
    final cat = state.category;
    if (cat != null && _usesParentCategory()) {
      resolved = resolved.copyWith(
        categoryId: cat.id,
        categoryName: cat.name,
        categoryIcon: cat.icon,
        categoryColor: cat.color,
      );
    }

    final newItems = [...state.items];
    newItems[index] = resolved;

    final total = _sumItems(newItems);
    state = state.copyWith(items: newItems, totalAmount: total);
  }

  /// Hapus item di index tertentu. Minimal 1 item harus tetap ada.
  void removeItem(int index) {
    if (state.items.length <= 1) return;
    final newItems = [...state.items]..removeAt(index);
    final newKeys = [...state.itemKeys]..removeAt(index);
    final total = _sumItems(newItems);
    state = state.copyWith(
      items: newItems,
      itemKeys: newKeys,
      totalAmount: total,
    );
    _syncCategoryToAllItems();
  }

  /// Ubah urutan item (drag-to-reorder).
  void reorderItems(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.items.length) return;
    if (newIndex < 0 || newIndex > state.items.length) return;

    final newItems = [...state.items];
    final item = newItems.removeAt(oldIndex);
    final adjustedIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    newItems.insert(adjustedIndex, item);

    final newKeys = [...state.itemKeys];
    final key = newKeys.removeAt(oldIndex);
    newKeys.insert(adjustedIndex, key);

    state = state.copyWith(items: newItems, itemKeys: newKeys);
    _syncCategoryToAllItems();
  }

  // ─── Multi manual (pengeluaran / pemasukan, mode create) ───

  late final TransactionFormMultiManualCoordinator _multi =
      TransactionFormMultiManualCoordinator(
        read: () => state,
        write: (s) => state = s,
        allocateItemKey: _generateKey,
      );

  void setMultiManualMode(bool enabled) => _multi.setMultiManualMode(enabled);

  bool addManualMultiEntry() => _multi.addManualEntry();

  void removeManualMultiEntry(int index) => _multi.removeManualEntry(index);

  void setManualMultiEntryExpanded(int index, bool expanded) =>
      _multi.setManualEntryExpanded(index, expanded);

  void setManualMultiEntryWallet(int index, WalletModel wallet) =>
      _multi.setManualEntryWallet(index, wallet);

  void setManualMultiEntryCategory(int index, CategoryModel cat) =>
      _multi.setManualEntryCategory(index, cat);

  void setManualMultiEntryDate(int index, DateTime date) =>
      _multi.setManualEntryDate(index, date);

  void setManualMultiEntryTotalAmount(int index, double amount) =>
      _multi.setManualEntryTotalAmount(index, amount);

  void setManualMultiEntryMerchant(int index, String? v) =>
      _multi.setManualEntryMerchant(index, v);

  void setManualMultiEntryNote(int index, String? v) =>
      _multi.setManualEntryNote(index, v);

  void setManualMultiEntryLocalAttachment(int index, String? path) =>
      _multi.setManualEntryLocalAttachment(index, path);

  void setManualMultiEntryAttachmentUrl(int index, String? url) =>
      _multi.setManualEntryAttachmentUrl(index, url);

  void addManualMultiItem(int entryIndex) =>
      _multi.addManualEntryItem(entryIndex);

  void updateManualMultiEntryItem(
    int entryIndex,
    int itemIndex,
    TransactionItemModel item,
  ) => _multi.updateManualEntryItem(entryIndex, itemIndex, item);

  void removeManualMultiEntryItem(int entryIndex, int itemIndex) =>
      _multi.removeManualEntryItem(entryIndex, itemIndex);

  void reorderManualMultiEntryItems(int entryIndex, int oldIndex, int newIndex) =>
      _multi.reorderManualEntryItems(entryIndex, oldIndex, newIndex);

  /// Prefill items dari Voice/OCR input.
  ///
  /// Mengganti seluruh items dan auto-recalc total.
  void prefillItems(List<TransactionItemModel> items) {
    if (items.isEmpty) return;
    final resolved = items.map(_resolveItemAmount).toList();
    final total = _sumItems(resolved);
    final keys = List.generate(resolved.length, (_) => _generateKey());
    state = state.copyWith(items: resolved, itemKeys: keys, totalAmount: total);
    _syncCategoryToAllItems();
  }

  // ─── Helpers ───

  /// Hitung amount dari qty * unitPrice jika keduanya tersedia.
  static TransactionItemModel _resolveItemAmount(TransactionItemModel item) {
    if (item.unitPrice != null && item.qty > 0) {
      final computed = item.qty * item.unitPrice!;
      return item.copyWith(amount: computed);
    }
    return item;
  }

  /// Sum amount dari semua items.
  static double _sumItems(List<TransactionItemModel> items) {
    return items.fold(0.0, (sum, i) => sum + i.amount);
  }

  /// @visibleForTesting — Exposed untuk unit test.
  static TransactionItemModel resolveItemAmountForTest(
    TransactionItemModel item,
  ) => _resolveItemAmount(item);

  /// @visibleForTesting — Exposed untuk unit test.
  static double sumItemsForTest(List<TransactionItemModel> items) =>
      _sumItems(items);

  // ─── Load untuk mode edit ───

  /// Pre-fill form dari transaksi yang sudah ada (mode edit).
  ///
  /// Setelah dipanggil, caller WAJIB memanggil [resolveEditLookups]
  /// untuk mengisi wallet, destinationWallet, dan category dari provider.
  void loadExistingTransaction(TransactionModel txn) {
    final items = txn.items.isNotEmpty
        ? txn.items
        : [TransactionItemModel(amount: txn.totalAmount)];
    final keys = List.generate(items.length, (_) => _generateKey());

    // Tentukan debtLoanKind dari settlement_kind atau base type
    DebtLoanKindEnum? debtLoanKind;
    if (txn.settlementKind != null) {
      debtLoanKind = txn.settlementKind;
    } else if (txn.type == TransactionTypeEnum.debt) {
      debtLoanKind = DebtLoanKindEnum.debt;
    } else if (txn.type == TransactionTypeEnum.loan) {
      debtLoanKind = DebtLoanKindEnum.loan;
    }

    state = TransactionFormState(
      existingTransaction: txn,
      type: txn.type,
      totalAmount: txn.totalAmount,
      date: txn.date,
      merchantName: txn.merchantName,
      note: txn.note,
      attachmentUrl: txn.attachmentUrl,
      withPerson: txn.withPerson,
      contact: txn.contactId != null
          ? ContactModel(
              id: txn.contactId!,
              userId: txn.userId,
              name: txn.contactName ?? txn.withPerson ?? '',
              phone: txn.contactPhone,
            )
          : null,
      dueDate: txn.dueDate,
      items: items,
      itemKeys: keys,
      debtLoanKind: debtLoanKind,
    );
  }

  /// Resolve wallet, destinationWallet, category setelah [loadExistingTransaction].
  ///
  /// Dipanggil dari UI layer yang punya akses ke provider wallet/category.
  void resolveEditLookups({
    WalletModel? wallet,
    WalletModel? destinationWallet,
    CategoryModel? category,
  }) {
    state = state.copyWith(
      wallet: wallet,
      destinationWallet: destinationWallet,
      category: category,
    );
    if (category != null && _usesParentCategory()) {
      state = state.copyWith(
        items: _itemsWithCategoryApplied(category, state.items),
      );
    }
  }

  // ─── Submit ───

  /// Submit transaksi (create, update, atau settle). Anti duplicate-submit via status.
  Future<DataState<Map<String, dynamic>>> submit() async {
    if (state.isSaving) {
      return const DataState.error(message: 'Sedang menyimpan...');
    }

    state = state.copyWith(status: TransactionFormStatus.saving);

    try {
      DataState<Map<String, dynamic>> result;

      // ── Settlement mode (Pelunasan / Penerimaan) ──
      if (state.isSettlementMode) {
        result = await _repository.settleDebtOrLoan(
          referenceTransactionId: state.referenceTransaction!.id,
          settlementKind: state.debtLoanKind!.toDbValue(),
          amount: state.totalAmount,
          walletId: state.wallet!.id,
          date: state.date,
          note: state.note,
        );
      } else if (!state.isEditing &&
          state.isMultiManualMode &&
          (state.type == TransactionTypeEnum.expense ||
              state.type == TransactionTypeEnum.income)) {
        final err = TransactionFormMultiManualCoordinator.validateBatch(
          state,
          state.type,
        );
        if (err != null) {
          state = state.copyWith(
            status: TransactionFormStatus.error,
            errorMessage: err,
          );
          result = DataState.error(message: err);
        } else {
          result = await _repository.createTransactionsBatch(
            type: state.type,
            entries: state.manualMultiEntries,
          );
          if (result.isSuccess()) {
            state = state.copyWith(status: TransactionFormStatus.saved);
          } else {
            final (message, _, _, _) = result.dataError()!;
            state = state.copyWith(
              status: TransactionFormStatus.error,
              errorMessage: message,
            );
          }
        }
      } else {
        _syncCategoryToAllItems();
        // Pastikan items memiliki sortOrder yang benar
        final itemsWithOrder = state.items
            .asMap()
            .entries
            .map((e) => e.value.copyWith(sortOrder: e.key))
            .toList();

        if (state.isEditing) {
          result = await _repository.updateTransaction(
            transactionId: state.existingTransaction!.id,
            walletId: state.wallet!.id,
            destinationWalletId: state.destinationWallet?.id,
            type: state.type,
            totalAmount: state.totalAmount,
            date: state.date ?? DateTime.now(),
            merchantName: state.merchantName,
            note: state.note,
            attachmentUrl: state.attachmentUrl,
            withPerson: state.withPerson,
            contactId: state.contact?.id,
            debtStatus: state.type.requiresWithPerson ? 'unpaid' : null,
            dueDate: state.dueDate,
            items: itemsWithOrder,
          );
        } else {
          result = await _repository.createTransaction(
            walletId: state.wallet!.id,
            destinationWalletId: state.destinationWallet?.id,
            type: state.type,
            totalAmount: state.totalAmount,
            date: state.date ?? DateTime.now(),
            merchantName: state.merchantName,
            note: state.note,
            attachmentUrl: state.attachmentUrl,
            withPerson: state.withPerson,
            contactId: state.contact?.id,
            debtStatus: state.type.requiresWithPerson ? 'unpaid' : null,
            dueDate: state.dueDate,
            items: itemsWithOrder,
          );
        }
      }

      if (result.isSuccess()) {
        state = state.copyWith(status: TransactionFormStatus.saved);
      } else {
        final (message, _, _, _) = result.dataError()!;
        state = state.copyWith(
          status: TransactionFormStatus.error,
          errorMessage: message,
        );
      }

      return result;
    } catch (e) {
      state = state.copyWith(
        status: TransactionFormStatus.error,
        errorMessage: e.toString(),
      );
      return DataState.error(message: e.toString());
    }
  }

  /// Delete transaksi yang sedang diedit.
  Future<DataState<Map<String, dynamic>>> delete() async {
    if (!state.isEditing) {
      return const DataState.error(
        message: 'Tidak ada transaksi untuk dihapus',
      );
    }

    if (state.isSaving) {
      return const DataState.error(message: 'Sedang memproses...');
    }

    state = state.copyWith(status: TransactionFormStatus.saving);

    try {
      final result = await _repository.deleteTransaction(
        state.existingTransaction!.id,
      );

      if (result.isSuccess()) {
        state = state.copyWith(status: TransactionFormStatus.saved);
      } else {
        final (message, _, _, _) = result.dataError()!;
        state = state.copyWith(
          status: TransactionFormStatus.error,
          errorMessage: message,
        );
      }

      return result;
    } catch (e) {
      state = state.copyWith(
        status: TransactionFormStatus.error,
        errorMessage: e.toString(),
      );
      return DataState.error(message: e.toString());
    }
  }
}
