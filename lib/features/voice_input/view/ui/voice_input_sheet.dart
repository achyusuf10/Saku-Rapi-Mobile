import 'dart:async';

import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/enums/alert_type_enum.dart';
import 'package:app_saku_rapi/core/extensions/context_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/parsing_dictionary/controllers/parsing_dictionary_controller.dart';
import 'package:app_saku_rapi/features/voice_input/view/widgets/voice_mic_visualizer.dart';
import 'package:app_saku_rapi/features/voice_input/view/widgets/voice_result_text.dart';
import 'package:app_saku_rapi/global/services/transaction_parser_service.dart';
import 'package:app_saku_rapi/global/services/voice_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

/// Bottom sheet utama untuk voice input.
///
/// Flow:
/// 1. Sheet muncul → request permission → mulai rekam.
/// 2. Teks real-time tampil di [VoiceResultText].
/// 3. Timer countdown 10 detik berjalan.
/// 4. Stop otomatis saat hening 3s / timer habis / user tap Stop.
/// 5. Sheet dismiss → loading overlay → parse → navigate ke TransactionForm.
class VoiceInputSheet extends ConsumerStatefulWidget {
  const VoiceInputSheet({super.key});

  @override
  ConsumerState<VoiceInputSheet> createState() => _VoiceInputSheetState();
}

class _VoiceInputSheetState extends ConsumerState<VoiceInputSheet> {
  static const int _maxSeconds = 10;

  final VoiceService _voiceService = VoiceService();
  final TransactionParserService _parserService = TransactionParserService();

  String _recognizedText = '';
  bool _isListening = false;
  bool _isDone = false;
  int _remainingSeconds = _maxSeconds;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startFlow();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _voiceService.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────
  // Flow
  // ─────────────────────────────────────────────────────

  Future<void> _startFlow() async {
    // 1. Check permission
    final status = await Permission.microphone.request();
    if (!mounted) return;

    if (!status.isGranted) {
      AppLogger.logError(
        '[VoiceInput] Microphone permission denied',
        runtimeType: VoiceInputSheet,
      );
      context.showAppAlert(
        context.l10n.voicePermissionDenied,
        alertType: AlertTypeEnum.error,
      );
      Navigator.of(context).pop();
      return;
    }

    // 2. Initialize speech engine
    final available = await _voiceService.initialize();
    if (!mounted) return;

    if (!available) {
      context.showAppAlert(
        context.l10n.voiceError,
        alertType: AlertTypeEnum.error,
      );
      Navigator.of(context).pop();
      return;
    }

    // 3. Start listening
    _startListening();
  }

  void _startListening() {
    setState(() {
      _isListening = true;
      _isDone = false;
      _remainingSeconds = _maxSeconds;
    });

    _startCountdown();

    _voiceService.startListening(
      onResult: (text) {
        if (!mounted) return;
        setState(() => _recognizedText = text);
      },
      onDone: () {
        if (!mounted || _isDone) return;
        _onRecordingDone();
      },
      onError: (error) {
        if (!mounted || _isDone) return;
        AppLogger.logError(
          '[VoiceInput] Error: $error',
          runtimeType: VoiceInputSheet,
        );
        _onRecordingDone();
      },
      maxDuration: const Duration(seconds: _maxSeconds),
      pauseFor: const Duration(seconds: 3),
    );
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _remainingSeconds--);
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _onStopTapped();
      }
    });
  }

  Future<void> _onStopTapped() async {
    if (_isDone) return;
    _countdownTimer?.cancel();
    await _voiceService.stopListening();
    if (!mounted) return;
    _onRecordingDone();
  }

  void _onRecordingDone() {
    if (_isDone) return;
    _isDone = true;
    _countdownTimer?.cancel();

    setState(() => _isListening = false);

    final rawText = _recognizedText.trim();
    if (rawText.isEmpty) {
      // Tidak ada teks terdeteksi
      if (mounted) {
        context.showAppAlert(
          context.l10n.voiceError,
          alertType: AlertTypeEnum.error,
        );
        Navigator.of(context).pop();
      }
      return;
    }

    // Dismiss sheet lalu proses
    Navigator.of(context).pop();

    // Proses di luar sheet (menggunakan navigator context)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processAndNavigate(rawText);
    });
  }

  void _processAndNavigate(String rawText) {
    final navContext = AppRouter.navigatorKey.currentContext;
    if (navContext == null) return;

    navContext.showLoadingOverlay();

    try {
      final dictionary =
          ref.read(parsingDictionaryControllerProvider).value ?? [];
      final parsedState = _parserService.parseVoiceInput(rawText, dictionary);

      navContext.closeOverlay();
      navContext.push(AppRouter.transactionForm, extra: parsedState);
    } catch (e) {
      navContext.closeOverlay();
      AppLogger.logError(
        '[VoiceInput] Parse error: $e',
        runtimeType: VoiceInputSheet,
      );
    }
  }

  // ─────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;
    final l10n = context.l10n;

    return Container(
      padding: EdgeInsets.only(
        top: 16.h,
        left: 16.w,
        right: 16.w,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
      ),
      decoration: BoxDecoration(
        color: appColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle bar ──
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: appColors.border,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 16.h),

          // ── Title ──
          Text(
            l10n.voiceListening,
            style: TextStyleConstants.h7.copyWith(
              fontWeight: FontWeight.w700,
              color: appColors.textPrimary,
            ),
          ),
          SizedBox(height: 24.h),

          // ── Mic Visualizer ──
          VoiceMicVisualizer(isListening: _isListening),
          SizedBox(height: 20.h),

          // ── Real-time text ──
          VoiceResultText(text: _recognizedText),
          SizedBox(height: 16.h),

          // ── Timer ──
          Text(
            '$_remainingSeconds / $_maxSeconds',
            style: TextStyleConstants.h6.copyWith(
              fontWeight: FontWeight.w800,
              color: _remainingSeconds <= 3
                  ? appColors.expense
                  : appColors.textPrimary,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
          SizedBox(height: 8.h),

          // ── Countdown status ──
          Text(
            l10n.voiceCountdown(_remainingSeconds),
            style: TextStyleConstants.caption.copyWith(
              color: appColors.textSecondary,
            ),
          ),
          SizedBox(height: 20.h),

          // ── Stop button ──
          GestureDetector(
            onTap: _isListening ? _onStopTapped : null,
            child: Container(
              width: 56.r,
              height: 56.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening
                    ? appColors.expense
                    : appColors.expense.withValues(alpha: 0.3),
                boxShadow: _isListening
                    ? [
                        BoxShadow(
                          color: appColors.expense.withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: FaIcon(
                  FontAwesomeIcons.stop,
                  color: Colors.white,
                  size: 20.r,
                ),
              ),
            ),
          ),
          SizedBox(height: 8.h),

          // ── Stop label ──
          Text(
            l10n.voiceStop,
            style: TextStyleConstants.label2.copyWith(
              color: appColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
