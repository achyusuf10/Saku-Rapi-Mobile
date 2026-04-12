import 'package:app_saku_rapi/core/utils/saku_date_utils.dart';

/// Model data untuk jenis emas custom.
///
/// Merepresentasikan satu record dari tabel `public.custom_gold_types`.
/// Maksimal 2 per user (enforced by DB trigger).
class CustomGoldTypeModel {
  const CustomGoldTypeModel({
    required this.id,
    required this.userId,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CustomGoldTypeModel.fromMap(Map<String, dynamic> map) {
    return CustomGoldTypeModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      createdAt: map['created_at'] != null
          ? SakuDateUtils.parseRequiredTimestamp(
              map['created_at'],
              fieldName: 'created_at',
            )
          : null,
      updatedAt: map['updated_at'] != null
          ? SakuDateUtils.parseRequiredTimestamp(
              map['updated_at'],
              fieldName: 'updated_at',
            )
          : null,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {'user_id': userId, 'name': name};
  }

  Map<String, dynamic> toUpdateMap() {
    return {'name': name};
  }

  Map<String, dynamic> toFullMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'created_at': SakuDateUtils.formatOptionalTimestamp(createdAt),
      'updated_at': SakuDateUtils.formatOptionalTimestamp(updatedAt),
    };
  }

  CustomGoldTypeModel copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomGoldTypeModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
