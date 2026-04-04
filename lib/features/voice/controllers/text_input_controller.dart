import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/features/category/controllers/category_controller.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/voice/controllers/voice_input_controller.dart';
import 'package:app_saku_rapi/features/voice/models/voice_parse_result_model.dart';
import 'package:app_saku_rapi/features/voice/repositories/voice_repository.dart';
import 'package:flutter_riverpod/legacy.dart';

// ═══════════════ Providers ═══════════════

/// Controller provider, auto-disposed saat sheet ditutup.
final textInputControllerProvider =
    StateNotifierProvider.autoDispose<TextInputController, TextInputState>(
      (ref) => TextInputController(
        repository: ref.watch(voiceRepositoryProvider),
        categories: ref
            .read(categoryControllerProvider)
            .categories
            .where((c) => c.type != CategoryType.system && !c.isHidden)
            .toList(),
      ),
    );

// ═══════════════ State ═══════════════

/// Status flow text input.
enum TextInputStatus {
  /// Idle, menunggu user mengetik.
  idle,

  /// Sedang proses AI parsing.
  processing,

  /// Hasil parsing siap.
  done,

  /// Error saat parsing.
  error,
}

/// Immutable state untuk text input flow.
class TextInputState {
  const TextInputState({
    this.status = TextInputStatus.idle,
    this.inputText = '',
    this.parseResult,
    this.errorMessage,
  });

  final TextInputStatus status;
  final String inputText;
  final VoiceParseResultModel? parseResult;
  final String? errorMessage;

  TextInputState copyWith({
    TextInputStatus? status,
    String? inputText,
    VoiceParseResultModel? parseResult,
    String? errorMessage,
  }) {
    return TextInputState(
      status: status ?? this.status,
      inputText: inputText ?? this.inputText,
      parseResult: parseResult ?? this.parseResult,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ═══════════════ Controller ═══════════════

/// Controller untuk text input → AI parse flow.
///
/// Lebih sederhana dari [VoiceInputController]:
/// - Tidak perlu mic permission / STT
/// - User langsung ketik teks → kirim ke AI parser
class TextInputController extends StateNotifier<TextInputState> {
  TextInputController({
    required VoiceRepository repository,
    List<CategoryModel> categories = const [],
  }) : _repository = repository,
       _categories = categories,
       super(const TextInputState());

  final VoiceRepository _repository;
  final List<CategoryModel> _categories;

  static const _tag = '[TextInput] [TextInputController]';

  /// Proses teks yang diketik user melalui AI parser.
  Future<void> processText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    AppLogger.call('$_tag processText: "$trimmed"');

    state = state.copyWith(
      status: TextInputStatus.processing,
      inputText: trimmed,
    );

    final categoryMaps = _categories
        .map((c) => {'id': c.id, 'name': c.name, 'type': c.type.name})
        .toList();

    final result = await _repository.parseVoiceText(
      trimmed,
      categories: categoryMaps,
    );

    if (!mounted) return;

    if (result.isSuccess()) {
      final parsed = result.dataSuccess()!;

      if (!parsed.isTransaction) {
        state = state.copyWith(
          status: TextInputStatus.error,
          errorMessage: 'not_transaction',
        );
        return;
      }

      state = state.copyWith(status: TextInputStatus.done, parseResult: parsed);
    } else {
      final (msg, _, _, _) = result.dataError()!;
      state = state.copyWith(status: TextInputStatus.error, errorMessage: msg);
    }
  }

  /// Reset state ke idle untuk coba lagi.
  void reset() {
    state = const TextInputState();
  }
}
