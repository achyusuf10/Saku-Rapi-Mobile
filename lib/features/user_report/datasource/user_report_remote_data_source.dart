import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/network/supabase_handler.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/user_report/models/user_report_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source untuk mengirim laporan user ke Supabase.
class UserReportRemoteDataSource {
  UserReportRemoteDataSource({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _table = 'user_reports';
  static const _tag = '[UserReport] [UserReportRemoteDataSource]';

  /// Kirim laporan baru ke Supabase.
  Future<DataState<void>> submitReport(UserReportModel report) {
    return SupabaseHandler.call<void>(
      function: () async {
        AppLogger.call('$_tag submitReport: ${report.category.value}');
        await _client.from(_table).insert(report.toInsertMap());
        AppLogger.call('$_tag submitReport success');
      },
    );
  }
}
