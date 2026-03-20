/// Model request untuk Edge Function `ai-parse`.
///
/// Berisi mode parsing (`voice` / `ocr`) dan teks mentah
/// yang akan dikirim ke AI provider.
class AiParseRequestModel {
  const AiParseRequestModel({required this.mode, required this.text});

  /// Mode parsing: `'voice'` atau `'ocr'`.
  final String mode;

  /// Teks mentah dari voice input atau OCR scan.
  final String text;

  factory AiParseRequestModel.fromMap(Map<String, dynamic> map) {
    return AiParseRequestModel(
      mode: map['mode'] as String,
      text: map['text'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {'mode': mode, 'text': text};
  }

  AiParseRequestModel copyWith({String? mode, String? text}) {
    return AiParseRequestModel(
      mode: mode ?? this.mode,
      text: text ?? this.text,
    );
  }
}
