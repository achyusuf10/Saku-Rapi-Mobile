import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/investment/controllers/investment_controller.dart';
import 'package:app_saku_rapi/features/investment/models/asset_type_model.dart';
import 'package:app_saku_rapi/features/investment/repositories/asset_type_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// ═══════════════ Providers ═══════════════

/// Singleton repository provider.
final assetTypeRepositoryProvider = Provider<AssetTypeRepository>((ref) {
  return AssetTypeRepository();
});

/// Controller utama untuk list + CRUD jenis aset.
final assetTypeControllerProvider =
    StateNotifierProvider<AssetTypeController, AssetTypeState>((ref) {
      final repository = ref.watch(assetTypeRepositoryProvider);
      return AssetTypeController(repository, ref);
    });

/// Daftar jenis aset aktif (non-deleted).
final assetTypeListProvider = Provider<List<AssetTypeModel>>((ref) {
  final state = ref.watch(assetTypeControllerProvider);
  return state.assetTypes;
});

// ═══════════════ State ═══════════════

enum AssetTypeStatus { initial, loading, loaded, error }

/// State untuk daftar jenis aset.
class AssetTypeState {
  const AssetTypeState({
    this.status = AssetTypeStatus.initial,
    this.assetTypes = const [],
    this.errorMessage,
  });

  final AssetTypeStatus status;
  final List<AssetTypeModel> assetTypes;
  final String? errorMessage;

  bool get isLoading => status == AssetTypeStatus.loading;
  bool get isEmpty => assetTypes.isEmpty && status == AssetTypeStatus.loaded;

  AssetTypeState copyWith({
    AssetTypeStatus? status,
    List<AssetTypeModel>? assetTypes,
    String? errorMessage,
  }) {
    return AssetTypeState(
      status: status ?? this.status,
      assetTypes: assetTypes ?? this.assetTypes,
      errorMessage: errorMessage,
    );
  }
}

// ═══════════════ Controller ═══════════════

/// Controller untuk CRUD jenis aset kustom.
class AssetTypeController extends StateNotifier<AssetTypeState> {
  AssetTypeController(this._repository, this._ref)
    : super(const AssetTypeState());

  final AssetTypeRepository _repository;
  final Ref _ref;

  /// Load semua jenis aset aktif.
  Future<void> loadAssetTypes() async {
    state = state.copyWith(status: AssetTypeStatus.loading);

    final result = await _repository.getAssetTypes();

    result.map(
      success: (data) {
        state = state.copyWith(
          status: AssetTypeStatus.loaded,
          assetTypes: data.data,
        );
      },
      error: (error) {
        state = state.copyWith(
          status: AssetTypeStatus.error,
          errorMessage: error.message,
        );
      },
    );
  }

  /// Buat jenis aset baru.
  Future<DataState<AssetTypeModel>> createAssetType({
    required String name,
    String? symbol,
    required double currentPrice,
  }) async {
    final isDuplicate = state.assetTypes.any(
      (t) => t.name.trim().toLowerCase() == name.trim().toLowerCase(),
    );
    if (isDuplicate) {
      return DataState.error(message: 'DUPLICATE:$name');
    }

    final result = await _repository.createAssetType(
      name: name,
      symbol: symbol,
      currentPrice: currentPrice,
    );

    if (result.isSuccess()) {
      final created = result.dataSuccess()!;
      state = state.copyWith(
        assetTypes: [...state.assetTypes, created]
          ..sort((a, b) => a.name.compareTo(b.name)),
      );
    }

    return result;
  }

  /// Update jenis aset.
  Future<DataState<AssetTypeModel>> updateAssetType({
    required String id,
    required String name,
    String? symbol,
    required double currentPrice,
  }) async {
    final isDuplicate = state.assetTypes.any(
      (t) =>
          t.id != id &&
          t.name.trim().toLowerCase() == name.trim().toLowerCase(),
    );
    if (isDuplicate) {
      return DataState.error(message: 'DUPLICATE:$name');
    }

    final result = await _repository.updateAssetType(
      id: id,
      name: name,
      symbol: symbol,
      currentPrice: currentPrice,
    );

    if (result.isSuccess()) {
      final updated = result.dataSuccess()!;
      final list = state.assetTypes.map((t) {
        return t.id == id ? updated : t;
      }).toList()..sort((a, b) => a.name.compareTo(b.name));
      state = state.copyWith(assetTypes: list);
    }

    return result;
  }

  /// Soft delete jenis aset.
  Future<DataState<void>> deleteAssetType(String id) async {
    final result = await _repository.deleteAssetType(id);

    if (result.isSuccess()) {
      final list = state.assetTypes.where((t) => t.id != id).toList();
      state = state.copyWith(assetTypes: list);
      // Remove investments using this asset type from investment list immediately.
      _ref.read(investmentControllerProvider.notifier).removeByAssetTypeId(id);
    }

    return result;
  }
}
