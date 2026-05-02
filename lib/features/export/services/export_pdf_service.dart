import 'dart:math' as math;
import 'dart:typed_data';

import 'package:app_saku_rapi/core/enums/debt_status_enum.dart';
import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/features/debt_loan/models/debt_loan_transaction_model.dart';
import 'package:app_saku_rapi/features/export/models/export_gathered_data_model.dart';
import 'package:app_saku_rapi/features/export/utils/export_data_utils.dart';
import 'package:app_saku_rapi/features/export/utils/export_pdf_theme.dart';
import 'package:app_saku_rapi/features/export/view/widgets/pdf/export_pdf_bar_chart.dart';
import 'package:app_saku_rapi/features/export/view/widgets/pdf/export_pdf_pie_chart.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:app_saku_rapi/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Membangun bytes PDF laporang (A4, tema mengikuti app, chart landscape).
final class ExportPdfService {
  ExportPdfService._();

  static const _tag = '[Export] [Pdf]';

  static double _tableWidth(double pageClientWidth) =>
      pageClientWidth - 2 * ExportPdfLayout.tableSideInset;

  static double _pageBottomInset() => ExportPdfLayout.pageMarginPt;

  static void _applyColumnWeights(PdfGrid grid, double tw, List<double> weights) {
    final sum = weights.fold<double>(0, (a, b) => a + b);
    for (var i = 0; i < weights.length; i++) {
      grid.columns[i].width = tw * weights[i] / sum;
    }
  }

  static void _centerFirstColumnCell(PdfGridRow row) {
    row.cells[0].style.stringFormat =
        PdfStringFormat(alignment: PdfTextAlignment.center);
  }

  /// Top [topN] kategori pengeluaran; sisanya digabung untuk chart pie PDF.
  static List<ExportPdfPieSlice> _pieSlicesTopWithOthers({
    required Map<String, double> catTotals,
    required String othersLabel,
    int topN = 6,
  }) {
    final sorted = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (sorted.isEmpty) return [];
    final out = sorted
        .take(topN)
        .map((e) => ExportPdfPieSlice(name: e.key, amount: e.value))
        .toList();
    if (sorted.length <= topN) return out;
    var rest = 0.0;
    for (var i = topN; i < sorted.length; i++) {
      rest += sorted[i].value;
    }
    if (rest > 0.000001) {
      out.add(ExportPdfPieSlice(name: othersLabel, amount: rest));
    }
    return out;
  }

  static Future<List<int>> buildPdfBytes({
    required BuildContext context,
    required ExportGatheredDataModel gathered,
    required AppLocalizations l10n,
    required String localeName,
    required DateTime periodStartLocal,
    required DateTime periodEndLocal,
    required bool includeDebtSheet,
    required bool includeTransferSheet,
  }) async {
    final colors = context.colors;
    final theme = ExportPdfTheme.fromContext(colors: colors);
    final rows = List<TransactionModel>.from(gathered.incomeExpenseForPeriod)
      ..sort((a, b) {
        final c = b.date.compareTo(a.date);
        if (c != 0) return c;
        final ac = a.createdAt;
        final bc = b.createdAt;
        if (ac == null || bc == null) return 0;
        return bc.compareTo(ac);
      });

    final daily = ExportDataUtils.dailyIncomeExpense(rows);
    final sortedDays = daily.keys.toList()..sort();
    final dailyIncome = sortedDays.map((d) => daily[d]!.income).toList();
    final dailyExpense = sortedDays.map((d) => daily[d]!.expense).toList();

    final catTotals = ExportDataUtils.expenseTotalsByCategory(rows);
    final totalExp = catTotals.values.fold<double>(0, (a, b) => a + b);
    final totalIn = ExportDataUtils.sumIncome(rows);
    final totalOut = ExportDataUtils.sumExpense(rows);
    final balance = totalIn - totalOut;

    final periodLabel =
        '${DateFormat.yMMMd(localeName).format(periodStartLocal)} – ${DateFormat.yMMMd(localeName).format(periodEndLocal)}';

    final shot = ScreenshotController();
    Uint8List? barPng;
    if (sortedDays.isNotEmpty) {
      try {
        barPng = await shot.captureFromWidget(
          ExportPdfBarChart(
            sortedDays: sortedDays,
            dailyIncome: dailyIncome,
            dailyExpense: dailyExpense,
            colors: colors,
            chartTitle: l10n.exportChartDailyTrendTitle,
            localeName: localeName,
            incomeLabel: l10n.exportDailyIncome,
            expenseLabel: l10n.exportDailyExpense,
          ),
          delay: const Duration(milliseconds: 750),
          context: context,
          pixelRatio: 2,
          targetSize: const Size(
            ExportPdfLayout.chartCaptureWidth,
            ExportPdfLayout.chartCaptureHeightBar,
          ),
        );
      } catch (e, st) {
        assert(() {
          AppLogger.call('$_tag bar capture failed: $e\n$st');
          return true;
        }());
      }
    }

    Uint8List? piePng;
    if (catTotals.isNotEmpty &&
        totalExp > 0 &&
        context.mounted) {
      final pieSlices = _pieSlicesTopWithOthers(
        catTotals: catTotals,
        othersLabel: l10n.exportChartCategoryOthers,
        topN: 6,
      );
      try {
        piePng = await shot.captureFromWidget(
          ExportPdfPieChart(
            slices: pieSlices,
            totalExpense: totalExp,
            colors: colors,
            l10n: l10n,
          ),
          delay: const Duration(milliseconds: 750),
          context: context,
          pixelRatio: 2,
          targetSize: const Size(
            ExportPdfLayout.chartCaptureWidth,
            ExportPdfLayout.chartCaptureHeightPie,
          ),
        );
      } catch (e, st) {
        assert(() {
          AppLogger.call('$_tag pie capture failed: $e\n$st');
          return true;
        }());
      }
    }

    final doc = PdfDocument()
      ..pageSettings.margins.all = ExportPdfLayout.pageMarginPt;
    final tocItems = <_TocItem>[];

    // ── Sampul
    doc.pages.add();
    _drawCover(
      doc.pages[0],
      theme: theme,
      l10n: l10n,
      localeName: localeName,
      periodLine: l10n.exportPeriodExcelLabel(periodLabel),
    );

    /// Halaman daftar isi (konten digambar di akhir agar nomor halaman benar).
    final tocPage = doc.pages.add();

    // ── Dashboard + ringkasan harian (satu blok konten)
    final dashboardPage = doc.pages.add();
    tocItems.add(_TocItem(l10n.exportPdfDashboardSectionTitle, dashboardPage));
    _drawDashboardAndDailyCombined(
      page: dashboardPage,
      theme: theme,
      l10n: l10n,
      localeName: localeName,
      totalIn: totalIn,
      totalOut: totalOut,
      balance: balance,
      showPartialNote: gathered.isPartialPeriod,
      sortedDays: sortedDays,
      daily: daily,
    );

    if (barPng != null) {
      final barPage = _addLandscapeA4Page(doc);
      tocItems.add(_TocItem(l10n.exportChartDailyTrendTitle, barPage));
      _drawLandscapeChartPage(
        barPage,
        theme: theme,
        title: l10n.exportChartDailyTrendTitle,
        png: barPng,
      );
    }

    if (piePng != null) {
      final piePage = _addLandscapeA4Page(doc);
      tocItems.add(_TocItem(l10n.exportChartCategoryTitle, piePage));
      _drawLandscapeChartPage(
        piePage,
        theme: theme,
        title: l10n.exportChartCategoryTitle,
        png: piePng,
      );
    }

    final txPage = doc.pages.add();
    tocItems.add(_TocItem(l10n.exportSheetTransactions, txPage));
    _drawTransactionTables(
      startPage: txPage,
      theme: theme,
      l10n: l10n,
      localeName: localeName,
      rows: rows,
    );

    final catPage = doc.pages.add();
    tocItems.add(_TocItem(l10n.exportSheetCategoryAnalysis, catPage));
    _drawCategoryPage(
      catPage,
      theme: theme,
      l10n: l10n,
      localeName: localeName,
      catTotals: catTotals,
      totalExpense: totalExp,
    );

    PdfPage? debtPage;
    if (includeDebtSheet) {
      debtPage = doc.pages.add();
      tocItems.add(_TocItem(l10n.exportSheetDebt, debtPage));
      _drawDebtSection(
        startPage: debtPage,
        theme: theme,
        l10n: l10n,
        localeName: localeName,
        rows: gathered.debtLoanRows,
      );
    }

    PdfPage? xferPage;
    if (includeTransferSheet) {
      xferPage = doc.pages.add();
      tocItems.add(_TocItem(l10n.exportSheetTransfer, xferPage));
      _drawTransferSection(
        startPage: xferPage,
        theme: theme,
        l10n: l10n,
        localeName: localeName,
        rows: gathered.transfersForPeriod,
      );
    }

    // ── Daftar isi (halaman 2, setelah semua pagination selesai)
    _drawToc(
      doc: doc,
      tocPage: tocPage,
      theme: theme,
      l10n: l10n,
      items: tocItems,
    );

    for (final item in tocItems) {
      doc.bookmarks.add(item.title).destination =
          PdfDestination(item.page, Offset.zero);
    }

    final bytes = doc.saveSync();
    doc.dispose();
    return bytes;
  }

  /// Halaman landscape A4: [PdfPageCollection.insert] membutuhkan dokumen
  /// loaded + crossTable; dokumen baru harus pakai section terpisah.
  static PdfPage _addLandscapeA4Page(PdfDocument document) {
    final section = document.sections!.add();
    final settings =
        PdfPageSettings(PdfPageSize.a4, PdfPageOrientation.landscape);
    settings.margins.all = ExportPdfLayout.pageMarginPt;
    section.pageSettings = settings;
    return section.pages.add();
  }

  static void _drawCover(
    PdfPage page,
    {
    required ExportPdfTheme theme,
    required AppLocalizations l10n,
    required String localeName,
    required String periodLine,
  }) {
    final size = page.getClientSize();
    final g = page.graphics;
    final pad = ExportPdfLayout.pageMarginPt;
    final headerH = size.height * 0.26;
    g.drawRectangle(
      brush: theme.brush(theme.primary),
      bounds: Rect.fromLTWH(0, 0, size.width, headerH),
    );
    g.drawString(
      l10n.exportCoverAppBrand,
      theme.boldFont(26),
      brush: PdfSolidBrush(PdfColor(255, 255, 255)),
      bounds: Rect.fromLTWH(pad, 26, size.width - 2 * pad, 36),
    );
    g.drawString(
      l10n.exportReportBrandTitle,
      theme.boldFont(12),
      brush: PdfSolidBrush(PdfColor(255, 255, 255)),
      bounds: Rect.fromLTWH(pad, 64, size.width - 2 * pad, 26),
    );

    g.drawRectangle(
      brush: theme.brush(theme.surface),
      bounds: Rect.fromLTWH(0, headerH, size.width, size.height - headerH),
    );

    g.drawString(
      periodLine,
      theme.bodyFont(11),
      brush: theme.brush(theme.textPrimary),
      bounds: Rect.fromLTWH(pad, headerH + 28, size.width - 2 * pad, 22),
    );
    g.drawString(
      '${l10n.exportCoverGeneratedLabel} ${DateFormat.yMMMd(localeName).format(DateTime.now())} · ${DateFormat.jm(localeName).format(DateTime.now())}',
      theme.bodyFont(9),
      brush: theme.brush(theme.textSecondary),
      bounds: Rect.fromLTWH(pad, headerH + 52, size.width - 2 * pad, 36),
    );
  }

  static void _drawDashboardAndDailyCombined({
    required PdfPage page,
    required ExportPdfTheme theme,
    required AppLocalizations l10n,
    required String localeName,
    required double totalIn,
    required double totalOut,
    required double balance,
    required bool showPartialNote,
    required List<DateTime> sortedDays,
    required Map<DateTime, ({double income, double expense})> daily,
  }) {
    final g = page.graphics;
    final size = page.getClientSize();
    final tx = ExportPdfLayout.tableSideInset;
    final tip = ExportPdfLayout.textInsetPt;
    final tw = _tableWidth(size.width);
    var y = ExportPdfLayout.pageMarginPt;

    g.drawRectangle(
      brush: theme.brush(theme.primary),
      bounds: Rect.fromLTWH(0, y, size.width, 3),
    );
    y += 10;

    g.drawString(
      l10n.exportPdfDashboardSectionTitle,
      theme.boldFont(15),
      brush: theme.brush(theme.textPrimary),
      bounds: Rect.fromLTWH(tip, y, size.width - 2 * tip, 20),
    );
    y += 24;

    if (showPartialNote) {
      g.drawString(
        l10n.exportPartialIncompleteNote,
        theme.bodyFont(9),
        brush: theme.brush(theme.warning),
        bounds: Rect.fromLTWH(tip, y, size.width - 2 * tip, 32),
      );
      y += 34;
    }

    final idr = NumberFormat.currency(
      locale: localeName,
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final boxW = (tw - 16) / 3;
    const boxH = 48.0;
    final labels = [
      l10n.exportSummaryIncomeBox,
      l10n.exportSummaryExpenseBox,
      l10n.exportSummaryBalanceBox,
    ];
    final amounts = [totalIn, totalOut, balance];
    final amountColors = [theme.income, theme.expense, theme.textPrimary];

    for (var i = 0; i < 3; i++) {
      final x = tx + i * (boxW + 8);
      g.drawRectangle(
        brush: theme.brush(theme.primary),
        bounds: Rect.fromLTWH(x, y, 4, boxH),
      );
      g.drawRectangle(
        bounds: Rect.fromLTWH(x + 4, y, boxW - 4, boxH),
        pen: theme.pen(theme.border),
        brush: theme.brush(theme.surface),
      );
      g.drawString(
        labels[i],
        theme.bodyFont(8),
        brush: theme.brush(theme.textSecondary),
        bounds: Rect.fromLTWH(x + 12, y + 5, boxW - 16, 12),
      );
      g.drawString(
        idr.format(amounts[i]),
        theme.boldFont(10),
        brush: theme.brush(amountColors[i]),
        bounds: Rect.fromLTWH(x + 12, y + 20, boxW - 16, 22),
      );
    }
    y += boxH + 18;

    g.drawString(
      l10n.exportPdfDailyTableSectionTitle,
      theme.boldFont(11),
      brush: theme.brush(theme.textSecondary),
      bounds: Rect.fromLTWH(tip, y, size.width - 2 * tip, 16),
    );
    y += 18;

    final grid = PdfGrid();
    grid.style = PdfGridStyle(
      font: theme.bodyFont(8),
      cellPadding: PdfPaddings(left: 3, right: 3, top: 2, bottom: 2),
    );
    grid.columns.add(count: 3);
    final colW = tw / 3;
    for (var i = 0; i < grid.columns.count; i++) {
      grid.columns[i].width = colW;
    }
    grid.headers.add(1);
    final h = grid.headers[0];
    h.cells[0].value = l10n.exportDailyDate;
    h.cells[1].value = l10n.exportDailyIncome;
    h.cells[2].value = l10n.exportDailyExpense;
    _styleHeaderRowPresentation(h, theme);

    final df = DateFormat.yMMMd(localeName);
    for (final d in sortedDays) {
      final row = grid.rows.add();
      final v = daily[d]!;
      row.cells[0].value = df.format(d);
      row.cells[1].value = idr.format(v.income);
      row.cells[2].value = idr.format(v.expense);
    }

    grid.draw(
      page: page,
      bounds: Rect.fromLTWH(
        tx,
        y,
        tw,
        size.height - y - _pageBottomInset(),
      ),
      format: PdfLayoutFormat(layoutType: PdfLayoutType.paginate),
    )!;
  }

  static void _drawLandscapeChartPage(
    PdfPage page,
    {
    required ExportPdfTheme theme,
    required String title,
    required Uint8List png,
  }) {
    final g = page.graphics;
    final size = page.getClientSize();
    final pad = ExportPdfLayout.landscapePad;
    g.drawRectangle(
      brush: theme.brush(theme.background),
      bounds: Rect.fromLTWH(0, 0, size.width, size.height),
    );
    g.drawString(
      title,
      theme.boldFont(13),
      brush: theme.brush(theme.textPrimary),
      bounds: Rect.fromLTWH(pad, pad, size.width - 2 * pad, 20),
    );
    final img = PdfBitmap(png);
    final iw = img.width.toDouble();
    final ih = img.height.toDouble();
    final top = pad + 26;
    final content = Rect.fromLTWH(
      pad,
      top,
      size.width - 2 * pad,
      size.height - top - pad,
    );
    final scale = math.min(content.width / iw, content.height / ih);
    final w = iw * scale;
    final h = ih * scale;
    final dx = content.left + (content.width - w) / 2;
    final dy = content.top + (content.height - h) / 2;
    g.drawImage(img, Rect.fromLTWH(dx, dy, w, h));
  }

  static void _drawCategoryPage(
    PdfPage page,
    {
    required ExportPdfTheme theme,
    required AppLocalizations l10n,
    required String localeName,
    required Map<String, double> catTotals,
    required double totalExpense,
  }) {
    final g = page.graphics;
    final size = page.getClientSize();
    final tw = _tableWidth(size.width);
    final tx = ExportPdfLayout.tableSideInset;
    var y = ExportPdfLayout.pageMarginPt;
    y = _drawSectionTitleBand(
      g,
      theme,
      l10n.exportSheetCategoryAnalysis,
      size.width,
      y,
    );

    final entries = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final grid = PdfGrid();
    grid.style = PdfGridStyle(
      font: theme.bodyFont(8),
      cellPadding: PdfPaddings(left: 4, right: 4, top: 3, bottom: 3),
    );
    grid.columns.add(count: 3);
    grid.columns[0].width = tw * 0.42;
    grid.columns[1].width = tw * 0.33;
    grid.columns[2].width = tw * 0.25;

    grid.headers.add(1);
    final h = grid.headers[0];
    h.cells[0].value = l10n.exportAnalysisCategory;
    h.cells[1].value = l10n.exportAnalysisTotal;
    h.cells[2].value = l10n.exportAnalysisPercent;
    _styleHeaderRowPresentation(h, theme);

    final idr = NumberFormat.currency(
      locale: localeName,
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    for (final e in entries) {
      final row = grid.rows.add();
      final pct = totalExpense > 0 ? (e.value / totalExpense * 100) : 0.0;
      row.cells[0].value = e.key;
      row.cells[1].value = idr.format(e.value);
      row.cells[2].value = '${pct.toStringAsFixed(1)}%';
    }

    grid.draw(
      page: page,
      bounds: Rect.fromLTWH(
        tx,
        y,
        tw,
        size.height - y - _pageBottomInset(),
      ),
      format: PdfLayoutFormat(layoutType: PdfLayoutType.paginate),
    )!;
  }

  static void _drawTransactionTables({
    required PdfPage startPage,
    required ExportPdfTheme theme,
    required AppLocalizations l10n,
    required String localeName,
    required List<TransactionModel> rows,
  }) {
    final size = startPage.getClientSize();
    final tw = _tableWidth(size.width);
    final tx = ExportPdfLayout.tableSideInset;
    var y = ExportPdfLayout.pageMarginPt;
    y = _drawSectionTitleBand(
      startPage.graphics,
      theme,
      l10n.exportSheetTransactions,
      size.width,
      y,
    );

    final grid = PdfGrid();
    grid.repeatHeader = true;
    grid.style = PdfGridStyle(
      font: theme.bodyFont(7),
      cellPadding: PdfPaddings(left: 3, right: 3, top: 2, bottom: 2),
    );
    grid.columns.add(count: 7);
    _applyColumnWeights(grid, tw, [22, 52, 40, 68, 95, 48, 56]);

    grid.headers.add(1);
    final h = grid.headers[0];
    h.cells[0].value = l10n.exportColNo;
    h.cells[1].value = l10n.exportColDate;
    h.cells[2].value = l10n.exportColType;
    h.cells[3].value = l10n.exportColCategory;
    h.cells[4].value = l10n.exportColNote;
    h.cells[5].value = l10n.exportColWallet;
    h.cells[6].value = l10n.exportColAmount;
    _styleHeaderRowPresentation(h, theme, centerColumnIndices: {0});

    final dateFmt = DateFormat.yMMMd(localeName);
    final idr = NumberFormat.currency(
      locale: localeName,
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    for (var i = 0; i < rows.length; i++) {
      final t = rows[i];
      final row = grid.rows.add();
      row.cells[0].value = '${i + 1}';
      row.cells[1].value = dateFmt.format(t.date.toLocal());
      row.cells[2].value = t.type == TransactionTypeEnum.income
          ? l10n.transactionIncome
          : l10n.transactionExpense;
      row.cells[3].value = ExportDataUtils.combinedCategoryNames(t);
      row.cells[4].value = ExportDataUtils.combinedNoteForRow(
        t,
        localeName: localeName,
      );
      row.cells[5].value = t.walletName ?? '—';
      row.cells[6].value = idr.format(t.totalAmount);
      _centerFirstColumnCell(row);
    }

    grid.draw(
      page: startPage,
      bounds: Rect.fromLTWH(
        tx,
        y,
        tw,
        size.height - y - _pageBottomInset(),
      ),
      format: PdfLayoutFormat(layoutType: PdfLayoutType.paginate),
    )!;
  }

  static bool _debtIsPaid(DebtLoanTransactionModel r) {
    if (r.remaining <= 0.009) return true;
    return r.status == DebtStatusEnum.paid;
  }

  static void _drawDebtSection({
    required PdfPage startPage,
    required ExportPdfTheme theme,
    required AppLocalizations l10n,
    required String localeName,
    required List<DebtLoanTransactionModel> rows,
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
    final idr = NumberFormat.currency(
      locale: localeName,
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final size = startPage.getClientSize();
    final tw = _tableWidth(size.width);
    final tx = ExportPdfLayout.tableSideInset;
    final tip = ExportPdfLayout.textInsetPt;
    var y = ExportPdfLayout.pageMarginPt;
    final g = startPage.graphics;
    y = _drawSectionTitleBand(
      g,
      theme,
      l10n.exportSheetDebt,
      size.width,
      y,
    );

    g.drawString(
      '${l10n.exportDebtUnpaidTotalTitle}: ${idr.format(debtUnpaid)}',
      theme.bodyFont(9),
      brush: theme.brush(theme.textPrimary),
      bounds: Rect.fromLTWH(tip, y, size.width - 2 * tip, 14),
    );
    y += 16;
    g.drawString(
      '${l10n.exportReceivableUnpaidTotalTitle}: ${idr.format(loanUnpaid)}',
      theme.bodyFont(9),
      brush: theme.brush(theme.textPrimary),
      bounds: Rect.fromLTWH(tip, y, size.width - 2 * tip, 14),
    );
    y += 22;

    final grid = PdfGrid();
    grid.repeatHeader = true;
    grid.style = PdfGridStyle(
      font: theme.bodyFont(7),
      cellPadding: PdfPaddings(left: 3, right: 3, top: 2, bottom: 2),
    );
    grid.columns.add(count: 8);
    _applyColumnWeights(grid, tw, [22, 50, 36, 56, 52, 48, 40, 76]);

    grid.headers.add(1);
    final h = grid.headers[0];
    h.cells[0].value = l10n.exportColNo;
    h.cells[1].value = l10n.exportColDate;
    h.cells[2].value = l10n.exportColType;
    h.cells[3].value = l10n.exportColPerson;
    h.cells[4].value = l10n.exportColAmount;
    h.cells[5].value = l10n.exportColDueDate;
    h.cells[6].value = l10n.exportColStatus;
    h.cells[7].value = l10n.exportColNote;
    _styleHeaderRowPresentation(h, theme, centerColumnIndices: {0});

    final sorted = List<DebtLoanTransactionModel>.from(rows)
      ..sort((a, b) => b.date.compareTo(a.date));
    final dateFmt = DateFormat.yMMMd(localeName);
    final dueFmt = DateFormat.yMMMd(localeName);

    for (var i = 0; i < sorted.length; i++) {
      final r = sorted[i];
      final row = grid.rows.add();
      row.cells[0].value = '${i + 1}';
      row.cells[1].value = dateFmt.format(r.date.toLocal());
      row.cells[2].value =
          r.type == 'debt' ? l10n.transactionDebt : l10n.transactionLoan;
      row.cells[3].value =
          r.withPerson?.trim().isNotEmpty == true ? r.withPerson! : '—';
      row.cells[4].value = idr.format(r.totalAmount);
      final due = r.dueDate;
      row.cells[5].value =
          due != null ? dueFmt.format(due.toLocal()) : '—';
      final paid = _debtIsPaid(r);
      row.cells[6].value =
          paid ? l10n.exportStatusLunas : l10n.exportStatusBelumLunas;
      row.cells[7].value = r.note ?? '';
      _centerFirstColumnCell(row);
    }

    grid.draw(
      page: startPage,
      bounds: Rect.fromLTWH(
        tx,
        y,
        tw,
        size.height - y - _pageBottomInset(),
      ),
      format: PdfLayoutFormat(layoutType: PdfLayoutType.paginate),
    )!;
  }

  static void _drawTransferSection({
    required PdfPage startPage,
    required ExportPdfTheme theme,
    required AppLocalizations l10n,
    required String localeName,
    required List<TransactionModel> rows,
  }) {
    final size = startPage.getClientSize();
    final tw = _tableWidth(size.width);
    final tx = ExportPdfLayout.tableSideInset;
    var y = ExportPdfLayout.pageMarginPt;
    y = _drawSectionTitleBand(
      startPage.graphics,
      theme,
      l10n.exportSheetTransfer,
      size.width,
      y,
    );

    final grid = PdfGrid();
    grid.repeatHeader = true;
    grid.style = PdfGridStyle(
      font: theme.bodyFont(7),
      cellPadding: PdfPaddings(left: 3, right: 3, top: 2, bottom: 2),
    );
    grid.columns.add(count: 6);
    _applyColumnWeights(grid, tw, [22, 52, 62, 62, 54, 90]);

    grid.headers.add(1);
    final h = grid.headers[0];
    h.cells[0].value = l10n.exportColNo;
    h.cells[1].value = l10n.exportColDate;
    h.cells[2].value = l10n.exportColWalletSource;
    h.cells[3].value = l10n.exportColWalletDest;
    h.cells[4].value = l10n.exportColAmount;
    h.cells[5].value = l10n.exportColNote;
    _styleHeaderRowPresentation(h, theme, centerColumnIndices: {0});

    final sorted = List<TransactionModel>.from(rows)
      ..sort((a, b) => b.date.compareTo(a.date));
    final dateFmt = DateFormat.yMMMd(localeName);
    final idr = NumberFormat.currency(
      locale: localeName,
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    for (var i = 0; i < sorted.length; i++) {
      final t = sorted[i];
      final row = grid.rows.add();
      row.cells[0].value = '${i + 1}';
      row.cells[1].value = dateFmt.format(t.date.toLocal());
      row.cells[2].value = t.walletName ?? '—';
      row.cells[3].value = t.destinationWalletName ?? '—';
      row.cells[4].value = idr.format(t.totalAmount);
      row.cells[5].value = t.note ?? '';
      _centerFirstColumnCell(row);
    }

    grid.draw(
      page: startPage,
      bounds: Rect.fromLTWH(
        tx,
        y,
        tw,
        size.height - y - _pageBottomInset(),
      ),
      format: PdfLayoutFormat(layoutType: PdfLayoutType.paginate),
    )!;
  }

  static double _drawSectionTitleBand(
    PdfGraphics g,
    ExportPdfTheme theme,
    String title,
    double pageWidth,
    double y,
  ) {
    final tip = ExportPdfLayout.textInsetPt;
    g.drawRectangle(
      brush: theme.brush(theme.primary),
      bounds: Rect.fromLTWH(0, y, pageWidth, 2.5),
    );
    var yy = y + 8;
    g.drawString(
      title,
      theme.boldFont(13),
      brush: theme.brush(theme.textPrimary),
      bounds: Rect.fromLTWH(tip, yy, pageWidth - 2 * tip, 18),
    );
    return yy + 22;
  }

  static void _styleHeaderRowPresentation(
    PdfGridRow h,
    ExportPdfTheme theme, {
    Set<int> centerColumnIndices = const {},
  }) {
    for (var i = 0; i < h.cells.count; i++) {
      final center = centerColumnIndices.contains(i);
      h.cells[i].style = PdfGridCellStyle(
        backgroundBrush: theme.brush(theme.primary),
        textBrush: theme.onPrimaryBrush,
        font: theme.boldFont(8),
        format: center
            ? PdfStringFormat(alignment: PdfTextAlignment.center)
            : null,
      );
    }
  }

  static void _drawToc({
    required PdfDocument doc,
    required PdfPage tocPage,
    required ExportPdfTheme theme,
    required AppLocalizations l10n,
    required List<_TocItem> items,
  }) {
    final g = tocPage.graphics;
    final size = tocPage.getClientSize();
    final tip = ExportPdfLayout.textInsetPt;
    final top = ExportPdfLayout.pageMarginPt;
    g.drawRectangle(
      brush: theme.brush(theme.background),
      bounds: Rect.fromLTWH(0, 0, size.width, size.height),
    );

    g.drawString(
      l10n.exportTocTitle,
      theme.boldFont(18),
      brush: theme.brush(theme.textPrimary),
      bounds: Rect.fromLTWH(tip, top, size.width - 2 * tip, 26),
    );

    var y = top + 36.0;
    const lineH = 18.0;

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final pageNum = doc.pages.indexOf(item.page) + 1;
      final label = '${i + 1}. ${item.title}';
      final dest = PdfDestination(item.page, Offset.zero);
      dest.mode = PdfDestinationMode.fitToPage;
      final fullRect = Rect.fromLTWH(tip, y, size.width - 2 * tip, lineH);

      g.drawString(
        label,
        theme.bodyFont(11),
        brush: theme.brush(theme.primary),
        bounds: Rect.fromLTWH(tip, y, size.width - 2 * tip - 36, lineH),
      );
      g.drawString(
        '$pageNum',
        theme.bodyFont(11),
        brush: theme.brush(theme.textPrimary),
        format: PdfStringFormat(alignment: PdfTextAlignment.right),
        bounds: Rect.fromLTWH(size.width - tip - 32, y, 28, lineH),
      );

      tocPage.annotations.add(PdfDocumentLinkAnnotation(fullRect, dest));
      y += lineH + 4;
    }
  }
}

class _TocItem {
  _TocItem(this.title, this.page);

  final String title;
  final PdfPage page;
}
