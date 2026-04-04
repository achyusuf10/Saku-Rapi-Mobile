import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/investment/controllers/investment_controller.dart';
import 'package:app_saku_rapi/features/investment/models/investment_asset_model.dart';
import 'package:app_saku_rapi/features/investment/models/investment_transaction_model.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// ═══════════════ Provider ═══════════════

/// Form controller provider, auto-disposed saat page ditutup.
final investmentFormControllerProvider =
    StateNotifierProvider.autoDispose<
      InvestmentFormController,
      InvestmentFormState
    >((ref) => InvestmentFormController(ref: ref));

// ═══════════════ Enums ═══════════════

/// Mode form: create, topup, atau edit.
enum InvestmentFormMode { create, topup, edit }

/// Status form investasi.
enum InvestmentFormStatus { idle, saving, saved, error }

// ═══════════════ State ═══════════════

/// Immutable state untuk form investasi.
///
/// Menyimpan semua field form: type, gold type, price source, wallet, dsb.
/// Controller memodifikasi via `copyWith`.
class InvestmentFormState {
  const InvestmentFormState({
    this.status = InvestmentFormStatus.idle,
    this.mode = InvestmentFormMode.create,
    this.existingAsset,
    this.existingTx,
    this.selectedType = InvestmentType.gold,
    this.selectedGoldType,
    this.selectedCustomGoldTypeId,
    this.selectedCustomCategoryId,
    this.selectedPriceSource = 'antaremas',
    this.selectedDate,
    this.deductWallet = false,
    this.selectedWallet,
    this.errorMessage,
  });

  final InvestmentFormStatus status;
  final InvestmentFormMode mode;
  final InvestmentAssetModel? existingAsset;
  final InvestmentTransactionModel? existingTx;

  final InvestmentType selectedType;
  final String? selectedGoldType;
  final String? selectedCustomGoldTypeId;
  final String? selectedCustomCategoryId;
  final String selectedPriceSource;
  final DateTime? selectedDate;
  final bool deductWallet;
  final WalletModel? selectedWallet;
  final String? errorMessage;

  bool get isSaving => status == InvestmentFormStatus.saving;
  bool get isEditing => existingTx != null;

  /// Apakah price source terkunci (non-antam gold types → paksa manual).
  bool get isPriceSourceLocked =>
      selectedGoldType != null && selectedGoldType != 'antam';

  /// Apakah current price field harus ditampilkan.
  bool get showCurrentPriceField =>
      mode == InvestmentFormMode.create && selectedPriceSource == 'manual';

  InvestmentFormState copyWith({
    InvestmentFormStatus? status,
    InvestmentFormMode? mode,
    InvestmentAssetModel? existingAsset,
    InvestmentTransactionModel? existingTx,
    InvestmentType? selectedType,
    String? selectedGoldType,
    String? selectedCustomGoldTypeId,
    String? selectedCustomCategoryId,
    String? selectedPriceSource,
    DateTime? selectedDate,
    bool? deductWallet,
    WalletModel? selectedWallet,
    String? errorMessage,
  }) {
    return InvestmentFormState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
      existingAsset: existingAsset ?? this.existingAsset,
      existingTx: existingTx ?? this.existingTx,
      selectedType: selectedType ?? this.selectedType,
      selectedGoldType: selectedGoldType ?? this.selectedGoldType,
      selectedCustomGoldTypeId:
          selectedCustomGoldTypeId ?? this.selectedCustomGoldTypeId,
      selectedCustomCategoryId:
          selectedCustomCategoryId ?? this.selectedCustomCategoryId,
      selectedPriceSource: selectedPriceSource ?? this.selectedPriceSource,
      selectedDate: selectedDate ?? this.selectedDate,
      deductWallet: deductWallet ?? this.deductWallet,
      selectedWallet: selectedWallet ?? this.selectedWallet,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Buat copy dengan nullable fields di-clear secara eksplisit.
  InvestmentFormState clearFields({
    bool clearGoldType = false,
    bool clearCustomGoldTypeId = false,
    bool clearCustomCategoryId = false,
    bool clearWallet = false,
    bool clearError = false,
    bool clearExistingAsset = false,
    bool clearExistingTx = false,
  }) {
    return InvestmentFormState(
      status: status,
      mode: mode,
      existingAsset: clearExistingAsset ? null : existingAsset,
      existingTx: clearExistingTx ? null : existingTx,
      selectedType: selectedType,
      selectedGoldType: clearGoldType ? null : selectedGoldType,
      selectedCustomGoldTypeId: clearCustomGoldTypeId
          ? null
          : selectedCustomGoldTypeId,
      selectedCustomCategoryId: clearCustomCategoryId
          ? null
          : selectedCustomCategoryId,
      selectedPriceSource: selectedPriceSource,
      selectedDate: selectedDate,
      deductWallet: deductWallet,
      selectedWallet: clearWallet ? null : selectedWallet,
      errorMessage: clearError ? null : errorMessage,
    );
  }
}

// ═══════════════ Controller ═══════════════

/// Controller form investasi.
///
/// Mengelola semua state form: type selection, gold type, price source,
/// wallet picker, date, dan submit create/topup/edit.
class InvestmentFormController extends StateNotifier<InvestmentFormState> {
  InvestmentFormController({required Ref ref})
    : _ref = ref,
      super(InvestmentFormState(selectedDate: DateTime.now()));

  final Ref _ref;

  // ─── Initialization ───

  /// Inisialisasi form dari GoRouter extra data.
  void initFromExtra(Object? extra) {
    if (extra == null) {
      state = state.copyWith(mode: InvestmentFormMode.create);
      return;
    }

    final data = extra as Map<String, dynamic>;
    final modeStr = data['mode'] as String? ?? 'create';
    final asset = data['asset'] as InvestmentAssetModel?;
    final tx = data['transaction'] as InvestmentTransactionModel?;

    switch (modeStr) {
      case 'topup':
        state = state.copyWith(
          mode: InvestmentFormMode.topup,
          existingAsset: asset,
          selectedType: asset?.type ?? InvestmentType.gold,
        );

      case 'edit':
        state = state.copyWith(
          mode: InvestmentFormMode.edit,
          existingAsset: asset,
          existingTx: tx,
          selectedType: asset?.type ?? InvestmentType.gold,
          selectedDate: tx?.date ?? DateTime.now(),
          deductWallet: tx?.deductWallet ?? false,
        );

      default:
        state = state.copyWith(mode: InvestmentFormMode.create);
    }
  }

  // ─── Setters ───

  /// Ganti tipe investasi (gold/bitcoin/custom).
  /// Reset gold type, custom category, dan sesuaikan price source default.
  void setType(InvestmentType type) {
    state = state
        .copyWith(
          selectedType: type,
          selectedPriceSource: _getDefaultPriceSource(type),
        )
        .clearFields(
          clearGoldType: true,
          clearCustomGoldTypeId: true,
          clearCustomCategoryId: true,
          clearError: true,
        );
  }

  /// Pilih jenis emas.
  /// Otomatis lock price source untuk perhiasan & custom gold types.
  void setGoldType(String? goldType, {String? customGoldTypeId}) {
    String priceSource = state.selectedPriceSource;
    if (goldType == 'perhiasan' || customGoldTypeId != null) {
      priceSource = 'manual';
    } else if (goldType == 'antam') {
      priceSource = 'antaremas';
    }

    state = state.copyWith(
      selectedGoldType: goldType,
      selectedCustomGoldTypeId: customGoldTypeId,
      selectedPriceSource: priceSource,
    );
  }

  /// Pilih sumber harga (antaremas/logammulia/manual).
  void setPriceSource(String source) {
    state = state.copyWith(selectedPriceSource: source);
  }

  /// Pilih kategori custom asset.
  void setCustomCategory(String? categoryId) {
    state = state.copyWith(selectedCustomCategoryId: categoryId);
  }

  /// Pilih tanggal transaksi.
  void setDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  /// Toggle deduct wallet.
  void setDeductWallet(bool value) {
    if (!value) {
      state = state
          .copyWith(deductWallet: false)
          .clearFields(clearWallet: true);
    } else {
      state = state.copyWith(deductWallet: true);
    }
  }

  /// Pilih wallet dari picker.
  void setWallet(WalletModel wallet) {
    state = state.copyWith(selectedWallet: wallet);
  }

  // ─── Submit ───

  /// Submit form: create, topup, atau edit.
  ///
  /// Returns DataState result. TextEditingController values dikirim
  /// dari page karena controller text tetap di page layer.
  Future<DataState> submit({
    required String name,
    required double units,
    required double pricePerUnit,
    required double fee,
    required double currentPrice,
    String? note,
  }) async {
    if (state.isSaving) {
      return const DataState.error(message: 'Already saving');
    }

    state = state.copyWith(status: InvestmentFormStatus.saving);

    final controller = _ref.read(investmentControllerProvider.notifier);

    try {
      DataState result;

      switch (state.mode) {
        case InvestmentFormMode.create:
          result = await controller.createAsset(
            type: state.selectedType.name,
            name: name,
            goldType: state.selectedType == InvestmentType.gold
                ? state.selectedGoldType
                : null,
            customGoldTypeId: state.selectedCustomGoldTypeId,
            customCategoryId: state.selectedCustomCategoryId,
            unitLabel: _getUnitLabel(),
            priceSource: _getPriceSource(),
            currentPrice: currentPrice > 0 ? currentPrice : pricePerUnit,
            units: units,
            pricePerUnit: pricePerUnit,
            fee: fee,
            date: state.selectedDate ?? DateTime.now(),
            note: note,
            deductWallet: state.deductWallet,
            walletId: state.selectedWallet?.id,
          );

        case InvestmentFormMode.topup:
          result = await controller.topupAsset(
            assetId: state.existingAsset!.id,
            units: units,
            pricePerUnit: pricePerUnit,
            fee: fee,
            date: state.selectedDate ?? DateTime.now(),
            note: note,
            deductWallet: state.deductWallet,
            walletId: state.selectedWallet?.id,
          );

        case InvestmentFormMode.edit:
          result = await controller.editTransaction(
            transactionId: state.existingTx!.id,
            units: units,
            pricePerUnit: pricePerUnit,
            fee: fee,
            date: state.selectedDate ?? DateTime.now(),
            note: note,
            deductWallet: state.existingTx!.deductWallet,
            walletId: state.existingTx!.walletId,
          );
      }

      if (result.isSuccess()) {
        state = state.copyWith(status: InvestmentFormStatus.saved);
      } else {
        final (msg, _, _, _) = result.dataError()!;
        state = state.copyWith(
          status: InvestmentFormStatus.error,
          errorMessage: msg,
        );
      }
      return result;
    } catch (e) {
      state = state.copyWith(
        status: InvestmentFormStatus.error,
        errorMessage: e.toString(),
      );
      return DataState.error(message: e.toString());
    }
  }

  /// Delete transaksi (mode edit).
  Future<DataState> deleteTransaction() async {
    if (state.existingTx == null) {
      return const DataState.error(message: 'No transaction to delete');
    }

    return _ref
        .read(investmentControllerProvider.notifier)
        .deleteTransaction(state.existingTx!.id);
  }

  // ─── Private Helpers ───

  String _getDefaultPriceSource(InvestmentType type) {
    switch (type) {
      case InvestmentType.gold:
        return 'antaremas';
      case InvestmentType.bitcoin:
        return 'indodax';
      case InvestmentType.custom:
        return 'manual';
    }
  }

  String _getUnitLabel() {
    switch (state.selectedType) {
      case InvestmentType.gold:
        return 'gram';
      case InvestmentType.bitcoin:
        return 'BTC';
      case InvestmentType.custom:
        final categoriesState = _ref.read(customAssetCategoriesProvider);
        if (categoriesState.isSuccess() &&
            state.selectedCustomCategoryId != null) {
          final cat = categoriesState
              .dataSuccess()!
              .where((c) => c.id == state.selectedCustomCategoryId)
              .firstOrNull;
          return cat?.unitLabel ?? 'unit';
        }
        return 'unit';
    }
  }

  String _getPriceSource() {
    switch (state.selectedType) {
      case InvestmentType.gold:
        return state.selectedPriceSource;
      case InvestmentType.bitcoin:
        return 'indodax';
      case InvestmentType.custom:
        return 'manual';
    }
  }
}
