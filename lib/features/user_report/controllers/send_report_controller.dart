import 'dart:io';

import 'package:app_saku_rapi/features/user_report/models/user_report_model.dart';
import 'package:app_saku_rapi/features/user_report/repositories/user_report_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// ───────────────── Providers ─────────────────

/// Provider singleton untuk [UserReportRepository].
final userReportRepositoryProvider = Provider<UserReportRepository>((ref) {
  return UserReportRepository();
});

/// Provider controller untuk form kirim laporan.
///
/// Pakai `.autoDispose` agar state dibersihkan saat halaman ditutup.
final sendReportControllerProvider = StateNotifierProvider.autoDispose<
    SendReportController, SendReportState>((ref) {
  final repository = ref.watch(userReportRepositoryProvider);
  return SendReportController(repository);
});

// ───────────────── State ─────────────────

/// State form kirim laporan.
class SendReportState {
  const SendReportState({
    this.category,
    this.croppedFile,
    this.isSubmitting = false,
  });

  final UserReportCategory? category;

  /// File foto setelah di-crop, disimpan di local state hingga submit.
  final File? croppedFile;

  final bool isSubmitting;

  SendReportState copyWith({
    UserReportCategory? category,
    File? croppedFile,
    bool clearPhoto = false,
    bool? isSubmitting,
  }) {
    return SendReportState(
      category: category ?? this.category,
      croppedFile: clearPhoto ? null : croppedFile ?? this.croppedFile,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

// ───────────────── Controller ─────────────────

/// Controller untuk form kirim laporan.
class SendReportController extends StateNotifier<SendReportState> {
  SendReportController(this._repository) : super(const SendReportState());

  final UserReportRepository _repository;

  /// Set kategori laporan.
  void setCategory(UserReportCategory category) {
    state = state.copyWith(category: category);
  }

  /// Simpan foto yang sudah di-crop ke local state.
  void setPhoto(File croppedFile) {
    state = state.copyWith(croppedFile: croppedFile);
  }

  /// Hapus foto dari local state.
  void removePhoto() {
    state = state.copyWith(clearPhoto: true);
  }

  /// Kirim laporan ke Supabase.
  ///
  /// Melempar [Exception] jika gagal — tangkap di UI.
  Future<void> submit({
    required String title,
    required String description,
  }) async {
    final category = state.category;
    if (category == null) throw Exception('Pilih kategori laporan');

    state = state.copyWith(isSubmitting: true);

    try {
      await _repository.submitReport(
        category: category,
        title: title,
        description: description,
        photoFile: state.croppedFile,
      );
    } finally {
      if (mounted) {
        state = state.copyWith(isSubmitting: false);
      }
    }
  }
}
