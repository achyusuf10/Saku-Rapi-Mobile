import 'dart:convert';

import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/utils/saku_date_utils.dart';
import 'package:app_saku_rapi/features/history/models/history_models.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:app_saku_rapi/utils/services/hive_services.dart';

/// Local data source untuk cache history transaksi.
///
/// Menyimpan:
/// - Cache transaksi (offline fallback)
/// - Preferensi filter terakhir (period, wallet, type, groupMode, subPeriodIndex)
class HistoryLocalDataSource {
  static const _tag = '[History] [HistoryLocalDataSource]';
  static const _cacheKey = 'cached_history_transactions';
  static const _filterPrefsKey = 'history_filter_prefs';

  // ───────────────── Transaction Cache ─────────────────

  /// Simpan daftar transaksi ke cache lokal.
  void cacheTransactions(List<TransactionModel> transactions) {
    AppLogger.call(
      '$_tag cacheTransactions: ${transactions.length} transactions',
    );
    final jsonList = transactions.map((e) => e.toFullMap()).toList();
    HiveService.set<String>(key: _cacheKey, data: jsonEncode(jsonList));
  }

  /// Ambil daftar transaksi dari cache lokal.
  List<TransactionModel>? getCachedTransactions() {
    final raw = HiveService.get<String>(key: _cacheKey);
    if (raw == null) return null;

    AppLogger.call('$_tag getCachedTransactions: from cache');
    final List<dynamic> jsonList = jsonDecode(raw) as List<dynamic>;
    return jsonList
        .map((e) => TransactionModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Hapus cache.
  void clearCache() {
    AppLogger.call('$_tag clearCache');
    HiveService.delete(_cacheKey);
  }

  // ───────────────── Filter Preferences ─────────────────

  /// Simpan preferensi filter terakhir ke lokal.
  ///
  /// Dipanggil setiap kali pengguna mengubah filter di halaman riwayat.
  void saveFilterPrefs({
    required HistoryPeriod period,
    required HistoryGroupMode groupMode,
    String? walletId,
    TransactionTypeEnum? typeFilter,
    String? searchKeyword,
    int? subPeriodIndex,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    try {
      final map = <String, dynamic>{
        'period': period.name,
        'groupMode': groupMode.name,
        'walletId': ?walletId,
        if (typeFilter != null) 'typeFilter': typeFilter.name,
        'searchKeyword': ?searchKeyword,
        'subPeriodIndex': ?subPeriodIndex,
        if (customStart != null)
          'customStart': SakuDateUtils.formatDate(customStart),
        if (customEnd != null) 'customEnd': SakuDateUtils.formatDate(customEnd),
      };
      HiveService.set<String>(key: _filterPrefsKey, data: jsonEncode(map));
      AppLogger.call('$_tag saveFilterPrefs: period=${period.name}');
    } catch (e) {
      AppLogger.call('$_tag saveFilterPrefs error: $e');
    }
  }

  /// Muat preferensi filter terakhir dari lokal.
  ///
  /// Mengembalikan null jika belum ada data atau terjadi error parsing.
  Map<String, dynamic>? loadFilterPrefs() {
    try {
      final raw = HiveService.get<String>(key: _filterPrefsKey);
      if (raw == null) return null;
      AppLogger.call('$_tag loadFilterPrefs: found saved prefs');
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.call('$_tag loadFilterPrefs error: $e');
      return null;
    }
  }
}
