import 'dart:io';

import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

/// Menulis bytes export ke folder unduhan (Android: `Android/media/<package>/files`).
final class ExportFileWriter {
  ExportFileWriter._();

  static const _tag = '[Export] [ExportFileWriter]';

  /// Basis direktori: Android → `…/Android/media/<applicationId>/files`, lainnya → unduhan / dokumen app.
  static Future<Directory> _exportBaseDirectory() async {
    if (Platform.isAndroid) {
      final dir = await _androidMediaFilesDirectory();
      if (dir != null) {
        return dir;
      }
    }
    Directory? base = await getDownloadsDirectory();
    base ??= await getApplicationDocumentsDirectory();
    return base;
  }

  /// `/storage/emulated/0/Android/media/<packageName>/files` (akar dari path storage eksternal).
  static Future<Directory?> _androidMediaFilesDirectory() async {
    try {
      final packageName = (await PackageInfo.fromPlatform()).packageName;
      final ext = await getExternalStorageDirectory();
      if (ext != null) {
        const marker = '/Android/data/';
        final idx = ext.path.indexOf(marker);
        if (idx != -1) {
          final root = ext.path.substring(0, idx);
          final dir = Directory('$root/Android/media/$packageName/files');
          await dir.create(recursive: true);
          AppLogger.call('$_tag Android export dir: ${dir.path}');
          return dir;
        }
      }
      final fallback = Directory('/storage/emulated/0/Android/media/$packageName/files');
      await fallback.create(recursive: true);
      AppLogger.call('$_tag Android export dir (fallback): ${fallback.path}');
      return fallback;
    } catch (e, st) {
      AppLogger.call('$_tag Android media dir failed: $e\n$st');
      return null;
    }
  }

  /// Menyimpan file dan mengembalikan path absolut.
  static Future<String> saveWorkbookBytes(List<int> bytes) async {
    final ts = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final fileName = 'SakuRapi_Laporan_$ts.xlsx';

    final base = await _exportBaseDirectory();
    final file = File('${base.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    AppLogger.call('$_tag saved ${file.path}');
    return file.path;
  }

  /// Menyimpan bytes PDF (`application/pdf`).
  static Future<String> savePdfBytes(List<int> bytes) async {
    final ts = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final fileName = 'SakuRapi_Laporan_$ts.pdf';

    final base = await _exportBaseDirectory();
    final file = File('${base.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    AppLogger.call('$_tag saved ${file.path}');
    return file.path;
  }
}
