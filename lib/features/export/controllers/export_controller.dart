import 'dart:async';

import 'package:app_saku_rapi/features/export/models/export_cancel_signal.dart';
import 'package:app_saku_rapi/features/export/models/export_cancelled_exception.dart';
import 'package:app_saku_rapi/features/export/repositories/export_gather_repository.dart';
import 'package:app_saku_rapi/features/export/services/export_excel_service.dart';
import 'package:app_saku_rapi/features/export/services/export_pdf_service.dart';
import 'package:app_saku_rapi/features/export/utils/export_file_writer.dart';
import 'package:app_saku_rapi/features/export/utils/export_period_ranges.dart';
import 'package:app_saku_rapi/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Fase proses export untuk UI.
enum ExportRunPhase { idle, fetching, building, success }

/// Format file keluaran dari hub Export.
enum ExportFileFormat { excel, pdf }

/// State layar Export pada hub Import/Export.
@immutable
class ExportUiState {
  const ExportUiState({
    required this.phase,
    required this.fileFormat,
    required this.periodPreset,
    required this.customPeriod,
    required this.includeDebtSheet,
    required this.includeTransferSheet,
    required this.showPartialAction,
    required this.isPartialResult,
    required this.savedFilePath,
    required this.errorMessage,
  });

  final ExportRunPhase phase;
  final ExportFileFormat fileFormat;
  final ExportPeriodPreset periodPreset;
  final DateTimeRange? customPeriod;
  final bool includeDebtSheet;
  final bool includeTransferSheet;
  final bool showPartialAction;
  final bool isPartialResult;
  final String? savedFilePath;
  final String? errorMessage;

  /// Rentang efektif untuk fetch & label Excel.
  DateTimeRange? get effectivePeriod {
    if (periodPreset == ExportPeriodPreset.custom) {
      return customPeriod;
    }
    return ExportPeriodRanges.fromPreset(periodPreset);
  }

  ExportUiState copyWith({
    ExportRunPhase? phase,
    ExportFileFormat? fileFormat,
    ExportPeriodPreset? periodPreset,
    DateTimeRange? customPeriod,
    bool clearCustomPeriod = false,
    bool? includeDebtSheet,
    bool? includeTransferSheet,
    bool? showPartialAction,
    bool? isPartialResult,
    String? savedFilePath,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ExportUiState(
      phase: phase ?? this.phase,
      fileFormat: fileFormat ?? this.fileFormat,
      periodPreset: periodPreset ?? this.periodPreset,
      customPeriod: clearCustomPeriod
          ? null
          : (customPeriod ?? this.customPeriod),
      includeDebtSheet: includeDebtSheet ?? this.includeDebtSheet,
      includeTransferSheet: includeTransferSheet ?? this.includeTransferSheet,
      showPartialAction: showPartialAction ?? this.showPartialAction,
      isPartialResult: isPartialResult ?? this.isPartialResult,
      savedFilePath: savedFilePath ?? this.savedFilePath,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  static ExportUiState initial() {
    return ExportUiState(
      phase: ExportRunPhase.idle,
      fileFormat: ExportFileFormat.excel,
      periodPreset: ExportPeriodPreset.thisMonth,
      customPeriod: null,
      includeDebtSheet: false,
      includeTransferSheet: false,
      showPartialAction: false,
      isPartialResult: false,
      savedFilePath: null,
      errorMessage: null,
    );
  }
}

final exportControllerProvider =
    StateNotifierProvider.autoDispose<ExportController, ExportUiState>(
      (ref) => ExportController(ref),
    );

class ExportController extends StateNotifier<ExportUiState> {
  ExportController(this._ref) : super(ExportUiState.initial()) {
    _ref.onDispose(() {
      _partialTimer?.cancel();
      _signal?.cancel();
    });
  }

  final Ref _ref;
  ExportCancelSignal? _signal;
  Timer? _partialTimer;

  void setPeriodPreset(ExportPeriodPreset preset) {
    state = state.copyWith(
      periodPreset: preset,
      clearCustomPeriod: preset != ExportPeriodPreset.custom,
      clearError: true,
    );
  }

  void setCustomPeriod(DateTimeRange range) {
    state = state.copyWith(
      periodPreset: ExportPeriodPreset.custom,
      customPeriod: range,
      clearError: true,
    );
  }

  void setIncludeDebt(bool v) {
    state = state.copyWith(includeDebtSheet: v, clearError: true);
  }

  void setIncludeTransfer(bool v) {
    state = state.copyWith(includeTransferSheet: v, clearError: true);
  }

  void setFileFormat(ExportFileFormat v) {
    state = state.copyWith(fileFormat: v, clearError: true);
  }

  void cancelExport() {
    _signal?.cancel();
    _partialTimer?.cancel();
    state = state.copyWith(
      phase: ExportRunPhase.idle,
      showPartialAction: false,
      clearError: true,
    );
  }

  void requestPartialStop() {
    _signal?.requestPartialStop();
  }

  Future<void> runExport(
    BuildContext context,
    AppLocalizations l10n,
    String localeName,
  ) async {
    final range = state.effectivePeriod;
    if (range == null) {
      state = state.copyWith(errorMessage: l10n.exportSelectCustomRange);
      return;
    }

    final signal = ExportCancelSignal()..reset();
    _signal = signal;
    _partialTimer?.cancel();
    state = state.copyWith(
      phase: ExportRunPhase.fetching,
      showPartialAction: false,
      isPartialResult: false,
      savedFilePath: null,
      clearError: true,
    );

    _partialTimer = Timer(const Duration(seconds: 15), () {
      if (state.phase == ExportRunPhase.fetching) {
        state = state.copyWith(showPartialAction: true);
      }
    });

    try {
      final repo = _ref.read(exportGatherRepositoryProvider);
      final gathered = await repo.gatherForExport(
        periodStartLocal: range.start,
        periodEndLocal: range.end,
        includeDebtSheet: state.includeDebtSheet,
        signal: signal,
      );

      if (signal.isCancelled) {
        state = ExportUiState.initial().copyWith(
          periodPreset: state.periodPreset,
          customPeriod: state.customPeriod,
          fileFormat: state.fileFormat,
          includeDebtSheet: state.includeDebtSheet,
          includeTransferSheet: state.includeTransferSheet,
        );
        return;
      }

      state = state.copyWith(phase: ExportRunPhase.building);

      late final List<int> bytes;
      if (state.fileFormat == ExportFileFormat.pdf) {
        if (!context.mounted) {
          _partialTimer?.cancel();
          state = state.copyWith(
            phase: ExportRunPhase.idle,
            showPartialAction: false,
          );
          return;
        }
        bytes = await ExportPdfService.buildPdfBytes(
          context: context,
          gathered: gathered,
          l10n: l10n,
          localeName: localeName,
          periodStartLocal: range.start,
          periodEndLocal: range.end,
          includeDebtSheet: state.includeDebtSheet,
          includeTransferSheet: state.includeTransferSheet,
        );
      } else {
        bytes = ExportExcelService.buildWorkbook(
          gathered: gathered,
          l10n: l10n,
          localeName: localeName,
          periodStartLocal: range.start,
          periodEndLocal: range.end,
          includeDebtSheet: state.includeDebtSheet,
          includeTransferSheet: state.includeTransferSheet,
        );
      }

      late final String path;
      if (state.fileFormat == ExportFileFormat.pdf) {
        path = await ExportFileWriter.savePdfBytes(bytes);
      } else {
        path = await ExportFileWriter.saveWorkbookBytes(bytes);
      }

      _partialTimer?.cancel();

      state = state.copyWith(
        phase: ExportRunPhase.success,
        savedFilePath: path,
        isPartialResult: gathered.isPartialPeriod,
        showPartialAction: false,
      );
    } on ExportCancelledException {
      _partialTimer?.cancel();
      state = ExportUiState.initial().copyWith(
        periodPreset: state.periodPreset,
        customPeriod: state.customPeriod,
        fileFormat: state.fileFormat,
        includeDebtSheet: state.includeDebtSheet,
        includeTransferSheet: state.includeTransferSheet,
      );
    } catch (e, st) {
      _partialTimer?.cancel();
      state = state.copyWith(
        phase: ExportRunPhase.idle,
        errorMessage: l10n.exportErrorGeneric,
        showPartialAction: false,
      );
      assert(() {
        debugPrint('$e\n$st');
        return true;
      }());
    }
  }

  void resetAfterDialog() {
    state = state.copyWith(
      phase: ExportRunPhase.idle,
      savedFilePath: null,
      isPartialResult: false,
    );
  }
}
