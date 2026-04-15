import 'dart:io';

import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/user_report/datasource/user_report_remote_data_source.dart';
import 'package:app_saku_rapi/features/user_report/models/user_report_model.dart';
import 'package:app_saku_rapi/global/services/image_upload_service.dart';
import 'package:app_saku_rapi/utils/function/compress_image_func.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository untuk mengirim laporan user.
///
/// Mengorkestrasi flow: compress → upload foto (jika ada) → insert laporan.
class UserReportRepository {
  UserReportRepository({
    UserReportRemoteDataSource? remoteDataSource,
    ImageUploadService? imageUploadService,
    SupabaseClient? client,
  }) : _remoteDataSource = remoteDataSource ?? UserReportRemoteDataSource(),
       _imageUploadService = imageUploadService ?? ImageUploadService(),
       _client = client ?? Supabase.instance.client;

  final UserReportRemoteDataSource _remoteDataSource;
  final ImageUploadService _imageUploadService;
  final SupabaseClient _client;

  static const _tag = '[UserReport] [UserReportRepository]';

  String get _userId => _client.auth.currentUser!.id;

  /// Kirim laporan ke Supabase.
  ///
  /// Jika [photoFile] diberikan, foto akan di-compress dan diupload ke Storage
  /// sebelum laporan diinsert.
  Future<void> submitReport({
    required UserReportCategory category,
    required String title,
    required String description,
    File? photoFile,
  }) async {
    AppLogger.call('$_tag submitReport start: ${category.value}');

    String? attachmentUrl;

    if (photoFile != null) {
      attachmentUrl = await _uploadPhoto(photoFile);
    }

    final model = UserReportModel(
      id: '',
      userId: _userId,
      category: category,
      title: title.trim(),
      description: description.trim(),
      attachmentUrl: attachmentUrl,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    final response = await _remoteDataSource.submitReport(model);

    response.map(
      success: (_) {
        AppLogger.call('$_tag submitReport done');
      },
      error: (err) {
        AppLogger.logError('$_tag submitReport failed: ${err.message}');
        throw Exception(err.message);
      },
    );
  }

  /// Compress dan upload foto ke Supabase Storage.
  ///
  /// Return public signed URL atau null jika gagal.
  Future<String?> _uploadPhoto(File photoFile) async {
    AppLogger.call('$_tag _uploadPhoto: ${photoFile.path}');

    final compressed = await CompressImageFunc.call(filePath: photoFile.path);

    if (compressed == null) {
      AppLogger.logError('$_tag compress photo failed');
      return null;
    }

    final result = await _imageUploadService.uploadImage(
      imageBytes: compressed,
      fileName: 'report_attachment.jpg',
    );

    if (result.isSuccess()) {
      final url = result.dataSuccess()!;
      AppLogger.call('$_tag photo uploaded: $url');
      return url;
    }

    AppLogger.logError('$_tag upload photo failed');
    return null;
  }
}
