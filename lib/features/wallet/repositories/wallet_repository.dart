import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/wallet/datasource/wallet_remote_data_source.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';

/// Orkestrator utama untuk fitur Wallet.
///
/// Memanggil [WalletRemoteDataSource] dan menangani hasilnya
/// menggunakan pattern matching `.map(success:, error:)` dari [DataState].
class WalletRepository {
  WalletRepository({required WalletRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final WalletRemoteDataSource _remoteDataSource;

  static const String _tag = 'Wallet';

  /// Mengambil semua wallet milik user.
  Future<DataState<List<WalletModel>>> getWallets() async {
    final result = await _remoteDataSource.getWallets();

    return result.map(
      success: (data) {
        AppLogger.call(
          '[$_tag] Berhasil memuat ${data.data.length} wallet',
          colorLog: ColorLog.green,
        );
        return DataState.success(data: data.data);
      },
      error: (err) {
        AppLogger.logError(
          '[$_tag] Gagal memuat wallet: ${err.message}',
          runtimeType: WalletRepository,
        );
        return DataState.error(message: err.message, errorData: err.errorData);
      },
    );
  }

  /// Mengambil satu wallet berdasarkan [walletId].
  Future<DataState<WalletModel>> getWalletById(String walletId) async {
    final result = await _remoteDataSource.getWalletById(walletId);

    return result.map(
      success: (data) {
        AppLogger.call(
          '[$_tag] Berhasil memuat wallet: ${data.data.name}',
          colorLog: ColorLog.green,
        );
        return DataState.success(data: data.data);
      },
      error: (err) {
        AppLogger.logError(
          '[$_tag] Gagal memuat wallet ($walletId): ${err.message}',
          runtimeType: WalletRepository,
        );
        return DataState.error(message: err.message, errorData: err.errorData);
      },
    );
  }

  /// Membuat wallet baru.
  Future<DataState<WalletModel>> createWallet(WalletModel wallet) async {
    final result = await _remoteDataSource.createWallet(wallet);

    return result.map(
      success: (data) {
        AppLogger.call(
          '[$_tag] Wallet "${data.data.name}" berhasil dibuat',
          colorLog: ColorLog.green,
        );
        return DataState.success(data: data.data);
      },
      error: (err) {
        AppLogger.logError(
          '[$_tag] Gagal membuat wallet: ${err.message}',
          runtimeType: WalletRepository,
        );
        return DataState.error(message: err.message, errorData: err.errorData);
      },
    );
  }

  /// Memperbarui data wallet.
  Future<DataState<WalletModel>> updateWallet(WalletModel wallet) async {
    final result = await _remoteDataSource.updateWallet(wallet);

    return result.map(
      success: (data) {
        AppLogger.call(
          '[$_tag] Wallet "${data.data.name}" berhasil diperbarui',
          colorLog: ColorLog.green,
        );
        return DataState.success(data: data.data);
      },
      error: (err) {
        AppLogger.logError(
          '[$_tag] Gagal memperbarui wallet: ${err.message}',
          runtimeType: WalletRepository,
        );
        return DataState.error(message: err.message, errorData: err.errorData);
      },
    );
  }

  /// Menghapus wallet berdasarkan [walletId].
  Future<DataState<String>> deleteWallet(String walletId) async {
    final result = await _remoteDataSource.deleteWallet(walletId);

    return result.map(
      success: (_) {
        AppLogger.call(
          '[$_tag] Wallet ($walletId) berhasil dihapus',
          colorLog: ColorLog.green,
        );
        return DataState.success(data: 'Berhasil menghapus wallet ($walletId)');
      },
      error: (err) {
        AppLogger.logError(
          '[$_tag] Gagal menghapus wallet ($walletId): ${err.message}',
          runtimeType: WalletRepository,
        );
        return DataState.error(message: err.message, errorData: err.errorData);
      },
    );
  }

  /// Menyesuaikan saldo wallet dengan membuat transaksi adjustment.
  ///
  /// [walletId] — wallet yang dikoreksi.
  /// [userId] — user ID pemilik wallet.
  /// [delta] — selisih saldo (actual - current).
  Future<DataState<void>> adjustBalance({
    required String walletId,
    required String userId,
    required double delta,
  }) async {
    final result = await _remoteDataSource.adjustBalance(
      walletId: walletId,
      userId: userId,
      delta: delta,
    );

    return result.map(
      success: (_) {
        AppLogger.call(
          '[$_tag] Saldo wallet ($walletId) disesuaikan: delta=$delta',
          colorLog: ColorLog.green,
        );
        return const DataState.success(data: null);
      },
      error: (err) {
        AppLogger.logError(
          '[$_tag] Gagal menyesuaikan saldo ($walletId): ${err.message}',
          runtimeType: WalletRepository,
        );
        return DataState.error(message: err.message, errorData: err.errorData);
      },
    );
  }
}
