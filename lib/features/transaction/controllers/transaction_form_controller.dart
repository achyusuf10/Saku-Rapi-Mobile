import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/transaction/models/contact_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_item_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:app_saku_rapi/features/transaction/repositories/transaction_repository.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// ═══════════════ Providers ═══════════════

/// Singleton repo provider.
final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(),
);

/// Form controller provider, auto-disposed saat page ditutup.
final transactionFormControllerProvider =
    StateNotifierProvider.autoDispose<
      TransactionFormController,
      TransactionFormState
    >(
      (ref) => TransactionFormController(
        repository: ref.watch(transactionRepositoryProvider),
      ),
    );

// ═══════════════ State ═══════════════

/// Status form transaksi.
enum TransactionFormStatus { idle, saving, saved, error }

/// Immutable state untuk form transaksi.
///
/// Menyimpan semua field form: type, wallet, amount, items, dsb.
/// Controller memodifikasi via `copyWith`.
class TransactionFormState {
  const TransactionFormState({
    this.status = TransactionFormStatus.idle,
    this.type = TransactionTypeEnum.expense,
    this.wallet,
    this.destinationWallet,
    this.totalAmount = 0,
    this.date,
    this.merchantName,
    this.note,
    this.attachmentUrl,
    this.withPerson,
    this.contact,
    this.dueDate,
    this.category,
    this.items = const [],
    this.itemKeys = const [],
    this.errorMessage,
    this.existingTransaction,
  });

  final TransactionFormStatus status;
  final TransactionTypeEnum type;
  final WalletModel? wallet;
  final WalletModel? destinationWallet;
  final double totalAmount;
  final DateTime? date;
  final String? merchantName;
  final String? note;
  final String? attachmentUrl;
  final String? withPerson;
  final ContactModel? contact;
  final DateTime? dueDate;
  final CategoryModel? category;
  final List<TransactionItemModel> items;

  /// Stable identity keys per item untuk widget keying.
  /// Setiap item punya key unik yang tidak berubah saat content berubah.
  final List<int> itemKeys;
  final String? errorMessage;

  /// Jika ada, berarti mode edit.
  final TransactionModel? existingTransaction;

  bool get isEditing => existingTransaction != null;
  bool get isSaving => status == TransactionFormStatus.saving;
  bool get isMultiItem => items.length > 1;

  /// Hitung total dari items.
  double get itemsTotal => items.fold(0.0, (sum, i) => sum + i.amount);

  /// Apakah items total cocok dengan total amount.
  bool get isTotalMatched => (itemsTotal - totalAmount).abs() < 0.01;

  TransactionFormState copyWith({
    TransactionFormStatus? status,
    TransactionTypeEnum? type,
    WalletModel? wallet,
    WalletModel? destinationWallet,
    double? totalAmount,
    DateTime? date,
    String? merchantName,
    String? note,
    String? attachmentUrl,
    String? withPerson,
    ContactModel? contact,
    DateTime? dueDate,
    CategoryModel? category,
    List<TransactionItemModel>? items,
    List<int>? itemKeys,
    String? errorMessage,
    TransactionModel? existingTransaction,
  }) {
    return TransactionFormState(
      status: status ?? this.status,
      type: type ?? this.type,
      wallet: wallet ?? this.wallet,
      destinationWallet: destinationWallet ?? this.destinationWallet,
      totalAmount: totalAmount ?? this.totalAmount,
      date: date ?? this.date,
      merchantName: merchantName ?? this.merchantName,
      note: note ?? this.note,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      withPerson: withPerson ?? this.withPerson,
      contact: contact ?? this.contact,
      dueDate: dueDate ?? this.dueDate,
      category: category ?? this.category,
      items: items ?? this.items,
      itemKeys: itemKeys ?? this.itemKeys,
      errorMessage: errorMessage ?? this.errorMessage,
      existingTransaction: existingTransaction ?? this.existingTransaction,
    );
  }

  /// Create fresh copy with nullable fields explicitly cleared.
  TransactionFormState clearFields({
    bool clearDestWallet = false,
    bool clearWithPerson = false,
    bool clearContact = false,
    bool clearDueDate = false,
    bool clearCategory = false,
    bool clearMerchant = false,
    bool clearNote = false,
    bool clearAttachment = false,
    bool clearError = false,
  }) {
    return TransactionFormState(
      status: status,
      type: type,
      wallet: wallet,
      destinationWallet: clearDestWallet ? null : destinationWallet,
      totalAmount: totalAmount,
      date: date,
      merchantName: clearMerchant ? null : merchantName,
      note: clearNote ? null : note,
      attachmentUrl: clearAttachment ? null : attachmentUrl,
      withPerson: clearWithPerson ? null : withPerson,
      contact: clearContact ? null : contact,
      dueDate: clearDueDate ? null : dueDate,
      category: clearCategory ? null : category,
      items: clearCategory
          ? items.map((item) => item.clearCategory()).toList()
          : items,
      itemKeys: itemKeys,
      errorMessage: clearError ? null : errorMessage,
      existingTransaction: existingTransaction,
    );
  }
}

// ═══════════════ Controller ═══════════════

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

  // ─── Setters ───

  void setType(TransactionTypeEnum type) {
    // Saat ganti type, clear field yang tidak relevan
    state = state
        .copyWith(type: type)
        .clearFields(
          clearDestWallet: !type.requiresDestinationWallet,
          clearWithPerson: !type.requiresWithPerson,
          clearContact: !type.requiresWithPerson,
          clearDueDate: !type.requiresWithPerson,
          clearCategory: true,
          clearError: true,
        );
  }

  void setWallet(WalletModel wallet) {
    state = state.copyWith(wallet: wallet).clearFields(clearError: true);
  }

  void setDestinationWallet(WalletModel wallet) {
    state = state
        .copyWith(destinationWallet: wallet)
        .clearFields(clearError: true);
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
    state = state.copyWith(category: category);
    // Jika single item, update category di item juga
    if (state.items.length == 1) {
      state = state.copyWith(
        items: [
          state.items.first.copyWith(
            categoryId: category.id,
            categoryName: category.name,
            categoryIcon: category.icon,
            categoryColor: category.color,
          ),
        ],
      );
    }
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
    final newItems = [
      ...state.items,
      TransactionItemModel(amount: 0, sortOrder: state.items.length),
    ];
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
    final resolved = _resolveItemAmount(item);

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
  }

  /// Prefill items dari Voice/OCR input.
  ///
  /// Mengganti seluruh items dan auto-recalc total.
  void prefillItems(List<TransactionItemModel> items) {
    if (items.isEmpty) return;
    final resolved = items.map(_resolveItemAmount).toList();
    final total = _sumItems(resolved);
    final keys = List.generate(resolved.length, (_) => _generateKey());
    state = state.copyWith(items: resolved, itemKeys: keys, totalAmount: total);
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
  void loadExistingTransaction(TransactionModel txn) {
    final items = txn.items.isNotEmpty
        ? txn.items
        : [TransactionItemModel(amount: txn.totalAmount)];
    final keys = List.generate(items.length, (_) => _generateKey());
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
    );
    // Wallet and category are loaded separately via widget
  }

  // ─── Submit ───

  /// Submit transaksi (create atau update). Anti duplicate-submit via status.
  Future<DataState<Map<String, dynamic>>> submit() async {
    if (state.isSaving) {
      return const DataState.error(message: 'Sedang menyimpan...');
    }

    state = state.copyWith(status: TransactionFormStatus.saving);

    try {
      // Pastikan items memiliki sortOrder yang benar
      final itemsWithOrder = state.items
          .asMap()
          .entries
          .map((e) => e.value.copyWith(sortOrder: e.key))
          .toList();

      DataState<Map<String, dynamic>> result;

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
