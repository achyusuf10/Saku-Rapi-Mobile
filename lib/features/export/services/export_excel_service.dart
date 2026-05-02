import 'package:app_saku_rapi/core/enums/debt_status_enum.dart';
import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/features/export/models/export_gathered_data_model.dart';
import 'package:app_saku_rapi/features/export/utils/export_data_utils.dart';
import 'package:app_saku_rapi/features/export/utils/export_excel_palette.dart';
import 'package:app_saku_rapi/features/debt_loan/models/debt_loan_transaction_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:app_saku_rapi/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:syncfusion_officechart/officechart.dart';

/// Membangun bytes `.xlsx` multi-sheet sesuai PRD export.
final class ExportExcelService {
  ExportExcelService._();

  static const _idrFormat = r'"Rp" #,##0';

  /// Font body/header export (harus terpasang di perangkat pembuka file).
  static const _excelFont = 'Nunito';

  /// Baris yang dipakai area chart mengambang di bawah ringkasan total.
  static const _chartVisualRowSpan = 18;

  static void _thinBorderAround(Range r, String colorHex) {
    final b = r.cellStyle.borders;
    for (final e in [b.left, b.right, b.top, b.bottom]) {
      e.lineStyle = LineStyle.thin;
      e.color = colorHex;
    }
  }

  static void _headerRowStyle(Worksheet sheet, int row, int c1, int c2) {
    for (var c = c1; c <= c2; c++) {
      final cell = sheet.getRangeByIndex(row, c);
      cell.cellStyle.bold = true;
      cell.cellStyle.fontName = _excelFont;
      cell.cellStyle.fontColor = ExportExcelPalette.textPrimary;
      cell.cellStyle.backColor = ExportExcelPalette.headerFill;
      cell.cellStyle.hAlign = HAlignType.center;
      cell.cellStyle.vAlign = VAlignType.center;
      _thinBorderAround(cell, ExportExcelPalette.border);
    }
  }

  /// Membuat workbook. [localeName] dipakai [DateFormat] (mis. `id_ID`).
  static List<int> buildWorkbook({
    required ExportGatheredDataModel gathered,
    required AppLocalizations l10n,
    required String localeName,
    required DateTime periodStartLocal,
    required DateTime periodEndLocal,
    required bool includeDebtSheet,
    required bool includeTransferSheet,
  }) {
    final wb = Workbook(1);
    final sheetDash = wb.worksheets[0]..name = l10n.exportSheetDashboard;

    final sheetData = wb.worksheets.add()
      ..name = l10n.exportSheetTransactions;
    final sheetCat = wb.worksheets.add()
      ..name = l10n.exportSheetCategoryAnalysis;

    Worksheet? sheetDebt;
    if (includeDebtSheet) {
      sheetDebt = wb.worksheets.add()..name = l10n.exportSheetDebt;
    }
    Worksheet? sheetXfer;
    if (includeTransferSheet) {
      sheetXfer = wb.worksheets.add()..name = l10n.exportSheetTransfer;
    }

    final rows = List<TransactionModel>.from(gathered.incomeExpenseForPeriod)
      ..sort((a, b) {
        final c = b.date.compareTo(a.date);
        if (c != 0) return c;
        final ac = a.createdAt;
        final bc = b.createdAt;
        if (ac == null || bc == null) return 0;
        return bc.compareTo(ac);
      });

    _fillTransactionSheet(
      sheet: sheetData,
      rows: rows,
      l10n: l10n,
      localeName: localeName,
    );

    final catTotals = ExportDataUtils.expenseTotalsByCategory(rows);
    final totalExp = catTotals.values.fold<double>(0, (a, b) => a + b);
    _fillCategorySheet(
      sheet: sheetCat,
      categoryTotals: catTotals,
      totalExpense: totalExp,
      l10n: l10n,
    );

    if (includeDebtSheet && sheetDebt != null) {
      _fillDebtSheet(
        sheet: sheetDebt,
        rows: gathered.debtLoanRows,
        l10n: l10n,
        localeName: localeName,
      );
    }

    if (includeTransferSheet && sheetXfer != null) {
      _fillTransferSheet(
        sheet: sheetXfer,
        rows: gathered.transfersForPeriod,
        l10n: l10n,
        localeName: localeName,
      );
    }

    final daily = ExportDataUtils.dailyIncomeExpense(rows);
    final sortedDays = daily.keys.toList()..sort();
    final totalIn = ExportDataUtils.sumIncome(rows);
    final totalOut = ExportDataUtils.sumExpense(rows);
    final balance = totalIn - totalOut;

    final periodLabel = _formatPeriodRange(
      periodStartLocal,
      periodEndLocal,
      localeName,
    );

    _fillDashboardSheet(
      sheet: sheetDash,
      sheetCategory: sheetCat,
      categoryRowCount: catTotals.length,
      daily: daily,
      sortedDays: sortedDays,
      totalIncome: totalIn,
      totalExpense: totalOut,
      balance: balance,
      periodExcelLabel: l10n.exportPeriodExcelLabel(periodLabel),
      gathered: gathered,
      l10n: l10n,
      localeName: localeName,
    );

    final bytes = wb.saveAsStream();
    wb.dispose();
    return bytes;
  }

  static String _formatPeriodRange(
    DateTime start,
    DateTime end,
    String localeName,
  ) {
    final fmt = DateFormat.yMMMd(localeName);
    return '${fmt.format(start)} – ${fmt.format(end)}';
  }

  static void _fillTransactionSheet({
    required Worksheet sheet,
    required List<TransactionModel> rows,
    required AppLocalizations l10n,
    required String localeName,
  }) {
    void h(int c, String t) => sheet.getRangeByIndex(1, c).setText(t);

    h(1, l10n.exportColNo);
    h(2, l10n.exportColDate);
    h(3, l10n.exportColType);
    h(4, l10n.exportColCategory);
    h(5, l10n.exportColNote);
    h(6, l10n.exportColWallet);
    h(7, l10n.exportColAmount);

    _headerRowStyle(sheet, 1, 1, 7);

    final dateFmt = DateFormat.yMMMd(localeName);
    for (var i = 0; i < rows.length; i++) {
      final t = rows[i];
      final r = i + 2;
      final idxCell = sheet.getRangeByIndex(r, 1);
      idxCell.setNumber(i + 1);
      idxCell.cellStyle.hAlign = HAlignType.center;

      sheet.getRangeByIndex(r, 2).setText(dateFmt.format(t.date.toLocal()));

      final typeLabel = t.type == TransactionTypeEnum.income
          ? l10n.transactionIncome
          : l10n.transactionExpense;
      final typeCell = sheet.getRangeByIndex(r, 3);
      typeCell.setText(typeLabel);
      if (t.type == TransactionTypeEnum.income) {
        typeCell.cellStyle.fontColor = ExportExcelPalette.income;
      } else {
        typeCell.cellStyle.fontColor = ExportExcelPalette.expense;
      }

      final catCell = sheet.getRangeByIndex(r, 4);
      catCell.setText(ExportDataUtils.combinedCategoryNames(t));
      catCell.cellStyle.wrapText = true;
      catCell.cellStyle.vAlign = VAlignType.top;

      final noteCell = sheet.getRangeByIndex(r, 5);
      noteCell.setText(
        ExportDataUtils.combinedNoteForRow(t, localeName: localeName),
      );
      noteCell.cellStyle.wrapText = true;
      noteCell.cellStyle.vAlign = VAlignType.top;

      final walletCell = sheet.getRangeByIndex(r, 6);
      walletCell.setText(t.walletName ?? '—');
      walletCell.cellStyle.wrapText = true;
      walletCell.cellStyle.vAlign = VAlignType.top;

      final amt = sheet.getRangeByIndex(r, 7);
      amt.setNumber(t.totalAmount);
      amt.cellStyle.numberFormat = _idrFormat;
      amt.cellStyle.hAlign = HAlignType.right;
      if (t.type == TransactionTypeEnum.income) {
        amt.cellStyle.fontColor = ExportExcelPalette.income;
      } else {
        amt.cellStyle.fontColor = ExportExcelPalette.expense;
      }

      final band = i.isEven
          ? ExportExcelPalette.rowStripeEven
          : ExportExcelPalette.rowStripeOdd;
      for (var c = 1; c <= 7; c++) {
        final cell = sheet.getRangeByIndex(r, c);
        cell.cellStyle.fontName = _excelFont;
        cell.cellStyle.backColor = band;
        cell.cellStyle.vAlign = VAlignType.top;
        _thinBorderAround(cell, ExportExcelPalette.border);
      }
    }

    if (rows.isNotEmpty) {
      sheet.getRangeByIndex(2, 1).freezePanes();
    }

    sheet.setColumnWidthInPixels(1, 48);
    sheet.setColumnWidthInPixels(2, 112);
    sheet.setColumnWidthInPixels(3, 96);
    sheet.setColumnWidthInPixels(4, 180);
    sheet.setColumnWidthInPixels(5, 320);
    sheet.setColumnWidthInPixels(6, 128);
    sheet.setColumnWidthInPixels(7, 112);
  }

  static void _fillCategorySheet({
    required Worksheet sheet,
    required Map<String, double> categoryTotals,
    required double totalExpense,
    required AppLocalizations l10n,
  }) {
    sheet.getRangeByIndex(1, 1).setText(l10n.exportAnalysisCategory);
    sheet.getRangeByIndex(1, 2).setText(l10n.exportAnalysisTotal);
    sheet.getRangeByIndex(1, 3).setText(l10n.exportAnalysisPercent);
    _headerRowStyle(sheet, 1, 1, 3);

    final entries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (var i = 0; i < entries.length; i++) {
      final r = i + 2;
      final e = entries[i];
      final nameCell = sheet.getRangeByIndex(r, 1);
      nameCell.setText(e.key);
      nameCell.cellStyle.fontName = _excelFont;
      nameCell.cellStyle.vAlign = VAlignType.top;
      _thinBorderAround(nameCell, ExportExcelPalette.border);

      final tot = sheet.getRangeByIndex(r, 2);
      tot.setNumber(e.value);
      tot.cellStyle.numberFormat = _idrFormat;
      tot.cellStyle.fontName = _excelFont;
      tot.cellStyle.hAlign = HAlignType.right;
      _thinBorderAround(tot, ExportExcelPalette.border);

      final pct = totalExpense > 0 ? (e.value / totalExpense * 100) : 0.0;
      final pCell = sheet.getRangeByIndex(r, 3);
      pCell.setNumber(pct / 100);
      pCell.cellStyle.numberFormat = '0.00%';
      pCell.cellStyle.fontName = _excelFont;
      pCell.cellStyle.hAlign = HAlignType.right;
      _thinBorderAround(pCell, ExportExcelPalette.border);

      final band = i.isEven
          ? ExportExcelPalette.rowStripeEven
          : ExportExcelPalette.rowStripeOdd;
      nameCell.cellStyle.backColor = band;
      tot.cellStyle.backColor = band;
      pCell.cellStyle.backColor = band;
    }

    sheet.setColumnWidthInPixels(1, 220);
    sheet.setColumnWidthInPixels(2, 120);
    sheet.setColumnWidthInPixels(3, 96);
  }

  static bool _debtIsPaid(DebtLoanTransactionModel r) {
    if (r.remaining <= 0.009) return true;
    return r.status == DebtStatusEnum.paid;
  }

  static void _fillDebtSheet({
    required Worksheet sheet,
    required List<DebtLoanTransactionModel> rows,
    required AppLocalizations l10n,
    required String localeName,
  }) {
    var debtUnpaid = 0.0;
    var loanUnpaid = 0.0;
    for (final r in rows) {
      if (r.remaining > 0.009) {
        if (r.type == 'debt') {
          debtUnpaid += r.remaining;
        } else {
          loanUnpaid += r.remaining;
        }
      }
    }

    void styleDebtSummaryTitle(Range range, String bg, String color) {
      range.cellStyle.bold = true;
      range.cellStyle.fontName = _excelFont;
      range.cellStyle.fontSize = 11;
      range.cellStyle.backColor = bg;
      range.cellStyle.fontColor = color;
      range.cellStyle.hAlign = HAlignType.left;
      range.cellStyle.vAlign = VAlignType.center;
      range.cellStyle.wrapText = true;
      _thinBorderAround(range, ExportExcelPalette.border);
    }

    void styleDebtSummaryValue(Range range, String bg, String color) {
      range.cellStyle.bold = true;
      range.cellStyle.fontName = _excelFont;
      range.cellStyle.fontSize = 12;
      range.cellStyle.backColor = bg;
      range.cellStyle.fontColor = color;
      range.cellStyle.hAlign = HAlignType.right;
      range.cellStyle.vAlign = VAlignType.center;
      range.cellStyle.numberFormat = _idrFormat;
      _thinBorderAround(range, ExportExcelPalette.border);
    }

    sheet.getRangeByIndex(1, 1, 1, 5).merge();
    final debtTitle = sheet.getRangeByIndex(1, 1);
    debtTitle.setText(l10n.exportDebtUnpaidTotalTitle);
    styleDebtSummaryTitle(
      debtTitle,
      ExportExcelPalette.summaryExpenseBg,
      ExportExcelPalette.debtTone,
    );

    sheet.getRangeByIndex(1, 6, 1, 8).merge();
    final debtVal = sheet.getRangeByIndex(1, 6);
    debtVal.setNumber(debtUnpaid);
    styleDebtSummaryValue(
      debtVal,
      ExportExcelPalette.summaryExpenseBg,
      ExportExcelPalette.debtTone,
    );

    sheet.getRangeByIndex(2, 1, 2, 5).merge();
    final recvTitle = sheet.getRangeByIndex(2, 1);
    recvTitle.setText(l10n.exportReceivableUnpaidTotalTitle);
    styleDebtSummaryTitle(
      recvTitle,
      ExportExcelPalette.summaryBalanceBg,
      ExportExcelPalette.loanTone,
    );

    sheet.getRangeByIndex(2, 6, 2, 8).merge();
    final recvVal = sheet.getRangeByIndex(2, 6);
    recvVal.setNumber(loanUnpaid);
    styleDebtSummaryValue(
      recvVal,
      ExportExcelPalette.summaryBalanceBg,
      ExportExcelPalette.loanTone,
    );

    const headerRow = 4;
    const firstDataRow = 5;
    void h(int c, String t) => sheet.getRangeByIndex(headerRow, c).setText(t);
    h(1, l10n.exportColNo);
    h(2, l10n.exportColDate);
    h(3, l10n.exportColType);
    h(4, l10n.exportColPerson);
    h(5, l10n.exportColAmount);
    h(6, l10n.exportColDueDate);
    h(7, l10n.exportColStatus);
    h(8, l10n.exportColNote);
    _headerRowStyle(sheet, headerRow, 1, 8);

    final sorted = List<DebtLoanTransactionModel>.from(rows)
      ..sort((a, b) => b.date.compareTo(a.date));

    final dateFmt = DateFormat.yMMMd(localeName);
    final dueFmt = DateFormat.yMMMd(localeName);

    for (var i = 0; i < sorted.length; i++) {
      final r = sorted[i];
      final rowIdx = firstDataRow + i;
      sheet.getRangeByIndex(rowIdx, 1).setNumber(i + 1);
      sheet.getRangeByIndex(rowIdx, 1).cellStyle.hAlign = HAlignType.center;
      sheet.getRangeByIndex(rowIdx, 2).setText(dateFmt.format(r.date.toLocal()));
      final typeLabel =
          r.type == 'debt' ? l10n.transactionDebt : l10n.transactionLoan;
      final typeCell = sheet.getRangeByIndex(rowIdx, 3);
      typeCell.setText(typeLabel);
      typeCell.cellStyle.fontColor = r.type == 'debt'
          ? ExportExcelPalette.debtTone
          : ExportExcelPalette.loanTone;
      final personCell = sheet.getRangeByIndex(rowIdx, 4);
      personCell.setText(
        r.withPerson?.trim().isNotEmpty == true ? r.withPerson! : '—',
      );
      personCell.cellStyle.wrapText = true;
      final amt = sheet.getRangeByIndex(rowIdx, 5);
      amt.setNumber(r.totalAmount);
      amt.cellStyle.numberFormat = _idrFormat;
      amt.cellStyle.hAlign = HAlignType.right;
      final due = r.dueDate;
      sheet
          .getRangeByIndex(rowIdx, 6)
          .setText(due != null ? dueFmt.format(due.toLocal()) : '—');
      final paid = _debtIsPaid(r);
      final statusCell = sheet.getRangeByIndex(rowIdx, 7);
      statusCell.setText(
        paid ? l10n.exportStatusLunas : l10n.exportStatusBelumLunas,
      );
      statusCell.cellStyle.fontColor = paid
          ? ExportExcelPalette.income
          : ExportExcelPalette.warning;
      final noteDebt = sheet.getRangeByIndex(rowIdx, 8);
      noteDebt.setText(r.note ?? '');
      noteDebt.cellStyle.wrapText = true;
      noteDebt.cellStyle.vAlign = VAlignType.top;

      final bg = paid
          ? ExportExcelPalette.debtPaidRowBg
          : ExportExcelPalette.debtUnpaidRowBg;
      for (var c = 1; c <= 8; c++) {
        final cell = sheet.getRangeByIndex(rowIdx, c);
        cell.cellStyle.backColor = bg;
        cell.cellStyle.fontName = _excelFont;
        cell.cellStyle.vAlign = VAlignType.top;
        _thinBorderAround(cell, ExportExcelPalette.border);
        if (c != 3 && c != 7) {
          cell.cellStyle.fontColor = ExportExcelPalette.textPrimary;
        }
      }
    }

    if (sorted.isNotEmpty) {
      sheet.getRangeByIndex(firstDataRow, 1).freezePanes();
    }
    sheet.setColumnWidthInPixels(1, 44);
    sheet.setColumnWidthInPixels(2, 108);
    sheet.setColumnWidthInPixels(3, 92);
    sheet.setColumnWidthInPixels(4, 132);
    sheet.setColumnWidthInPixels(5, 108);
    sheet.setColumnWidthInPixels(6, 108);
    sheet.setColumnWidthInPixels(7, 100);
    sheet.setColumnWidthInPixels(8, 440);
  }

  static void _fillTransferSheet({
    required Worksheet sheet,
    required List<TransactionModel> rows,
    required AppLocalizations l10n,
    required String localeName,
  }) {
    void h(int c, String t) => sheet.getRangeByIndex(1, c).setText(t);
    h(1, l10n.exportColNo);
    h(2, l10n.exportColDate);
    h(3, l10n.exportColWalletSource);
    h(4, l10n.exportColWalletDest);
    h(5, l10n.exportColAmount);
    h(6, l10n.exportColNote);
    _headerRowStyle(sheet, 1, 1, 6);

    final sorted = List<TransactionModel>.from(rows)
      ..sort((a, b) => b.date.compareTo(a.date));
    final dateFmt = DateFormat.yMMMd(localeName);

    for (var i = 0; i < sorted.length; i++) {
      final t = sorted[i];
      final r = i + 2;
      sheet.getRangeByIndex(r, 1).setNumber(i + 1);
      sheet.getRangeByIndex(r, 2).setText(dateFmt.format(t.date.toLocal()));
      sheet.getRangeByIndex(r, 3).setText(t.walletName ?? '—');
      sheet.getRangeByIndex(r, 4).setText(t.destinationWalletName ?? '—');
      final amt = sheet.getRangeByIndex(r, 5);
      amt.setNumber(t.totalAmount);
      amt.cellStyle.numberFormat = _idrFormat;
      amt.cellStyle.hAlign = HAlignType.right;
      amt.cellStyle.fontColor = ExportExcelPalette.transfer;
      final noteT = sheet.getRangeByIndex(r, 6);
      noteT.setText(t.note ?? '');
      noteT.cellStyle.wrapText = true;
      noteT.cellStyle.vAlign = VAlignType.top;

      final band = i.isEven
          ? ExportExcelPalette.rowStripeEven
          : ExportExcelPalette.rowStripeOdd;
      for (var c = 1; c <= 6; c++) {
        final cell = sheet.getRangeByIndex(r, c);
        cell.cellStyle.fontName = _excelFont;
        cell.cellStyle.backColor = band;
        if (c == 5) {
          cell.cellStyle.fontColor = ExportExcelPalette.transfer;
        } else {
          cell.cellStyle.fontColor = ExportExcelPalette.textPrimary;
        }
        cell.cellStyle.vAlign = VAlignType.top;
        _thinBorderAround(cell, ExportExcelPalette.border);
      }
    }

    if (sorted.isNotEmpty) {
      sheet.getRangeByIndex(2, 1).freezePanes();
    }
    sheet.setColumnWidthInPixels(1, 48);
    sheet.setColumnWidthInPixels(2, 112);
    sheet.setColumnWidthInPixels(3, 128);
    sheet.setColumnWidthInPixels(4, 128);
    sheet.setColumnWidthInPixels(5, 112);
    sheet.setColumnWidthInPixels(6, 240);
  }

  static void _fillDashboardSheet({
    required Worksheet sheet,
    required Worksheet sheetCategory,
    required int categoryRowCount,
    required Map<DateTime, ({double income, double expense})> daily,
    required List<DateTime> sortedDays,
    required double totalIncome,
    required double totalExpense,
    required double balance,
    required String periodExcelLabel,
    required ExportGatheredDataModel gathered,
    required AppLocalizations l10n,
    required String localeName,
  }) {
    void styleTitleCell(Range cell) {
      cell.cellStyle.bold = true;
      cell.cellStyle.fontSize = 16;
      cell.cellStyle.fontName = _excelFont;
      cell.cellStyle.fontColor = ExportExcelPalette.textPrimary;
      cell.cellStyle.hAlign = HAlignType.center;
    }

    sheet.getRangeByName('A1:J1').merge();
    final title = sheet.getRangeByName('A1');
    title.setText(l10n.exportReportBrandTitle);
    styleTitleCell(title);

    sheet.getRangeByName('A2:J2').merge();
    final periodCell = sheet.getRangeByName('A2');
    periodCell.setText(periodExcelLabel);
    periodCell.cellStyle.fontName = _excelFont;
    periodCell.cellStyle.fontSize = 11;
    periodCell.cellStyle.fontColor = ExportExcelPalette.textSecondary;
    periodCell.cellStyle.hAlign = HAlignType.center;

    var nextRow = 3;
    if (gathered.isPartialPeriod) {
      sheet.getRangeByIndex(nextRow, 1, nextRow, 10).merge();
      final partialCell = sheet.getRangeByIndex(nextRow, 1);
      partialCell.setText(l10n.exportPartialIncompleteNote);
      partialCell.cellStyle.fontName = _excelFont;
      partialCell.cellStyle.fontColor = ExportExcelPalette.expense;
      partialCell.cellStyle.wrapText = true;
      nextRow++;
    }

    for (var c = 1; c <= 10; c++) {
      sheet.setColumnWidthInPixels(c, 118);
    }

    final labelRow = nextRow;
    final valueRow = nextRow + 1;

    void styleSummaryLabel(Range range, String bg, String textColor) {
      range.cellStyle.bold = true;
      range.cellStyle.fontName = _excelFont;
      range.cellStyle.fontSize = 11;
      range.cellStyle.backColor = bg;
      range.cellStyle.fontColor = textColor;
      range.cellStyle.hAlign = HAlignType.center;
      range.cellStyle.vAlign = VAlignType.center;
      range.cellStyle.wrapText = true;
      _thinBorderAround(range, ExportExcelPalette.border);
    }

    void styleSummaryValue(Range range, String bg, String textColor) {
      range.cellStyle.bold = true;
      range.cellStyle.fontName = _excelFont;
      range.cellStyle.fontSize = 13;
      range.cellStyle.backColor = bg;
      range.cellStyle.fontColor = textColor;
      range.cellStyle.hAlign = HAlignType.center;
      range.cellStyle.vAlign = VAlignType.center;
      range.cellStyle.wrapText = true;
      _thinBorderAround(range, ExportExcelPalette.border);
    }

    sheet.getRangeByIndex(labelRow, 1, labelRow, 3).merge();
    final incL = sheet.getRangeByIndex(labelRow, 1);
    incL.setText(l10n.exportSummaryIncomeBox);
    styleSummaryLabel(
      incL,
      ExportExcelPalette.summaryIncomeBg,
      ExportExcelPalette.primary,
    );

    sheet.getRangeByIndex(labelRow, 4, labelRow, 6).merge();
    final expL = sheet.getRangeByIndex(labelRow, 4);
    expL.setText(l10n.exportSummaryExpenseBox);
    styleSummaryLabel(
      expL,
      ExportExcelPalette.summaryExpenseBg,
      ExportExcelPalette.expense,
    );

    sheet.getRangeByIndex(labelRow, 7, labelRow, 10).merge();
    final balL = sheet.getRangeByIndex(labelRow, 7);
    balL.setText(l10n.exportSummaryBalanceBox);
    styleSummaryLabel(
      balL,
      ExportExcelPalette.summaryBalanceBg,
      ExportExcelPalette.primary,
    );

    sheet.getRangeByIndex(valueRow, 1, valueRow, 3).merge();
    final incV = sheet.getRangeByIndex(valueRow, 1);
    incV.setNumber(totalIncome);
    incV.cellStyle.numberFormat = _idrFormat;
    styleSummaryValue(
      incV,
      ExportExcelPalette.summaryIncomeBg,
      ExportExcelPalette.primary,
    );

    sheet.getRangeByIndex(valueRow, 4, valueRow, 6).merge();
    final expV = sheet.getRangeByIndex(valueRow, 4);
    expV.setNumber(totalExpense);
    expV.cellStyle.numberFormat = _idrFormat;
    styleSummaryValue(
      expV,
      ExportExcelPalette.summaryExpenseBg,
      ExportExcelPalette.expense,
    );

    sheet.getRangeByIndex(valueRow, 7, valueRow, 10).merge();
    final balV = sheet.getRangeByIndex(valueRow, 7);
    balV.setNumber(balance);
    balV.cellStyle.numberFormat = _idrFormat;
    styleSummaryValue(
      balV,
      ExportExcelPalette.summaryBalanceBg,
      ExportExcelPalette.primary,
    );

    final chartTopRow = valueRow + 2;
    final chartBottomRow = chartTopRow + _chartVisualRowSpan;
    final dailyTitleRow = chartBottomRow + 2;

    sheet.getRangeByIndex(dailyTitleRow, 1, dailyTitleRow, 10).merge();
    sheet
        .getRangeByIndex(dailyTitleRow, 1)
        .setText(l10n.exportDailySummaryTitle);
    sheet.getRangeByIndex(dailyTitleRow, 1).cellStyle.bold = true;
    sheet.getRangeByIndex(dailyTitleRow, 1).cellStyle.fontName = _excelFont;
    sheet.getRangeByIndex(dailyTitleRow, 1).cellStyle.fontColor =
        ExportExcelPalette.textPrimary;

    final hdrRow = dailyTitleRow + 1;
    final dateFmt = DateFormat.MMMd(localeName);
    sheet.getRangeByIndex(hdrRow, 1).setText(l10n.exportDailyDate);
    sheet.getRangeByIndex(hdrRow, 2).setText(l10n.exportDailyIncome);
    sheet.getRangeByIndex(hdrRow, 3).setText(l10n.exportDailyExpense);
    _headerRowStyle(sheet, hdrRow, 1, 3);

    for (var i = 0; i < sortedDays.length; i++) {
      final day = sortedDays[i];
      final r = hdrRow + 1 + i;
      final v = daily[day]!;
      final dCell = sheet.getRangeByIndex(r, 1);
      dCell.setText(dateFmt.format(day));
      dCell.cellStyle.fontName = _excelFont;
      dCell.cellStyle.hAlign = HAlignType.left;
      dCell.cellStyle.fontColor = ExportExcelPalette.textPrimary;
      final iC = sheet.getRangeByIndex(r, 2);
      iC.setNumber(v.income);
      iC.cellStyle.numberFormat = _idrFormat;
      iC.cellStyle.fontName = _excelFont;
      iC.cellStyle.hAlign = HAlignType.right;
      iC.cellStyle.fontColor = ExportExcelPalette.income;
      final eC = sheet.getRangeByIndex(r, 3);
      eC.setNumber(v.expense);
      eC.cellStyle.numberFormat = _idrFormat;
      eC.cellStyle.fontName = _excelFont;
      eC.cellStyle.hAlign = HAlignType.right;
      eC.cellStyle.fontColor = ExportExcelPalette.expense;
      for (var c = 1; c <= 3; c++) {
        final cell = sheet.getRangeByIndex(r, c);
        cell.cellStyle.backColor = i.isEven
            ? ExportExcelPalette.rowStripeEven
            : ExportExcelPalette.rowStripeOdd;
        cell.cellStyle.vAlign = VAlignType.top;
        _thinBorderAround(cell, ExportExcelPalette.border);
      }
    }

    final dailyDataEndRow = hdrRow + sortedDays.length;

    final charts = ChartCollection(sheet);
    var hasChart = false;

    if (categoryRowCount > 0 && sortedDays.isNotEmpty) {
      final lastCatRow = 1 + categoryRowCount;
      final pie = charts.add();
      pie.chartType = ExcelChartType.pie;
      pie.chartTitle = l10n.exportChartCategoryTitle;
      pie.isSeriesInRows = false;
      pie.topRow = chartTopRow;
      pie.bottomRow = chartBottomRow;
      pie.leftColumn = 5;
      pie.rightColumn = 10;
      pie.dataRange = sheetCategory.getRangeByName('A2:B$lastCatRow');
      pie.legend?.position = ExcelLegendPosition.bottom;

      final bar = charts.add();
      bar.chartType = ExcelChartType.column;
      bar.chartTitle = l10n.exportChartBarTitle;
      bar.isSeriesInRows = false;
      bar.topRow = chartTopRow;
      bar.bottomRow = chartBottomRow;
      bar.leftColumn = 0;
      bar.rightColumn = 4;
      bar.dataRange = sheet.getRangeByIndex(
        hdrRow,
        1,
        dailyDataEndRow,
        3,
      );
      bar.legend?.position = ExcelLegendPosition.bottom;
      hasChart = true;
    } else if (categoryRowCount > 0) {
      final lastCatRow = 1 + categoryRowCount;
      final pie = charts.add();
      pie.chartType = ExcelChartType.pie;
      pie.chartTitle = l10n.exportChartCategoryTitle;
      pie.isSeriesInRows = false;
      pie.topRow = chartTopRow;
      pie.bottomRow = chartBottomRow;
      pie.leftColumn = 1;
      pie.rightColumn = 9;
      pie.dataRange = sheetCategory.getRangeByName('A2:B$lastCatRow');
      pie.legend?.position = ExcelLegendPosition.bottom;
      hasChart = true;
    } else if (sortedDays.isNotEmpty && dailyDataEndRow >= hdrRow + 1) {
      final bar = charts.add();
      bar.chartType = ExcelChartType.column;
      bar.chartTitle = l10n.exportChartBarTitle;
      bar.isSeriesInRows = false;
      bar.topRow = chartTopRow;
      bar.bottomRow = chartBottomRow;
      bar.leftColumn = 0;
      bar.rightColumn = 9;
      bar.dataRange = sheet.getRangeByIndex(
        hdrRow,
        1,
        dailyDataEndRow,
        3,
      );
      bar.legend?.position = ExcelLegendPosition.bottom;
      hasChart = true;
    }

    if (hasChart) {
      sheet.charts = charts;
    }
  }
}
