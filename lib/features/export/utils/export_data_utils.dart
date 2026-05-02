import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/features/category/utils/category_catalog_localizations.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_item_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:app_saku_rapi/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// Utilitas murni untuk agregasi dan teks export Excel (dapat diuji unit).
final class ExportDataUtils {
  ExportDataUtils._();

  /// Gabungan nama kategori unik dari item, urut [TransactionItemModel.sortOrder].
  static String combinedCategoryNames(
    TransactionModel t, {
    AppLocalizations? l10n,
  }) {
    if (t.items.isEmpty) return '-';
    final sorted = List<TransactionItemModel>.from(t.items)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final seen = <String>{};
    final ordered = <String>[];
    for (final e in sorted) {
      final n = e.categoryName?.trim();
      if (n == null || n.isEmpty) continue;
      if (!seen.add(n)) continue;
      ordered.add(
        l10n != null
            ? resolvedCategoryDisplayName(
                l10n: l10n,
                rawName: n,
                ownership: e.categoryOwnership,
              )
            : n,
      );
    }
    if (ordered.isEmpty) return '-';
    return ordered.join('; ');
  }

  /// Catatan induk + rincian tiap item (multi-item ke catatan).
  static String combinedNoteForRow(
    TransactionModel t, {
    String localeName = 'id_ID',
  }) {
    final itemFmt = NumberFormat.currency(
      locale: localeName,
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final buf = StringBuffer();
    final base = t.note?.trim();
    if (base != null && base.isNotEmpty) {
      buf.write(base);
    }
    if (t.items.length <= 1) {
      return buf.isEmpty ? '' : buf.toString();
    }
    final sorted = List<TransactionItemModel>.from(t.items)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    for (final item in sorted) {
      if (buf.isNotEmpty) buf.write('\n');
      final label = item.itemName?.trim().isNotEmpty == true
          ? item.itemName!.trim()
          : (item.categoryName ?? '-');
      buf.write('• $label — ${itemFmt.format(item.amount)}');
    }
    return buf.toString();
  }

  /// Agregasi pengeluaran per kategori dari **item** (bukan dari gabungan string baris).
  static Map<String, double> expenseTotalsByCategory(
    Iterable<TransactionModel> rows,
  ) {
    final map = <String, double>{};
    for (final t in rows) {
      if (t.type != TransactionTypeEnum.expense) continue;
      for (final item in t.items) {
        final name = item.categoryName?.trim().isNotEmpty == true
            ? item.categoryName!.trim()
            : '—';
        map[name] = (map[name] ?? 0) + item.amount;
      }
    }
    return map;
  }

  /// Key tanggal lokal (hanya tahun-bulan-hari).
  static DateTime _dateOnlyLocal(DateTime d) {
    final l = d.toLocal();
    return DateTime(l.year, l.month, l.day);
  }

  /// Total pemasukan & pengeluaran per hari (hanya income/expense).
  static Map<DateTime, ({double income, double expense})> dailyIncomeExpense(
    Iterable<TransactionModel> rows,
  ) {
    final map = <DateTime, ({double income, double expense})>{};
    for (final t in rows) {
      final day = _dateOnlyLocal(t.date);
      final cur = map[day] ?? (income: 0.0, expense: 0.0);
      switch (t.type) {
        case TransactionTypeEnum.income:
          map[day] = (income: cur.income + t.totalAmount, expense: cur.expense);
          break;
        case TransactionTypeEnum.expense:
          map[day] = (income: cur.income, expense: cur.expense + t.totalAmount);
          break;
        default:
          break;
      }
    }
    return map;
  }

  static double sumIncome(Iterable<TransactionModel> rows) {
    return rows
        .where((t) => t.type == TransactionTypeEnum.income)
        .sumBy((t) => t.totalAmount);
  }

  static double sumExpense(Iterable<TransactionModel> rows) {
    return rows
        .where((t) => t.type == TransactionTypeEnum.expense)
        .sumBy((t) => t.totalAmount);
  }
}

extension on Iterable<TransactionModel> {
  double sumBy(double Function(TransactionModel) f) {
    var s = 0.0;
    for (final e in this) {
      s += f(e);
    }
    return s;
  }
}
