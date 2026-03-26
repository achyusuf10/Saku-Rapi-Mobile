import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/investment/datasource/asset_type_remote_data_source.dart';
import 'package:app_saku_rapi/features/investment/models/asset_type_model.dart';

/// Repository untuk jenis aset kustom.
///
/// Mengorkestrasikan [AssetTypeRemoteDataSource] dengan validasi domain.
class AssetTypeRepository {
  AssetTypeRepository({AssetTypeRemoteDataSource? remoteDataSource})
    : _remote = remoteDataSource ?? AssetTypeRemoteDataSource();

  final AssetTypeRemoteDataSource _remote;

  static const _tag = '[Investment] [AssetTypeRepository]';

  // ───────────────── READ ─────────────────

  /// Ambil semua jenis aset aktif.
  Future<DataState<List<AssetTypeModel>>> getAssetTypes() async {
    return _remote.getAssetTypes();
  }

  // ───────────────── VALIDATION ─────────────────

  /// Validasi input jenis aset.
  /// Mengembalikan pesan error, atau `null` jika valid.
  static String? validateInput({
    required String name,
    required double currentPrice,
  }) {
    if (name.trim().isEmpty) return 'Nama jenis aset wajib diisi';
    if (currentPrice < 0) return 'Harga tidak boleh negatif';
    return null;
  }

  // ───────────────── CREATE ─────────────────

  /// Buat jenis aset baru setelah validasi.
  Future<DataState<AssetTypeModel>> createAssetType({
    required String name,
    String? symbol,
    required double currentPrice,
  }) async {
    final error = validateInput(name: name, currentPrice: currentPrice);
    if (error != null) {
      return DataState.error(message: error);
    }

    AppLogger.call('$_tag createAssetType: $name');
    return _remote.createAssetType(
      name: name,
      symbol: symbol,
      currentPrice: currentPrice,
    );
  }

  // ───────────────── UPDATE ─────────────────

  /// Update jenis aset.
  Future<DataState<AssetTypeModel>> updateAssetType({
    required String id,
    required String name,
    String? symbol,
    required double currentPrice,
  }) async {
    final error = validateInput(name: name, currentPrice: currentPrice);
    if (error != null) {
      return DataState.error(message: error);
    }

    AppLogger.call('$_tag updateAssetType: $id');
    return _remote.updateAssetType(
      id: id,
      name: name,
      symbol: symbol,
      currentPrice: currentPrice,
    );
  }

  // ───────────────── DELETE ─────────────────

  /// Soft delete jenis aset.
  Future<DataState<void>> deleteAssetType(String id) async {
    AppLogger.call('$_tag deleteAssetType: $id');
    return _remote.deleteAssetType(id);
  }
}
