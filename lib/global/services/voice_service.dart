import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Wrapper service untuk `speech_to_text` package.
///
/// Mengelola lifecycle rekam suara: init, start, stop.
/// Auto-stop saat hening ([pauseFor]) atau durasi habis ([maxDuration]).
class VoiceService {
  VoiceService() : _speech = SpeechToText();

  final SpeechToText _speech;

  static const String _tag = 'VoiceInput';

  /// `true` jika sedang aktif merekam suara.
  bool get isListening => _speech.isListening;

  /// `true` jika speech_to_text berhasil diinisialisasi.
  bool get isAvailable => _speech.isAvailable;

  /// Inisialisasi engine speech recognition.
  ///
  /// Return `true` jika berhasil dan permission diberikan.
  Future<bool> initialize() async {
    AppLogger.call(
      '[$_tag] Inisialisasi speech engine...',
      colorLog: ColorLog.blue,
    );

    final available = await _speech.initialize(
      onError: _onError,
      onStatus: _onStatus,
    );

    AppLogger.call(
      '[$_tag] Speech engine available: $available',
      colorLog: available ? ColorLog.green : ColorLog.red,
    );

    return available;
  }

  /// Mulai merekam suara.
  ///
  /// [onResult] dipanggil real-time saat teks terdeteksi.
  /// [onDone] dipanggil saat rekaman selesai (manual/timeout/silence).
  /// [onError] dipanggil jika terjadi error.
  /// [maxDuration] batas waktu maksimum rekaman (default 10s).
  /// [pauseFor] auto-stop jika hening selama durasi ini (default 3s).
  Future<void> startListening({
    required void Function(String text) onResult,
    required void Function() onDone,
    required void Function(String error) onError,
    Duration maxDuration = const Duration(seconds: 10),
    Duration pauseFor = const Duration(seconds: 3),
  }) async {
    if (!_speech.isAvailable) {
      onError('Speech engine not available');
      return;
    }

    AppLogger.call('[$_tag] Mulai rekam', colorLog: ColorLog.blue);

    _onDoneCallback = onDone;
    _onErrorCallback = onError;

    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        onResult(result.recognizedWords);
        if (result.finalResult) {
          AppLogger.call(
            '[$_tag] Final result: ${result.recognizedWords}',
            colorLog: ColorLog.green,
          );
          _onDoneCallback?.call();
        }
      },
      listenFor: maxDuration,
      pauseFor: pauseFor,
      localeId: 'id_ID',
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        cancelOnError: true,
      ),
    );
  }

  /// Stop rekaman secara manual.
  Future<void> stopListening() async {
    AppLogger.call('[$_tag] Stop rekam (manual)', colorLog: ColorLog.yellow);
    await _speech.stop();
  }

  /// Dispose resources.
  void dispose() {
    _speech.cancel();
    _onDoneCallback = null;
    _onErrorCallback = null;
  }

  // ─────────────────────────────────────────────────────
  // Internal callbacks
  // ─────────────────────────────────────────────────────

  void Function()? _onDoneCallback;
  void Function(String error)? _onErrorCallback;

  void _onError(SpeechRecognitionError error) {
    AppLogger.logError(
      '[$_tag] Error: ${error.errorMsg} (permanent: ${error.permanent})',
      runtimeType: VoiceService,
    );
    if (error.permanent) {
      _onErrorCallback?.call(error.errorMsg);
    }
  }

  void _onStatus(String status) {
    AppLogger.call('[$_tag] Status: $status', colorLog: ColorLog.blue);
    if (status == 'done' || status == 'notListening') {
      _onDoneCallback?.call();
    }
  }
}
