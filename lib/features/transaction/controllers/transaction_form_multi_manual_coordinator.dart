import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/transaction/controllers/transaction_form_state.dart';
import 'package:app_saku_rapi/features/transaction/models/manual_transaction_entry_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_item_model.dart';
import 'package:app_saku_rapi/features/transaction/utils/manual_multi_batch_limits.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';

/// Mengorkestrasi state **Multi Transaksi** pada form manual (expense/income).
///
/// Dipisah dari [TransactionFormController] agar file tidak membesar dan
/// tanggung jawab tetap fokus (SRP).
class TransactionFormMultiManualCoordinator {
  /// Batas transaksi per satu simpanan batch (client + server).
  static int get maxManualEntries => kManualMultiBatchMaxTransactions;

  TransactionFormMultiManualCoordinator({
    required this.read,
    required this.write,
    required this.allocateItemKey,
  });

  final TransactionFormState Function() read;
  final void Function(TransactionFormState) write;
  final int Function() allocateItemKey;

  int _nextEntryKey = 0;

  int _allocEntryKey() => _nextEntryKey++;

  ManualTransactionEntryModel _cloneFromFlat(
    TransactionFormState s,
    int entryKey,
  ) {
    final items = s.items.isEmpty
        ? [const TransactionItemModel(amount: 0)]
        : List<TransactionItemModel>.from(s.items);
    final keys = s.itemKeys.length == items.length
        ? List<int>.from(s.itemKeys)
        : List<int>.generate(items.length, (_) => allocateItemKey());
    return ManualTransactionEntryModel(
      entryKey: entryKey,
      wallet: s.wallet,
      category: s.category,
      items: items,
      itemKeys: keys,
      date: s.date,
      merchantName: s.merchantName,
      note: s.note,
      attachmentUrl: s.attachmentUrl,
      localAttachmentPath: s.localAttachmentPath,
      totalAmount: s.totalAmount,
    );
  }

  List<TransactionItemModel> _withParentCategory(
    CategoryModel cat,
    List<TransactionItemModel> items,
  ) {
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

  void setMultiManualMode(bool enabled) {
    final s = read();
    if (enabled) {
      write(
        s.copyWith(
          isMultiManualMode: true,
          manualMultiEntries: [_cloneFromFlat(s, _allocEntryKey())],
        ),
      );
    } else {
      if (s.manualMultiEntries.isEmpty) {
        write(s.copyWith(isMultiManualMode: false));
        return;
      }
      final first = s.manualMultiEntries.first;
      write(
        s.copyWith(
          isMultiManualMode: false,
          manualMultiEntries: const [],
          wallet: first.wallet,
          category: first.category,
          items: first.items,
          itemKeys: first.itemKeys,
          date: first.date,
          merchantName: first.merchantName,
          note: first.note,
          attachmentUrl: first.attachmentUrl,
          localAttachmentPath: first.localAttachmentPath,
          totalAmount: first.totalAmount,
        ),
      );
    }
  }

  /// Ganti seluruh entri multi manual (mis. prefill dari AI multi-transaksi).
  ///
  /// Mengalokasikan [entryKey] dan [itemKeys] baru agar stabil di UI.
  void prefillMultiManualEntries(List<ManualTransactionEntryModel> templates) {
    if (templates.isEmpty) return;
    final s = read();
    final list = <ManualTransactionEntryModel>[];
    for (final t in templates) {
      final keys = List.generate(t.items.length, (_) => allocateItemKey());
      final resolvedItems =
          t.items.map(ManualTransactionEntryModel.resolveItemAmount).toList();
      final total = ManualTransactionEntryModel.sumItems(resolvedItems);
      list.add(
        ManualTransactionEntryModel(
          entryKey: _allocEntryKey(),
          expanded: t.expanded,
          wallet: t.wallet,
          category: t.category,
          items: resolvedItems,
          itemKeys: keys,
          date: t.date,
          merchantName: t.merchantName,
          note: t.note,
          attachmentUrl: t.attachmentUrl,
          localAttachmentPath: t.localAttachmentPath,
          totalAmount: total,
        ),
      );
    }
    write(
      s.copyWith(
        isMultiManualMode: true,
        manualMultiEntries: list,
        wallet: list.first.wallet,
        category: null,
        items: const [TransactionItemModel(amount: 0)],
        itemKeys: [allocateItemKey()],
        totalAmount: 0,
        merchantName: null,
        note: null,
      ),
    );
  }

  /// `false` jika sudah mencapai [maxManualEntries].
  bool addManualEntry() {
    final s = read();
    if (s.manualMultiEntries.length >= kManualMultiBatchMaxTransactions) {
      return false;
    }
    final def = s.date ?? DateTime.now();
    final fresh = ManualTransactionEntryModel.fresh(
      entryKey: _allocEntryKey(),
      defaultDate: def,
      allocateItemKey: allocateItemKey,
    );
    write(s.copyWith(manualMultiEntries: [...s.manualMultiEntries, fresh]));
    return true;
  }

  void removeManualEntry(int index) {
    final s = read();
    if (index < 0 || index >= s.manualMultiEntries.length) return;
    if (s.manualMultiEntries.length <= 1) return;
    final next = [...s.manualMultiEntries]..removeAt(index);
    write(s.copyWith(manualMultiEntries: next));
  }

  void setManualEntryExpanded(int index, bool expanded) {
    _replaceEntry(index, (e) => e.copyWith(expanded: expanded));
  }

  void setManualEntryWallet(int index, WalletModel wallet) {
    _replaceEntry(index, (e) => e.copyWith(wallet: wallet));
  }

  void setManualEntryCategory(int index, CategoryModel cat) {
    _replaceEntry(
      index,
      (e) =>
          e.copyWith(category: cat, items: _withParentCategory(cat, e.items)),
    );
  }

  void setManualEntryDate(int index, DateTime date) {
    _replaceEntry(index, (e) => e.copyWith(date: date));
  }

  /// Nominal transaksi saat entry **bukan** multi-item (satu baris item).
  /// Selaras dengan [TransactionFormController.setTotalAmount] pada form tunggal.
  void setManualEntryTotalAmount(int index, double amount) {
    final s = read();
    if (index < 0 || index >= s.manualMultiEntries.length) return;
    final e = s.manualMultiEntries[index];
    if (e.items.length != 1) return;
    final first = e.items.first;
    final list = [...s.manualMultiEntries];
    list[index] = e.copyWith(
      items: [first.copyWith(amount: amount)],
      totalAmount: amount,
    );
    write(s.copyWith(manualMultiEntries: list));
  }

  void setManualEntryMerchant(int index, String? v) {
    final empty = v == null || v.isEmpty;
    _replaceEntry(
      index,
      (e) => e.copyWith(
        merchantName: empty ? null : v,
        clearMerchant: empty,
      ),
    );
  }

  void setManualEntryNote(int index, String? v) {
    final empty = v == null || v.isEmpty;
    _replaceEntry(
      index,
      (e) => e.copyWith(
        note: empty ? null : v,
        clearNote: empty,
      ),
    );
  }

  void setManualEntryLocalAttachment(int index, String? path) {
    if (path == null) {
      _replaceEntry(index, (e) => e.copyWith(clearAttachment: true));
    } else {
      _replaceEntry(
        index,
        (e) => e.withAttachmentFields(
          attachmentUrl: null,
          localAttachmentPath: path,
        ),
      );
    }
  }

  void setManualEntryAttachmentUrl(int index, String? url) {
    if (url == null) {
      _replaceEntry(index, (e) => e.copyWith(clearAttachment: true));
    } else {
      _replaceEntry(
        index,
        (e) => e.withAttachmentFields(
          attachmentUrl: url,
          localAttachmentPath: null,
        ),
      );
    }
  }

  void addManualEntryItem(int entryIndex) {
    final s = read();
    if (entryIndex < 0 || entryIndex >= s.manualMultiEntries.length) return;
    final e = s.manualMultiEntries[entryIndex];
    var newItem = TransactionItemModel(amount: 0, sortOrder: e.items.length);
    final cat = e.category;
    if (cat != null) {
      newItem = newItem.copyWith(
        categoryId: cat.id,
        categoryName: cat.name,
        categoryIcon: cat.icon,
        categoryColor: cat.color,
      );
    }
    final list = [...s.manualMultiEntries];
    list[entryIndex] = e.copyWith(
      items: [...e.items, newItem],
      itemKeys: [...e.itemKeys, allocateItemKey()],
    );
    _recalcEntryTotal(list, entryIndex);
    write(s.copyWith(manualMultiEntries: list));
  }

  void updateManualEntryItem(
    int entryIndex,
    int itemIndex,
    TransactionItemModel item,
  ) {
    final s = read();
    if (entryIndex < 0 || entryIndex >= s.manualMultiEntries.length) return;
    final e = s.manualMultiEntries[entryIndex];
    if (itemIndex < 0 || itemIndex >= e.items.length) return;
    var resolved = ManualTransactionEntryModel.resolveItemAmount(item);
    final cat = e.category;
    if (cat != null) {
      resolved = resolved.copyWith(
        categoryId: cat.id,
        categoryName: cat.name,
        categoryIcon: cat.icon,
        categoryColor: cat.color,
      );
    }
    final newItems = [...e.items];
    newItems[itemIndex] = resolved;
    final list = [...s.manualMultiEntries];
    list[entryIndex] = e.copyWith(items: newItems);
    _recalcEntryTotal(list, entryIndex);
    write(s.copyWith(manualMultiEntries: list));
  }

  void removeManualEntryItem(int entryIndex, int itemIndex) {
    final s = read();
    if (entryIndex < 0 || entryIndex >= s.manualMultiEntries.length) return;
    final e = s.manualMultiEntries[entryIndex];
    if (e.items.length <= 1) return;
    final newItems = [...e.items]..removeAt(itemIndex);
    final newKeys = [...e.itemKeys]..removeAt(itemIndex);
    final list = [...s.manualMultiEntries];
    list[entryIndex] = e.copyWith(items: newItems, itemKeys: newKeys);
    _recalcEntryTotal(list, entryIndex);
    write(s.copyWith(manualMultiEntries: list));
  }

  void reorderManualEntryItems(int entryIndex, int oldIndex, int newIndex) {
    final s = read();
    if (entryIndex < 0 || entryIndex >= s.manualMultiEntries.length) return;
    final e = s.manualMultiEntries[entryIndex];
    if (oldIndex < 0 || oldIndex >= e.items.length) return;
    if (newIndex < 0 || newIndex > e.items.length) return;
    final newItems = [...e.items];
    final moved = newItems.removeAt(oldIndex);
    final adj = newIndex > oldIndex ? newIndex - 1 : newIndex;
    newItems.insert(adj, moved);
    final newKeys = [...e.itemKeys];
    final k = newKeys.removeAt(oldIndex);
    newKeys.insert(adj, k);
    final list = [...s.manualMultiEntries];
    list[entryIndex] = e.copyWith(items: newItems, itemKeys: newKeys);
    final cat = e.category;
    if (cat != null) {
      list[entryIndex] = list[entryIndex].copyWith(
        items: _withParentCategory(cat, list[entryIndex].items),
      );
    }
    write(s.copyWith(manualMultiEntries: list));
  }

  void _recalcEntryTotal(
    List<ManualTransactionEntryModel> list,
    int entryIndex,
  ) {
    final e = list[entryIndex];
    final total = ManualTransactionEntryModel.sumItems(e.items);
    list[entryIndex] = e.copyWith(totalAmount: total);
  }

  void _replaceEntry(
    int index,
    ManualTransactionEntryModel Function(ManualTransactionEntryModel e) fn,
  ) {
    final s = read();
    if (index < 0 || index >= s.manualMultiEntries.length) return;
    final list = [...s.manualMultiEntries];
    list[index] = fn(list[index]);
    write(s.copyWith(manualMultiEntries: list));
  }

  /// Validasi client sebelum RPC batch.
  static String? validateBatch(
    TransactionFormState s,
    TransactionTypeEnum type,
  ) {
    if (type != TransactionTypeEnum.expense &&
        type != TransactionTypeEnum.income) {
      return 'Batch hanya untuk pengeluaran atau pemasukan';
    }
    if (s.manualMultiEntries.isEmpty) {
      return 'Tambah minimal satu transaksi';
    }
    if (s.manualMultiEntries.length > kManualMultiBatchMaxTransactions) {
      return 'Maksimal $kManualMultiBatchMaxTransactions transaksi sekaligus';
    }
    for (final e in s.manualMultiEntries) {
      if (e.wallet == null) return 'Pilih dompet untuk setiap transaksi';
      if (e.category == null) return 'Pilih kategori untuk setiap transaksi';
      if (e.totalAmount <= 0) return 'Nominal harus lebih dari 0';
      if (e.items.isEmpty) return 'Setiap transaksi wajib punya item';
      if (e.isMultiItem && !e.isTotalMatched) {
        return 'Periksa total multi-item pada setiap transaksi';
      }
      for (final it in e.items) {
        if (it.categoryId == null || it.categoryId!.isEmpty) {
          return 'Kategori wajib untuk setiap item';
        }
      }
    }
    return null;
  }
}
