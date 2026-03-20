import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/transaction/datasource/transaction_local_datasource.dart';
import 'package:app_saku_rapi/features/transaction/datasource/transaction_remote_datasource.dart';
import 'package:app_saku_rapi/features/transaction/models/category_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_form_state.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:app_saku_rapi/features/transaction/repositories/transaction_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────

/// Provider untuk [TransactionRepository].
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(
    remoteDataSource: TransactionRemoteDataSource(),
    localDataSource: TransactionLocalDataSource(),
  );
});

/// Provider untuk state form transaksi.
///
/// State direset setiap kali screen form ditutup (auto-dispose by default di
/// Riverpod 3).
final transactionFormControllerProvider =
    NotifierProvider<TransactionFormController, TransactionFormState>(
      () => TransactionFormController(),
    );

/// Provider untuk daftar kategori yang sudah dikelompokkan (parent + children).
///
/// Di-cache dengan autoDispose agar tidak terus hidup setelah form tutup.
final transactionCategoriesProvider = FutureProvider<List<CategoryModel>>((
  ref,
) async {
  final repo = ref.read(transactionRepositoryProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
  final result = await repo.getCategories(userId: userId);
  return result.map(
    success: (data) => data.data,
    error: (err) => throw Exception(err.message),
  );
});

// ─────────────────────────────────────────────────────────────
// Controller
// ─────────────────────────────────────────────────────────────

/// Riverpod [Notifier] untuk mengelola state form transaksi.
///
/// State direset otomatis saat form screen ditutup (auto-dispose default di
/// Riverpod 3).
class TransactionFormController extends Notifier<TransactionFormState> {
  static const String _tag = 'TransactionForm';

  @override
  TransactionFormState build() {
    return TransactionFormState(date: DateTime.now());
  }

  // ─────────────────────────────────────────────────────────────
  // Initialization
  // ─────────────────────────────────────────────────────────────

  /// Inisialisasi form dari state awal (pre-fill dari Voice/OCR atau edit).
  void initialize(TransactionFormState initialState) {
    state = initialState;
    AppLogger.call(
      '[$_tag] Form diinisialisasi: type=${initialState.type}, '
      'prefillSource=${initialState.prefillSource}',
      colorLog: ColorLog.blue,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Type
  // ─────────────────────────────────────────────────────────────

  /// Ubah tipe transaksi.
  ///
  /// Saat berganti tipe, item non-compatible (multi-item untuk non-expense)
  /// direset menjadi 1 item kosong.
  void setType(String type) {
    final resetItems = type != 'expense' && state.items.length > 1;
    state = state.copyWith(
      type: type,
      items: resetItems ? [const TransactionItemFormState()] : null,
      clearDestinationWallet: type != 'transfer',
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Wallet
  // ─────────────────────────────────────────────────────────────

  /// Set dompet sumber transaksi.
  void setWallet(String walletId, String walletName) {
    state = state.copyWith(walletId: walletId, walletName: walletName);
  }

  /// Set dompet tujuan (untuk transfer).
  void setDestinationWallet(String? walletId, String? walletName) {
    if (walletId == null) {
      state = state.copyWith(clearDestinationWallet: true);
    } else {
      state = state.copyWith(
        destinationWalletId: walletId,
        destinationWalletName: walletName,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Date
  // ─────────────────────────────────────────────────────────────

  /// Set tanggal transaksi.
  void setDate(DateTime date) {
    state = state.copyWith(date: date);
  }

  // ─────────────────────────────────────────────────────────────
  // Optional fields
  // ─────────────────────────────────────────────────────────────

  void setMerchantName(String? name) {
    if (name == null || name.trim().isEmpty) {
      state = state.copyWith(clearMerchantName: true);
    } else {
      state = state.copyWith(merchantName: name.trim());
    }
  }

  void setNote(String? note) {
    if (note == null || note.trim().isEmpty) {
      state = state.copyWith(clearNote: true);
    } else {
      state = state.copyWith(note: note.trim());
    }
  }

  void setAttachmentLocalPath(String? path) {
    if (path == null) {
      state = state.copyWith(clearAttachment: true);
    } else {
      state = state.copyWith(attachmentLocalPath: path);
    }
  }

  void setWithPerson(String? withPerson) {
    if (withPerson == null || withPerson.trim().isEmpty) {
      state = state.copyWith(clearWithPerson: true);
    } else {
      state = state.copyWith(withPerson: withPerson.trim());
    }
  }

  void setStatus(String? status) {
    state = state.copyWith(status: status);
  }

  void setDueDate(DateTime? dueDate) {
    if (dueDate == null) {
      state = state.copyWith(clearDueDate: true);
    } else {
      state = state.copyWith(dueDate: dueDate);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Single-item helpers
  // ─────────────────────────────────────────────────────────────

  /// Set nominal item pertama (mode single-item).
  void setAmount(double? amount) {
    _updateItem(0, state.items.first.copyWith(amount: amount));
  }

  /// Set kategori item pertama (mode single-item).
  void setCategory({
    required String? categoryId,
    required String? categoryName,
    required String? categoryColor,
    required String? categoryIcon,
  }) {
    if (categoryId == null) {
      _updateItem(0, state.items.first.copyWith(clearCategory: true));
    } else {
      _updateItem(
        0,
        state.items.first.copyWith(
          categoryId: categoryId,
          categoryName: categoryName,
          categoryColor: categoryColor,
          categoryIcon: categoryIcon,
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Multi-item operations
  // ─────────────────────────────────────────────────────────────

  /// Tambah item baru (kosong) — otomatis switch ke mode multi-item.
  void addItem() {
    state = state.copyWith(
      items: [...state.items, const TransactionItemFormState()],
    );
  }

  /// Hapus item berdasarkan index.
  ///
  /// Minimal selalu ada 1 item — tidak bisa menghapus jika hanya tersisa 1.
  void removeItem(int index) {
    if (state.items.length <= 1) return;
    final updated = List<TransactionItemFormState>.from(state.items)
      ..removeAt(index);
    state = state.copyWith(items: updated);
  }

  /// Update nominal item berdasarkan index.
  void updateItemAmount(int index, double? amount) {
    _updateItem(index, state.items[index].copyWith(amount: amount));
  }

  /// Update kategori item berdasarkan index.
  void updateItemCategory(
    int index, {
    required String? categoryId,
    required String? categoryName,
    required String? categoryColor,
    required String? categoryIcon,
  }) {
    if (categoryId == null) {
      _updateItem(index, state.items[index].copyWith(clearCategory: true));
    } else {
      _updateItem(
        index,
        state.items[index].copyWith(
          categoryId: categoryId,
          categoryName: categoryName,
          categoryColor: categoryColor,
          categoryIcon: categoryIcon,
        ),
      );
    }
  }

  /// Update catatan item berdasarkan index.
  void updateItemNote(int index, String? note) {
    _updateItem(index, state.items[index].copyWith(note: note));
  }

  // ─────────────────────────────────────────────────────────────
  // Save
  // ─────────────────────────────────────────────────────────────

  /// Menyimpan transaksi ke Supabase.
  ///
  /// Return [DataState<TransactionModel>] agar caller (UI) bisa
  /// menentukan aksi lanjutan (pop, snackbar, dll).
  Future<DataState<TransactionModel>> save() async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final repo = ref.read(transactionRepositoryProvider);

    AppLogger.call(
      '[$_tag] Menyimpan form: type=${state.type}, '
      'total=${state.totalAmount}, items=${state.items.length}',
      colorLog: ColorLog.blue,
    );

    return repo.saveTransaction(formState: state, userId: userId);
  }

  // ─────────────────────────────────────────────────────────────
  // Validation
  // ─────────────────────────────────────────────────────────────

  /// Validasi form sebelum submit.
  ///
  /// Return pesan error atau `null` jika valid.
  String? validate() {
    if (state.walletId == null) return 'walletRequired';
    if (state.type == 'transfer' && state.destinationWalletId == null) {
      return 'destWalletRequired';
    }
    if (state.type == 'transfer' &&
        state.walletId == state.destinationWalletId) {
      return 'sameWallet';
    }
    if (state.isDebtOrLoan && (state.withPerson?.isEmpty ?? true)) {
      return 'withPersonRequired';
    }
    for (final item in state.items) {
      if (item.amount == null || item.amount! <= 0) return 'amountRequired';
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────
  // Internal helpers
  // ─────────────────────────────────────────────────────────────

  void _updateItem(int index, TransactionItemFormState updated) {
    final items = List<TransactionItemFormState>.from(state.items);
    items[index] = updated;
    state = state.copyWith(items: items);
  }
}
