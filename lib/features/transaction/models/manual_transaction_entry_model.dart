import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_item_model.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';

/// Satu baris transaksi dalam mode **Multi Transaksi** (input manual).
///
/// Struktur meniru slice form tunggal: dompet, kategori, tanggal, item,
/// merchant, catatan, lampiran. [totalAmount] selalu selaras jumlah item.
class ManualTransactionEntryModel {
  const ManualTransactionEntryModel({
    required this.entryKey,
    this.expanded = true,
    this.wallet,
    this.category,
    this.items = const [],
    this.itemKeys = const [],
    this.date,
    this.merchantName,
    this.note,
    this.attachmentUrl,
    this.localAttachmentPath,
    this.totalAmount = 0,
  });

  final int entryKey;
  final bool expanded;
  final WalletModel? wallet;
  final CategoryModel? category;
  final List<TransactionItemModel> items;
  final List<int> itemKeys;
  final DateTime? date;
  final String? merchantName;
  final String? note;
  final String? attachmentUrl;
  final String? localAttachmentPath;
  final double totalAmount;

  bool get isMultiItem => items.length > 1;

  double get itemsTotal => items.fold(0.0, (s, i) => s + i.amount);

  bool get isTotalMatched => (itemsTotal - totalAmount).abs() < 0.01;

  /// Entry kosong: satu item nol, tanggal default.
  factory ManualTransactionEntryModel.fresh({
    required int entryKey,
    required DateTime defaultDate,
    required int Function() allocateItemKey,
  }) {
    return ManualTransactionEntryModel(
      entryKey: entryKey,
      date: defaultDate,
      items: const [TransactionItemModel(amount: 0)],
      itemKeys: [allocateItemKey()],
    );
  }

  ManualTransactionEntryModel copyWith({
    bool? expanded,
    WalletModel? wallet,
    CategoryModel? category,
    List<TransactionItemModel>? items,
    List<int>? itemKeys,
    DateTime? date,
    String? merchantName,
    String? note,
    String? attachmentUrl,
    String? localAttachmentPath,
    double? totalAmount,
    bool clearAttachment = false,
    bool clearCategory = false,
    bool clearMerchant = false,
    bool clearNote = false,
  }) {
    return ManualTransactionEntryModel(
      entryKey: entryKey,
      expanded: expanded ?? this.expanded,
      wallet: wallet ?? this.wallet,
      category: clearCategory ? null : (category ?? this.category),
      items: items ?? this.items,
      itemKeys: itemKeys ?? this.itemKeys,
      date: date ?? this.date,
      merchantName: clearMerchant ? null : (merchantName ?? this.merchantName),
      note: clearNote ? null : (note ?? this.note),
      attachmentUrl: clearAttachment
          ? null
          : (attachmentUrl ?? this.attachmentUrl),
      localAttachmentPath: clearAttachment
          ? null
          : (localAttachmentPath ?? this.localAttachmentPath),
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }

  List<TransactionItemModel> itemsWithCategory(CategoryModel cat) {
    return items
        .map(
          (i) => i.copyWith(
            categoryId: cat.id,
            categoryName: cat.name,
            categoryIcon: cat.icon,
            categoryColor: cat.color,
          ),
        )
        .toList();
  }

  static TransactionItemModel resolveItemAmount(TransactionItemModel item) {
    if (item.unitPrice != null && item.qty > 0) {
      return item.copyWith(amount: item.qty * item.unitPrice!);
    }
    return item;
  }

  static double sumItems(List<TransactionItemModel> items) {
    return items.fold(0.0, (s, i) => s + i.amount);
  }

  /// Lampiran: set URL (upload selesai) atau file lokal; saling eksklusif.
  ManualTransactionEntryModel withAttachmentFields({
    String? attachmentUrl,
    String? localAttachmentPath,
  }) {
    return ManualTransactionEntryModel(
      entryKey: entryKey,
      expanded: expanded,
      wallet: wallet,
      category: category,
      items: items,
      itemKeys: itemKeys,
      date: date,
      merchantName: merchantName,
      note: note,
      attachmentUrl: attachmentUrl,
      localAttachmentPath: localAttachmentPath,
      totalAmount: totalAmount,
    );
  }
}
