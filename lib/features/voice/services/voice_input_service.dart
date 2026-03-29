import 'package:app_saku_rapi/core/constants/app_constants.dart';
import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Status rekaman suara.
enum VoiceRecordingStatus {
  /// Belum mulai / idle.
  idle,

  /// Mempersiapkan mikrofon (initializing STT).
  initializing,

  /// Sedang mendengarkan / merekam.
  listening,

  /// Selesai merekam (ada hasil transkripsi).
  done,

  /// Error (permission denied, STT gagal, dsb).
  error,
}

/// Service pembungkus `speech_to_text` + `permission_handler`.
///
/// Menangani:
/// - Request izin mikrofon (just in time)
/// - Start/stop speech recognition
/// - Callback saat ada partial/final result
/// - Timeout maksimum 10 detik (PRD §7.5)
class VoiceInputService {
  VoiceInputService({SpeechToText? speech})
    : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;

  static const _tag = '[Voice] [VoiceInputService]';

  /// Maksimum durasi rekaman (PRD §7.5: 10 detik).
  static final maxListenDuration = Duration(
    seconds: AppConstants.voiceMaxDurationSeconds,
  );

  /// Pause threshold sebelum finalizing.
  static final pauseForDuration = Duration(
    seconds: AppConstants.voicePauseDurationSeconds,
  );

  bool _isInitialized = false;

  /// Cek dan minta izin mikrofon.
  ///
  /// Returns `true` jika izin granted, `false` jika denied.
  /// Jika permanently denied, caller harus arahkan ke settings.
  Future<MicPermissionResult> requestMicPermission() async {
    AppLogger.call('$_tag requestMicPermission');
    final status = await Permission.microphone.request();

    if (status.isGranted) {
      return MicPermissionResult.granted;
    } else if (status.isPermanentlyDenied) {
      return MicPermissionResult.permanentlyDenied;
    } else {
      return MicPermissionResult.denied;
    }
  }

  /// Inisialisasi speech-to-text engine.
  ///
  /// Harus dipanggil sebelum `startListening`.
  /// Akan otomatis skip jika sudah initialized.
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    AppLogger.call('$_tag initialize');
    _isInitialized = await _speech.initialize(
      onError: (error) {
        AppLogger.logError('$_tag STT Error: ${error.errorMsg}');
      },
      onStatus: (status) {
        AppLogger.call('$_tag STT Status: $status');
      },
    );
    AppLogger.call('$_tag initialized: $_isInitialized');
    return _isInitialized;
  }

  /// Mulai mendengarkan suara.
  ///
  /// [onResult] dipanggil setiap ada partial/final result.
  /// [onSoundLevelChange] dipanggil saat level suara berubah.
  /// Otomatis berhenti setelah [maxListenDuration].
  Future<void> startListening({
    required void Function(SpeechRecognitionResult result) onResult,
    void Function(double level)? onSoundLevelChange,
    String localeId = 'id_ID',
  }) async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) throw Exception('STT initialization failed');
    }

    AppLogger.call('$_tag startListening (locale: $localeId)');
    await _speech.listen(
      onResult: onResult,
      onSoundLevelChange: onSoundLevelChange,
      listenFor: maxListenDuration,
      pauseFor: pauseForDuration,
      localeId: localeId,
      listenOptions: SpeechListenOptions(
        cancelOnError: false,
        partialResults: true,
        autoPunctuation: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  /// Stop mendengarkan.
  Future<void> stopListening() async {
    AppLogger.call('$_tag stopListening');
    await _speech.stop();
  }

  /// Cancel listening tanpa hasil.
  Future<void> cancelListening() async {
    AppLogger.call('$_tag cancelListening');
    await _speech.cancel();
  }

  /// Apakah sedang mendengarkan.
  bool get isListening => _speech.isListening;

  /// Buka app settings (jika permission permanently denied).
  Future<bool> openSystemSettings() async {
    return openAppSettings();
  }
}

/// Hasil request izin mikrofon.
enum MicPermissionResult { granted, denied, permanentlyDenied }
