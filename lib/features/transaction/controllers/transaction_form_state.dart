import 'package:app_saku_rapi/core/enums/debt_loan_kind_enum.dart';
import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/debt_loan/models/debt_loan_transaction_model.dart';
import 'package:app_saku_rapi/features/transaction/models/contact_model.dart';
import 'package:app_saku_rapi/features/transaction/models/manual_transaction_entry_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_item_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';

// ═══════════════════════════════════════════════
//  Status Enum
// ═══════════════════════════════════════════════

/// Status proses penyimpanan pada form transaksi.
///
/// - [idle]   : belum ada aksi simpan.
/// - [saving] : sedang mengirim ke backend (anti double-submit).
/// - [saved]  : berhasil disimpan.
/// - [error]  : terjadi error saat menyimpan.
enum TransactionFormStatus { idle, saving, saved, error }

// ═══════════════════════════════════════════════
//  State
// ═══════════════════════════════════════════════

/// Immutable state untuk form transaksi.
///
/// Menyimpan semua nilai field form: type, wallet, amount, items, dsb.
/// Dimodifikasi oleh [TransactionFormController] lewat [copyWith]
/// atau [clearFields] — tidak pernah dimutasi langsung.
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
    this.localAttachmentPath,
    this.withPerson,
    this.contact,
    this.dueDate,
    this.category,
    this.items = const [],
    this.itemKeys = const [],
    this.errorMessage,
    this.existingTransaction,
    this.debtLoanKind,
    this.referenceTransaction,
    this.isMultiManualMode = false,
    this.manualMultiEntries = const [],
  });

  // ─── Persisted fields ───

  /// Status proses form saat ini.
  final TransactionFormStatus status;

  /// Tipe transaksi yang sedang dipilih (expense, income, transfer, debt, loan).
  final TransactionTypeEnum type;

  /// Dompet sumber / dompet utama transaksi.
  final WalletModel? wallet;

  /// Dompet tujuan — hanya relevan untuk tipe transfer.
  final WalletModel? destinationWallet;

  /// Jumlah total transaksi (sama dengan sum items).
  final double totalAmount;

  /// Tanggal transaksi yang dipilih user.
  final DateTime? date;

  /// Nama merchant / toko (opsional).
  final String? merchantName;

  /// Catatan bebas (opsional).
  final String? note;

  /// URL lampiran yang sudah di-upload ke Supabase Storage.
  final String? attachmentUrl;

  /// Path lokal file lampiran yang belum di-upload.
  /// Diisi saat user memilih foto; di-upload secara lazy saat simpan.
  final String? localAttachmentPath;

  /// Nama orang terkait (hutang / piutang).
  final String? withPerson;

  /// Kontak yang dipilih dari phone book (hutang / piutang).
  final ContactModel? contact;

  /// Tanggal jatuh tempo (hutang / piutang, opsional).
  final DateTime? dueDate;

  /// Kategori transaksi — satu untuk seluruh baris item (expense / income).
  final CategoryModel? category;

  /// Daftar baris item transaksi (minimal 1 baris).
  final List<TransactionItemModel> items;

  /// Stable identity keys per item untuk widget [Key] assignment.
  /// Key tidak berubah saat konten item berubah, sehingga rebuild lebih efisien.
  final List<int> itemKeys;

  /// Pesan error terakhir dari backend (jika ada).
  final String? errorMessage;

  /// Data transaksi yang sedang di-edit. Null berarti mode create baru.
  final TransactionModel? existingTransaction;

  /// Jenis operasi Hutang/Piutang: debt, loan, debtPayment, loanCollection.
  final DebtLoanKindEnum? debtLoanKind;

  /// Transaksi referensi untuk mode pelunasan hutang / penerimaan piutang.
  final DebtLoanTransactionModel? referenceTransaction;

  /// Mode **Multi Transaksi** (hanya create + expense/income).
  final bool isMultiManualMode;

  /// Daftar transaksi saat [isMultiManualMode] aktif.
  final List<ManualTransactionEntryModel> manualMultiEntries;

  // ─── Computed getters ───

  /// True jika form sedang dalam mode edit (bukan create baru).
  bool get isEditing => existingTransaction != null;

  /// True jika sedang dalam proses penyimpanan (gunakan untuk disable tombol).
  bool get isSaving => status == TransactionFormStatus.saving;

  /// True jika ada lebih dari 1 baris item (mode multi-item aktif).
  bool get isMultiItem => items.length > 1;

  /// True jika tab aktif adalah Hutang atau Piutang.
  bool get isDebtLoanTab =>
      type == TransactionTypeEnum.debt || type == TransactionTypeEnum.loan;

  /// True jika sedang mode pelunasan hutang / penerimaan piutang.
  bool get isSettlementMode => debtLoanKind?.isSettlement ?? false;

  /// Total yang dihitung dari sum amount seluruh items.
  double get itemsTotal => items.fold(0.0, (sum, i) => sum + i.amount);

  /// True jika itemsTotal cocok dengan totalAmount (toleransi ±0.01).
  bool get isTotalMatched => (itemsTotal - totalAmount).abs() < 0.01;

  /// Multi-item salah satu entry manual belum cocok totalnya.
  bool get multiManualSaveBlocked {
    if (!isMultiManualMode) return false;
    return manualMultiEntries.any((e) => e.isMultiItem && !e.isTotalMatched);
  }

  // ─── copyWith ───

  /// Buat salinan state dengan field tertentu diubah.
  /// Field yang tidak disebutkan tetap menggunakan nilai lama.
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
    String? localAttachmentPath,
    String? withPerson,
    ContactModel? contact,
    DateTime? dueDate,
    CategoryModel? category,
    List<TransactionItemModel>? items,
    List<int>? itemKeys,
    String? errorMessage,
    TransactionModel? existingTransaction,
    DebtLoanKindEnum? debtLoanKind,
    DebtLoanTransactionModel? referenceTransaction,
    bool? isMultiManualMode,
    List<ManualTransactionEntryModel>? manualMultiEntries,
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
      localAttachmentPath: localAttachmentPath ?? this.localAttachmentPath,
      withPerson: withPerson ?? this.withPerson,
      contact: contact ?? this.contact,
      dueDate: dueDate ?? this.dueDate,
      category: category ?? this.category,
      items: items ?? this.items,
      itemKeys: itemKeys ?? this.itemKeys,
      errorMessage: errorMessage ?? this.errorMessage,
      existingTransaction: existingTransaction ?? this.existingTransaction,
      debtLoanKind: debtLoanKind ?? this.debtLoanKind,
      referenceTransaction: referenceTransaction ?? this.referenceTransaction,
      isMultiManualMode: isMultiManualMode ?? this.isMultiManualMode,
      manualMultiEntries: manualMultiEntries ?? this.manualMultiEntries,
    );
  }

  // ─── clearFields ───

  /// Buat salinan state dengan field nullable tertentu dikosongkan (null).
  ///
  /// Dipanggil saat ganti tipe transaksi agar field yang tidak relevan
  /// untuk tipe baru otomatis terhapus.
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
    bool clearDebtLoanKind = false,
    bool clearReferenceTransaction = false,
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
      localAttachmentPath: clearAttachment ? null : localAttachmentPath,
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
      debtLoanKind: clearDebtLoanKind ? null : debtLoanKind,
      referenceTransaction: clearReferenceTransaction
          ? null
          : referenceTransaction,
      isMultiManualMode: isMultiManualMode,
      manualMultiEntries: manualMultiEntries,
    );
  }
}
