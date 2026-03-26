import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/network/supabase_handler.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/investment/models/asset_type_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source untuk jenis aset kustom (CRUD).
///
/// Semua operasi menggunakan REST langsung ke tabel `asset_types`.
/// Soft delete: update `is_deleted = true` (bukan hard delete).
class AssetTypeRemoteDataSource {
  AssetTypeRemoteDataSource({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _table = 'asset_types';
  static const _tag = '[Investment] [AssetTypeRemoteDataSource]';

  String get _userId => _client.auth.currentUser!.id;

  // ───────────────── READ ─────────────────

  /// Ambil semua jenis aset aktif (non-deleted) milik user.
  Future<DataState<List<AssetTypeModel>>> getAssetTypes() {
    return SupabaseHandler.call<List<AssetTypeModel>>(
      function: () async {
        AppLogger.call('$_tag getAssetTypes');

        final response = await _client
            .from(_table)
            .select()
            .eq('user_id', _userId)
            .eq('is_deleted', false)
            .order('name', ascending: true);

        return response.map((e) => AssetTypeModel.fromMap(e)).toList();
      },
    );
  }

  // ───────────────── CREATE ─────────────────

  /// Buat jenis aset baru.
  Future<DataState<AssetTypeModel>> createAssetType({
    required String name,
    String? symbol,
    required double currentPrice,
  }) {
    return SupabaseHandler.call<AssetTypeModel>(
      function: () async {
        AppLogger.call('$_tag createAssetType: $name');

        final response = await _client
            .from(_table)
            .insert({
              'user_id': _userId,
              'name': name,
              'symbol': symbol,
              'current_price': currentPrice,
            })
            .select()
            .single();

        return AssetTypeModel.fromMap(response);
      },
    );
  }

  // ───────────────── UPDATE ─────────────────

  /// Update jenis aset.
  Future<DataState<AssetTypeModel>> updateAssetType({
    required String id,
    required String name,
    String? symbol,
    required double currentPrice,
  }) {
    return SupabaseHandler.call<AssetTypeModel>(
      function: () async {
        AppLogger.call('$_tag updateAssetType: $id');

        final response = await _client
            .from(_table)
            .update({
              'name': name,
              'symbol': symbol,
              'current_price': currentPrice,
            })
            .eq('id', id)
            .eq('user_id', _userId)
            .select()
            .single();

        return AssetTypeModel.fromMap(response);
      },
    );
  }

  // ───────────────── SOFT DELETE ─────────────────

  /// Soft delete jenis aset (set is_deleted = true).
  Future<DataState<void>> deleteAssetType(String id) {
    return SupabaseHandler.call<void>(
      function: () async {
        AppLogger.call('$_tag deleteAssetType (soft): $id');

        await _client
            .from(_table)
            .update({'is_deleted': true})
            .eq('id', id)
            .eq('user_id', _userId);
      },
    );
  }
}
