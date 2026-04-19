import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:app_saku_rapi/features/home_widget/home_widget_constants.dart';
import 'package:app_saku_rapi/features/ocr/controllers/pending_ocr_prefill_provider.dart';
import 'package:app_saku_rapi/features/ocr/view/ui/ocr_result_sheet.dart';
import 'package:app_saku_rapi/features/voice/controllers/pending_voice_prefill_provider.dart';
import 'package:app_saku_rapi/features/voice/view/ui/text_input_sheet.dart';
import 'package:app_saku_rapi/features/voice/view/ui/voice_input_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

/// Pending action dari home widget.
///
/// Diisi saat URI diterima dari widget click (cold start atau warm start).
/// Dikonsumsi oleh Dashboard listener untuk melakukan navigasi.
final pendingWidgetActionProvider = StateProvider<Uri?>((ref) => null);

/// Pending walletId dari home widget deep link.
///
/// Diisi bersamaan dengan [pendingWidgetActionProvider].
/// Dikonsumsi oleh TransactionFormPage untuk pre-select wallet.
final pendingWidgetWalletIdProvider = StateProvider<String?>((ref) => null);

/// Handler untuk deep link yang datang dari Android Home Widget.
///
/// Menggunakan state-based routing (bukan `Future.delayed`) agar aman
/// dari race conditions pada cold start maupun warm start.
class HomeWidgetDeepLinkHandler {
  HomeWidgetDeepLinkHandler._();

  /// Terima URI dari widget dan simpan ke provider.
  ///
  /// TIDAK langsung navigate — navigasi dilakukan oleh Dashboard listener.
  static void receiveUri(WidgetRef ref, Uri? uri) {
    if (uri == null) return;
    if (uri.scheme != HomeWidgetConstants.uriScheme) return;

    AppLogger.call('[Online] [HomeWidget] Received deep link: $uri');

    ref.read(pendingWidgetActionProvider.notifier).state = uri;
  }

  /// Consume pending action dan lakukan navigasi.
  ///
  /// Dipanggil dari Dashboard listener setelah dashboard fully mounted.
  /// Aman dipanggil meskipun tidak ada pending action (null-safe).
  static Future<void> consumeAction(WidgetRef ref, BuildContext context) async {
    final uri = ref.read(pendingWidgetActionProvider);
    if (uri == null) return;

    // Consume — set null agar tidak re-trigger
    ref.read(pendingWidgetActionProvider.notifier).state = null;

    final type = uri.queryParameters[HomeWidgetConstants.paramType];
    final walletId = uri.queryParameters[HomeWidgetConstants.paramWalletId];

    AppLogger.call(
      '[Online] [HomeWidget] Consuming action: type=$type, walletId=$walletId',
    );

    // Simpan walletId agar TransactionFormPage bisa pre-select wallet
    if (walletId != null &&
        walletId.isNotEmpty &&
        type == HomeWidgetConstants.actionManual) {
      ref.read(pendingWidgetWalletIdProvider.notifier).state = walletId;
    }

    AppLogger.call('[Online] [HomeWidget] Navigating to action: $type');
    context.go(AppRouter.dashboard);
    switch (type) {
      case HomeWidgetConstants.actionManual:
        context.push(AppRouter.transactionForm);
      case HomeWidgetConstants.actionSpeech:
        _handleVoiceInput(context, ref);
      case HomeWidgetConstants.actionOcr:
        _handleOcrInput(context, ref);
      case HomeWidgetConstants.actionText:
        _handleTextInput(context, ref);
      default:
        AppLogger.logError(
          'Unknown widget action type: $type',
          runtimeType: HomeWidgetDeepLinkHandler,
        );
    }
  }

  static Future<void> _handleVoiceInput(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final result = await VoiceInputSheet.show(context: context);
    if (result != null && context.mounted) {
      ref.read(pendingVoicePrefillProvider.notifier).state = result;
      context.push(AppRouter.transactionForm);
    }
  }

  static Future<void> _handleOcrInput(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final result = await OcrResultSheet.show(context: context);
    if (result != null && context.mounted) {
      ref.read(pendingOcrPrefillProvider.notifier).state = result;
      context.push(AppRouter.transactionForm);
    }
  }

  static Future<void> _handleTextInput(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final result = await TextInputSheet.show(context: context);
    if (result != null && context.mounted) {
      ref.read(pendingVoicePrefillProvider.notifier).state = result;
      context.push(AppRouter.transactionForm);
    }
  }
}
