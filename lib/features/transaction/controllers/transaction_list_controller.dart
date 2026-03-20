import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:app_saku_rapi/features/transaction/repositories/transaction_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'transaction_form_controller.dart';

/// Parameter untuk filter list transaksi.
class TransactionFilter {
  const TransactionFilter({
    required this.startDate,
    required this.endDate,
    this.walletId,
  });

  final DateTime startDate;
  final DateTime endDate;

  /// `null` = semua dompet.
  final String? walletId;

  @override
  bool operator ==(Object other) =>
      other is TransactionFilter &&
      other.startDate == startDate &&
      other.endDate == endDate &&
      other.walletId == walletId;

  @override
  int get hashCode => Object.hash(startDate, endDate, walletId);
}

// ─────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────

/// Provider untuk list transaksi dengan filter tanggal aktif bulan ini.
///
/// State: `AsyncValue<List<TransactionModel>>`
final transactionListControllerProvider =
    AsyncNotifierProvider<TransactionListController, List<TransactionModel>>(
      () => TransactionListController(),
    );

// ─────────────────────────────────────────────────────────────
// Controller
// ─────────────────────────────────────────────────────────────

/// Riverpod [AsyncNotifier] untuk mengelola daftar transaksi dengan
/// paginasi dan filter.
///
/// Fitur:
/// - Auto-load saat build (bulan ini secara default)
/// - Pagination via [loadMore]
/// - Filter dompet via [applyFilter]
/// - Refresh via [refresh]
class TransactionListController extends AsyncNotifier<List<TransactionModel>> {
  late final TransactionRepository _repository;

  static const String _tag = 'TransactionList';
  static const int _limit = 20;

  DateTime _startDate = _firstDayOfMonth();
  DateTime _endDate = _lastDayOfMonth();
  String? _walletId;
  int _currentPage = 0;
  bool _hasMore = true;

  bool get hasMore => _hasMore;

  static DateTime _firstDayOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  static DateTime _lastDayOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  }

  @override
  Future<List<TransactionModel>> build() async {
    _repository = ref.watch(transactionRepositoryProvider);
    return _fetchPage(page: 0, replace: true);
  }

  // ─────────────────────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────────────────────

  /// Refresh dari awal (halaman 0).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(page: 0, replace: true));
  }

  /// Muat halaman berikutnya (infinite scroll).
  Future<void> loadMore() async {
    if (!_hasMore) return;
    final current = state.value ?? [];
    final next = await AsyncValue.guard(
      () => _fetchPage(page: _currentPage, replace: false),
    );
    next.whenData((newItems) => state = AsyncData([...current, ...newItems]));
  }

  /// Terapkan filter baru (reset ke halaman 0).
  Future<void> applyFilter({
    DateTime? startDate,
    DateTime? endDate,
    String? walletId,
    bool clearWallet = false,
  }) async {
    _startDate = startDate ?? _startDate;
    _endDate = endDate ?? _endDate;
    _walletId = clearWallet ? null : (walletId ?? _walletId);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(page: 0, replace: true));
  }

  /// Hapus transaksi dari list (optimistic remove) lalu konfirmasi ke server.
  Future<void> deleteTransaction(String transactionId) async {
    final previous = state.value ?? [];
    state = AsyncData(previous.where((t) => t.id != transactionId).toList());

    final DataState<bool> result = await _repository.deleteTransaction(
      transactionId,
    );

    result.map(
      success: (_) {
        AppLogger.logSuccess('[$_tag] Transaksi $transactionId dihapus');
      },
      error: (err) {
        AppLogger.logError('[$_tag] Gagal hapus, rollback: ${err.message}');
        // Rollback optimistic update
        state = AsyncData(previous);
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Internal
  // ─────────────────────────────────────────────────────────────

  Future<List<TransactionModel>> _fetchPage({
    required int page,
    required bool replace,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

    AppLogger.call('[$_tag] Fetch halaman $page...', colorLog: ColorLog.blue);

    final result = await _repository.getTransactions(
      userId: userId,
      startDate: _startDate,
      endDate: _endDate,
      walletId: _walletId,
      page: page,
      limit: _limit,
    );

    return result.map(
      success: (data) {
        _hasMore = data.data.length == _limit;
        _currentPage = page + 1;
        AppLogger.call(
          '[$_tag] ${data.data.length} transaksi dimuat',
          colorLog: ColorLog.green,
        );
        return data.data;
      },
      error: (err) {
        AppLogger.logError('[$_tag] Fetch gagal: ${err.message}');
        throw Exception(err.message);
      },
    );
  }
}
