import 'dart:async';

import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/features/category/controllers/category_controller.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/voice/models/voice_parse_result_model.dart';
import 'package:app_saku_rapi/features/voice/repositories/voice_repository.dart';
import 'package:app_saku_rapi/features/voice/services/voice_input_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// ═══════════════ Providers ═══════════════

/// Singleton repository provider.
final voiceRepositoryProvider = Provider<VoiceRepository>(
  (ref) => VoiceRepository(),
);

/// Singleton service provider.
final voiceInputServiceProvider = Provider<VoiceInputService>(
  (ref) => VoiceInputService(),
);

/// Controller provider, auto-disposed saat sheet ditutup.
final voiceInputControllerProvider =
    StateNotifierProvider.autoDispose<VoiceInputController, VoiceInputState>(
      (ref) => VoiceInputController(
        repository: ref.watch(voiceRepositoryProvider),
        service: ref.watch(voiceInputServiceProvider),
        categories: ref
            .read(categoryControllerProvider)
            .categories
            .where((c) => c.type != CategoryType.system && !c.isHidden)
            .toList(),
      ),
    );

// ═══════════════ State ═══════════════

/// Status keseluruhan flow voice input.
enum VoiceInputStatus {
  /// Idle, belum mulai.
  idle,

  /// Sedang mempersiapkan mikrofon.
  initializing,

  /// Sedang merekam / mendengarkan suara.
  listening,

  /// Rekaman selesai, sedang proses AI.
  processing,

  /// Hasil parsing siap.
  done,

  /// Error (permission denied, STT gagal, AI gagal).
  error,

  /// Permission ditolak permanen → perlu buka settings.
  permissionDenied,
}

/// Immutable state untuk voice input flow.
class VoiceInputState {
  const VoiceInputState({
    this.status = VoiceInputStatus.idle,
    this.transcript = '',
    this.parseResult,
    this.errorMessage,
    this.remainingSeconds = 10,
    this.isPermanentlyDenied = false,
  });

  /// Status flow saat ini.
  final VoiceInputStatus status;

  /// Teks transkripsi dari STT (partial/final).
  final String transcript;

  /// Hasil parsing AI/local.
  final VoiceParseResultModel? parseResult;

  /// Pesan error jika ada.
  final String? errorMessage;

  /// Sisa detik rekaman (countdown dari 10).
  final int remainingSeconds;

  /// True jika mic permission permanently denied.
  final bool isPermanentlyDenied;

  VoiceInputState copyWith({
    VoiceInputStatus? status,
    String? transcript,
    VoiceParseResultModel? parseResult,
    String? errorMessage,
    int? remainingSeconds,
    bool? isPermanentlyDenied,
  }) {
    return VoiceInputState(
      status: status ?? this.status,
      transcript: transcript ?? this.transcript,
      parseResult: parseResult ?? this.parseResult,
      errorMessage: errorMessage ?? this.errorMessage,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isPermanentlyDenied: isPermanentlyDenied ?? this.isPermanentlyDenied,
    );
  }
}

// ═══════════════ Controller ═══════════════

/// Controller yang mengelola seluruh flow voice input:
///
/// 1. Request mic permission
/// 2. Initialize STT
/// 3. Start listening (max 10 detik)
/// 4. Kirim transcript ke AI parser
/// 5. Return [VoiceParseResultModel] untuk prefill form
class VoiceInputController extends StateNotifier<VoiceInputState> {
  VoiceInputController({
    required VoiceRepository repository,
    required VoiceInputService service,
    List<CategoryModel> categories = const [],
  }) : _repository = repository,
       _service = service,
       _categories = categories,
       super(const VoiceInputState());

  final VoiceRepository _repository;
  final VoiceInputService _service;
  final List<CategoryModel> _categories;

  static const _tag = '[Voice] [VoiceInputController]';

  Timer? _countdownTimer;

  /// Mulai flow voice input dari awal.
  ///
  /// Pipeline: permission → init STT → listen → transcript → AI parse.
  Future<void> startVoiceInput() async {
    AppLogger.call('$_tag startVoiceInput');

    // ── Step 1: Request mic permission ──
    state = state.copyWith(status: VoiceInputStatus.initializing);

    final permResult = await _service.requestMicPermission();

    switch (permResult) {
      case MicPermissionResult.granted:
        break; // proceed
      case MicPermissionResult.permanentlyDenied:
        state = state.copyWith(
          status: VoiceInputStatus.permissionDenied,
          isPermanentlyDenied: true,
        );
        return;
      case MicPermissionResult.denied:
        state = state.copyWith(
          status: VoiceInputStatus.permissionDenied,
          isPermanentlyDenied: false,
        );
        return;
    }

    // ── Step 2: Initialize STT ──
    final initialized = await _service.initialize();
    if (!initialized) {
      state = state.copyWith(
        status: VoiceInputStatus.error,
        errorMessage: 'Speech recognition not available',
      );
      return;
    }

    // ── Step 3: Start listening ──
    state = state.copyWith(
      status: VoiceInputStatus.listening,
      transcript: '',
      remainingSeconds: 10,
    );

    _startCountdown();

    await _service.startListening(
      onResult: (result) {
        if (!mounted) return;
        state = state.copyWith(transcript: result.recognizedWords);

        // Jika final result → proses ke AI
        if (result.finalResult) {
          _onFinalResult(result.recognizedWords);
        }
      },
    );
  }

  /// Stop rekaman secara manual dan proses transcript yang ada.
  Future<void> stopAndProcess() async {
    AppLogger.call('$_tag stopAndProcess');
    _stopCountdown();
    await _service.stopListening();

    if (state.transcript.isNotEmpty) {
      await _processTranscript(state.transcript);
    } else {
      state = state.copyWith(
        status: VoiceInputStatus.error,
        errorMessage: 'no_speech',
      );
    }
  }

  /// Cancel seluruh flow.
  Future<void> cancel() async {
    AppLogger.call('$_tag cancel');
    _stopCountdown();
    await _service.cancelListening();
    state = const VoiceInputState();
  }

  /// Reset state ke idle.
  void reset() {
    _stopCountdown();
    state = const VoiceInputState();
  }

  /// Buka app settings untuk izin mikrofon.
  Future<void> openSettings() async {
    await _service.openSystemSettings();
  }

  // ─── Private methods ───

  /// Handle final result dari STT.
  void _onFinalResult(String transcript) {
    _stopCountdown();
    if (transcript.isNotEmpty) {
      _processTranscript(transcript);
    } else {
      state = state.copyWith(
        status: VoiceInputStatus.error,
        errorMessage: 'no_speech',
      );
    }
  }

  /// Kirim transcript ke AI parser pipeline.
  Future<void> _processTranscript(String transcript) async {
    AppLogger.call('$_tag _processTranscript: "$transcript"');
    state = state.copyWith(status: VoiceInputStatus.processing);

    // Siapkan daftar kategori untuk AI categorization (termasuk type)
    final categoryMaps = _categories
        .map((c) => {'id': c.id, 'name': c.name, 'type': c.type.name})
        .toList();

    final result = await _repository.parseVoiceText(
      transcript,
      categories: categoryMaps,
    );

    if (!mounted) return;

    if (result.isSuccess()) {
      final parsed = result.dataSuccess()!;

      // Edge case: AI menentukan ini bukan transaksi
      if (!parsed.isTransaction) {
        state = state.copyWith(
          status: VoiceInputStatus.error,
          errorMessage: 'not_transaction',
        );
        return;
      }

      state = state.copyWith(
        status: VoiceInputStatus.done,
        parseResult: parsed,
      );
    } else {
      final (msg, _, _, _) = result.dataError()!;
      state = state.copyWith(status: VoiceInputStatus.error, errorMessage: msg);
    }
  }

  /// Start countdown timer (10 → 0).
  void _startCountdown() {
    _stopCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final remaining = state.remainingSeconds - 1;
      if (remaining <= 0) {
        timer.cancel();
        // Auto-stop ketika waktu habis
        stopAndProcess();
      } else {
        state = state.copyWith(remainingSeconds: remaining);
      }
    });
  }

  /// Stop countdown timer.
  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  @override
  void dispose() {
    _stopCountdown();
    _service.cancelListening();
    super.dispose();
  }
}
