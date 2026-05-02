import 'package:app_saku_rapi/features/dashboard/controllers/dashboard_chart_controller.dart';
import 'package:app_saku_rapi/features/dashboard/repositories/dashboard_repository.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:app_saku_rapi/features/wallet/controllers/wallet_controller.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// ───────────────── Providers ─────────────────

/// Provider singleton untuk [DashboardRepository].
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository();
});

/// Provider utama untuk [DashboardController].
///
/// Mengelola state inti dashboard: status loading, recent transactions,
/// error message, dan visibility saldo.
///
/// **Tidak** mengelola data chart/period — tanggung jawab tersebut
/// didelegasikan ke [dashboardChartControllerProvider] agar widget chart
/// bisa di-rebuild secara independen tanpa mempengaruhi widget lain.
final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, DashboardState>((ref) {
      final repository = ref.watch(dashboardRepositoryProvider);
      return DashboardController(repository, ref);
    });

/// Provider computed: semua wallet dengan urutan tampilan yang sama seperti
/// [walletListProvider] (picker, filter, wallet page).
final dashboardWalletsProvider = Provider<List<WalletModel>>((ref) {
  return ref.watch(walletListProvider);
});

/// Provider computed: total balance excluding `exclude_from_total` wallets.
final dashboardTotalBalanceProvider = Provider<double>((ref) {
  final wallets = ref.watch(dashboardWalletsProvider);
  return wallets
      .where((w) => !w.excludeFromTotal)
      .fold<double>(0, (sum, w) => sum + w.balance);
});

// ───────────────── Enums ─────────────────

/// Status loading dashboard.
enum DashboardStatus { initial, loading, loaded, error }

// ───────────────── State ─────────────────

/// Immutable state inti dashboard.
///
/// Hanya menyimpan data yang dibutuhkan oleh widget non-chart:
/// - Status loading halaman
/// - Recent transactions preview (5 terbaru)
/// - Error message
/// - Balance visibility toggle
///
/// Data chart (period summary, daily aggregation, chart mode) dikelola
/// terpisah oleh [DashboardChartState] untuk optimasi rebuild.
class DashboardState {
  const DashboardState({
    this.status = DashboardStatus.initial,
    this.recentTransactions = const [],
    this.errorMessage,
    this.isBalanceHidden = false,
  });

  /// Status loading halaman dashboard secara keseluruhan.
  final DashboardStatus status;

  /// 5 transaksi terbaru untuk preview.
  final List<TransactionModel> recentTransactions;

  /// Error message jika gagal load data inti.
  final String? errorMessage;

  /// User toggle: sembunyikan saldo di balance card.
  final bool isBalanceHidden;

  DashboardState copyWith({
    DashboardStatus? status,
    List<TransactionModel>? recentTransactions,
    String? errorMessage,
    bool? isBalanceHidden,
  }) {
    return DashboardState(
      status: status ?? this.status,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      errorMessage: errorMessage,
      isBalanceHidden: isBalanceHidden ?? this.isBalanceHidden,
    );
  }
}

// ───────────────── Controller ─────────────────

/// Controller inti (parent) untuk dashboard.
///
/// Bertanggung jawab atas:
/// - Load recent transactions preview
/// - Orchestrate chart data loading via [DashboardChartController]
/// - Toggle balance visibility
///
/// Saat `loadDashboard()` dipanggil (termasuk dari fitur lain seperti
/// TransactionFormPage, HistoryPage, dll.), controller ini secara otomatis
/// juga men-trigger reload data chart melalui
/// [dashboardChartControllerProvider].
///
/// **Arsitektur rebuild:**
/// ```
/// DashboardController (core)
///   → DashboardPage (status, loading/error)
///   → DashboardBalanceCard (isBalanceHidden)
///   → DashboardWalletSection (isBalanceHidden)
///   → DashboardRecentTransactions (recentTransactions)
///
/// DashboardChartController (chart)
///   → DashboardChartCarousel (chartMode)
///   → DashboardComparisonChart (chartMode, income/expense)
///   → DashboardTrendReportChart (chartMode, daily data)
///   → DashboardPeriodSummary (chartMode, income/expense)
/// ```
class DashboardController extends StateNotifier<DashboardState> {
  DashboardController(this._repository, this._ref)
    : super(const DashboardState());

  final DashboardRepository _repository;

  /// Riverpod ref untuk mengakses chart controller.
  final Ref _ref;

  /// Load semua data dashboard.
  ///
  /// Fetch recent transactions dan secara paralel trigger chart data loading.
  /// External callers (TransactionFormPage, HistoryPage, dll.) cukup
  /// memanggil method ini — chart data otomatis ikut di-refresh.
  Future<void> loadDashboard() async {
    state = state.copyWith(status: DashboardStatus.loading);

    // Trigger chart data loading secara paralel (non-blocking)
    _ref.read(dashboardChartControllerProvider.notifier).loadChartData();

    // Fetch recent transactions
    final recentResult = await _repository.getRecentTransactions(limit: 5);

    if (recentResult.isError()) {
      final (message, _, _, _) = recentResult.dataError()!;
      state = state.copyWith(
        status: DashboardStatus.error,
        errorMessage: message,
      );
      return;
    }

    state = state.copyWith(
      status: DashboardStatus.loaded,
      recentTransactions: recentResult.dataSuccess() ?? [],
    );
  }

  /// Toggle visibility saldo di balance card.
  void toggleBalanceVisibility() {
    state = state.copyWith(isBalanceHidden: !state.isBalanceHidden);
  }
}
