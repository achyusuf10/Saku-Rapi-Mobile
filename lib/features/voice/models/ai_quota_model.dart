/// Model untuk quota AI usage per mode.
class AiQuotaModel {
  const AiQuotaModel({
    required this.used,
    required this.limit,
    required this.remaining,
  });

  final int used;
  final int limit;
  final int remaining;

  bool get isExhausted => remaining <= 0;

  factory AiQuotaModel.fromMap(Map<String, dynamic> map) {
    return AiQuotaModel(
      used: (map['used'] as num?)?.toInt() ?? 0,
      limit: (map['limit'] as num?)?.toInt() ?? 0,
      remaining: (map['remaining'] as num?)?.toInt() ?? 0,
    );
  }

  AiQuotaModel copyWith({int? used, int? limit, int? remaining}) {
    return AiQuotaModel(
      used: used ?? this.used,
      limit: limit ?? this.limit,
      remaining: remaining ?? this.remaining,
    );
  }

  Map<String, dynamic> toMap() {
    return {'used': used, 'limit': limit, 'remaining': remaining};
  }
}

/// Model gabungan semua kuota AI user.
class AllAiQuotasModel {
  const AllAiQuotasModel({
    required this.text,
    required this.voice,
    required this.ocr,
    required this.tier,
  });

  final AiQuotaModel text;
  final AiQuotaModel voice;
  final AiQuotaModel ocr;
  final String tier;

  factory AllAiQuotasModel.fromRpcResponse(Map<String, dynamic> map) {
    return AllAiQuotasModel(
      text: AiQuotaModel.fromMap(
        (map['text'] as Map<String, dynamic>?) ?? {'used': 0, 'limit': 0, 'remaining': 0},
      ),
      voice: AiQuotaModel.fromMap(
        (map['voice'] as Map<String, dynamic>?) ?? {'used': 0, 'limit': 0, 'remaining': 0},
      ),
      ocr: AiQuotaModel.fromMap(
        (map['ocr'] as Map<String, dynamic>?) ?? {'used': 0, 'limit': 0, 'remaining': 0},
      ),
      tier: map['tier'] as String? ?? 'free',
    );
  }

  /// Get quota for a specific mode.
  AiQuotaModel quotaForMode(String mode) {
    switch (mode) {
      case 'text':
        return text;
      case 'voice':
        return voice;
      case 'ocr':
        return ocr;
      default:
        return const AiQuotaModel(used: 0, limit: 0, remaining: 0);
    }
  }

  AllAiQuotasModel copyWith({
    AiQuotaModel? text,
    AiQuotaModel? voice,
    AiQuotaModel? ocr,
    String? tier,
  }) {
    return AllAiQuotasModel(
      text: text ?? this.text,
      voice: voice ?? this.voice,
      ocr: ocr ?? this.ocr,
      tier: tier ?? this.tier,
    );
  }
}
