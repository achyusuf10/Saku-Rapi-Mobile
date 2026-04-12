import 'package:app_saku_rapi/core/utils/saku_date_utils.dart';

/// Kategori laporan yang bisa dikirim user.
enum UserReportCategory {
  bugReport,
  featureRequest,
  accountIssue,
  paymentIssue,
  other;

  /// Nilai string yang disimpan di database (snake_case).
  String get value => switch (this) {
    bugReport => 'bug_report',
    featureRequest => 'feature_request',
    accountIssue => 'account_issue',
    paymentIssue => 'payment_issue',
    other => 'other',
  };

  /// Parse dari string DB ke enum.
  static UserReportCategory fromValue(String value) => switch (value) {
    'bug_report' => bugReport,
    'feature_request' => featureRequest,
    'account_issue' => accountIssue,
    'payment_issue' => paymentIssue,
    _ => other,
  };
}

/// Model laporan yang dikirim user ke tim SakuRapi.
class UserReportModel {
  const UserReportModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.title,
    required this.description,
    this.attachmentUrl,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final UserReportCategory category;
  final String title;
  final String description;
  final String? attachmentUrl;
  final String status;
  final DateTime createdAt;

  factory UserReportModel.fromMap(Map<String, dynamic> map) {
    return UserReportModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      category: UserReportCategory.fromValue(map['category'] as String),
      title: map['title'] as String,
      description: map['description'] as String,
      attachmentUrl: map['attachment_url'] as String?,
      status: map['status'] as String,
      createdAt: SakuDateUtils.parseRequiredTimestamp(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'category': category.value,
      'title': title,
      'description': description,
      'attachment_url': attachmentUrl,
      'status': status,
      'created_at': SakuDateUtils.formatTimestamp(createdAt),
    };
  }

  /// Map untuk INSERT ke Supabase (tanpa id dan created_at, dibuat oleh DB).
  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'category': category.value,
      'title': title,
      'description': description,
      if (attachmentUrl != null) 'attachment_url': attachmentUrl,
    };
  }

  UserReportModel copyWith({
    String? id,
    String? userId,
    UserReportCategory? category,
    String? title,
    String? description,
    String? attachmentUrl,
    String? status,
    DateTime? createdAt,
  }) {
    return UserReportModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
