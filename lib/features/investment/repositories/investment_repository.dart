import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/investment/datasource/investment_local_data_source.dart';
import 'package:app_saku_rapi/features/investment/datasource/investment_remote_data_source.dart';
import 'package:app_saku_rapi/features/investment/models/investment_model.dart';

/// Repository utama untuk fitur investasi.
///
/// Mengorkestrasikan [InvestmentRemoteDataSource] dan
/// [InvestmentLocalDataSource]:
/// - Validasi domain dilakukan di sini.
/// - Create menggunakan RPC atomik (optional wallet deduction).
/// - Update/delete langsung REST.
/// - Read dengan offline fallback.
class InvestmentRepository {
  InvestmentRepository({
    InvestmentRemoteDataSource? remoteDataSource,
    InvestmentLocalDataSource? localDataSource,
  }) : _remote = remoteDataSource ?? InvestmentRemoteDataSource(),
       _local = localDataSource ?? InvestmentLocalDataSource();

  final InvestmentRemoteDataSource _remote;
  final InvestmentLocalDataSource _local;

  static const _tag = '[Investment] [InvestmentRepository]';

  // ───────────────── READ ─────────────────

  /// Ambil semua investasi. Fallback ke cache jika gagal.
  Future<DataState<List<InvestmentModel>>> getInvestments() async {
    final result = await _remote.getInvestments();

    if (result.isSuccess()) {
      // Exclude investments whose custom asset type has been soft-deleted.
      final filtered = result
          .dataSuccess()!
          .where(
            (inv) => inv.assetTypeId == null || inv.assetTypeIsDeleted != true,
          )
          .toList();
      _local.cacheInvestments(filtered);
      return DataState.success(data: filtered);
    }

    // Offline fallback
    final cached = _local.getCachedInvestments();
    if (cached != null) {
      AppLogger.call('$_tag getInvestments: serving from cache');
      return DataState.success(data: cached);
    }

    return result;
  }

  // ───────────────── VALIDATION ─────────────────

  /// Validasi input investasi.
  /// Mengembalikan pesan error, atau `null` jika valid.
  static String? validateInput({
    required String name,
    required double amount,
    required double avgBuyPrice,
    required bool deductFromWallet,
    String? walletId,
    double? walletBalance,
  }) {
    if (name.trim().isEmpty) return 'Nama aset wajib diisi';
    if (amount <= 0) return 'Jumlah harus lebih dari 0';
    if (avgBuyPrice <= 0) return 'Harga beli harus lebih dari 0';

    if (deductFromWallet) {
      if (walletId == null || walletId.isEmpty) {
        return 'Pilih dompet terlebih dahulu';
      }
      if (walletBalance != null) {
        final totalCost = amount * avgBuyPrice;
        if (totalCost > walletBalance) {
          return 'Saldo dompet tidak mencukupi';
        }
      }
    }

    return null;
  }

  // ───────────────── CREATE ─────────────────

  /// Buat investasi baru setelah validasi domain.
  ///
  /// Jika [deductFromWallet] true, RPC akan atomically:
  /// 1. Insert investment
  /// 2. Create transaction `transfer_to_asset`
  /// 3. Trigger update wallet balance
  Future<DataState<Map<String, dynamic>>> createInvestment({
    required String type,
    required String name,
    String? symbol,
    required double amount,
    required double avgBuyPrice,
    double? customCurrentPrice,
    String? linkedWalletId,
    String? assetTypeId,
    String? notes,
    required bool deductFromWallet,
    double? walletBalance,
  }) async {
    final validationError = validateInput(
      name: name,
      amount: amount,
      avgBuyPrice: avgBuyPrice,
      deductFromWallet: deductFromWallet,
      walletId: linkedWalletId,
      walletBalance: walletBalance,
    );

    if (validationError != null) {
      return DataState.error(message: validationError);
    }

    AppLogger.call(
      '$_tag createInvestment: $name ($type), '
      'deductWallet=$deductFromWallet',
    );

    return _remote.createInvestment(
      type: type,
      name: name,
      symbol: symbol,
      amount: amount,
      avgBuyPrice: avgBuyPrice,
      customCurrentPrice: customCurrentPrice,
      linkedWalletId: linkedWalletId,
      assetTypeId: assetTypeId,
      notes: notes,
      deductFromWallet: deductFromWallet,
    );
  }

  // ───────────────── UPDATE ─────────────────

  /// Update investasi yang sudah ada.
  /// Tidak menyentuh wallet / ledger — hanya update data aset.
  Future<DataState<InvestmentModel>> updateInvestment({
    required String investmentId,
    required String name,
    String? symbol,
    required double amount,
    required double avgBuyPrice,
    double? customCurrentPrice,
    String? linkedWalletId,
    String? assetTypeId,
    String? notes,
  }) async {
    if (name.trim().isEmpty) {
      return DataState.error(message: 'Nama aset wajib diisi');
    }
    if (amount <= 0) {
      return DataState.error(message: 'Jumlah harus lebih dari 0');
    }
    if (avgBuyPrice <= 0) {
      return DataState.error(message: 'Harga beli harus lebih dari 0');
    }

    AppLogger.call('$_tag updateInvestment: $investmentId');

    return _remote.updateInvestment(
      investmentId: investmentId,
      updates: {
        'name': name,
        'symbol': symbol,
        'amount': amount,
        'avg_buy_price': avgBuyPrice,
        'custom_current_price': customCurrentPrice,
        'linked_wallet_id': linkedWalletId,
        'asset_type_id': assetTypeId,
        'notes': notes,
      },
    );
  }

  // ───────────────── DELETE ─────────────────

  /// Hapus investasi.
  Future<DataState<void>> deleteInvestment(String investmentId) async {
    AppLogger.call('$_tag deleteInvestment: $investmentId');
    return _remote.deleteInvestment(investmentId);
  }

  // ───────────────── CACHE ─────────────────

  /// Cache daftar investasi secara manual.
  void cacheInvestmentList(List<InvestmentModel> investments) {
    _local.cacheInvestments(investments);
  }

  /// Hapus cache investasi.
  void clearCache() {
    _local.clearCache();
  }

  // ───────────────── PORTFOLIO CALCULATION ─────────────────

  /// Hitung total nilai investasi saat ini.
  static double calculateTotalValue(List<InvestmentModel> investments) {
    return investments.fold(0.0, (sum, i) => sum + i.currentValue);
  }

  /// Hitung total modal (invested).
  static double calculateTotalInvested(List<InvestmentModel> investments) {
    return investments.fold(0.0, (sum, i) => sum + i.investedValue);
  }

  /// Hitung total unrealized P/L.
  static double calculateTotalPL(List<InvestmentModel> investments) {
    return investments.fold(0.0, (sum, i) => sum + i.unrealizedPL);
  }

  /// Hitung persentase P/L portfolio keseluruhan.
  static double calculateTotalPLPercent(List<InvestmentModel> investments) {
    final totalInvested = calculateTotalInvested(investments);
    if (totalInvested == 0) return 0;
    return calculateTotalPL(investments) / totalInvested;
  }
}
