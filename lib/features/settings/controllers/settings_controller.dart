import 'package:app_saku_rapi/utils/services/hive_services.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Key Hive untuk menyimpan entry point preferensi.
const _kEntryPointKey = 'transaction_entry_point';

/// Entry point pilihan user saat membuat transaksi baru.
enum TransactionEntryPoint {
  manual,
  voice,
  scan;

  String get dbValue => name;

  static TransactionEntryPoint fromString(String? value) {
    return switch (value) {
      'voice' => TransactionEntryPoint.voice,
      'scan' => TransactionEntryPoint.scan,
      _ => TransactionEntryPoint.manual,
    };
  }
}

/// Provider untuk entry point preference transaksi.
final entryPointProvider =
    StateNotifierProvider<EntryPointController, TransactionEntryPoint>((ref) {
      return EntryPointController();
    });

/// Controller untuk menyimpan dan membaca entry point dari Hive.
class EntryPointController extends StateNotifier<TransactionEntryPoint> {
  EntryPointController() : super(_readFromHive());

  static TransactionEntryPoint _readFromHive() {
    final stored = HiveService.get<String>(key: _kEntryPointKey);
    return TransactionEntryPoint.fromString(stored);
  }

  void setEntryPoint(TransactionEntryPoint point) {
    state = point;
    HiveService.set<String>(key: _kEntryPointKey, data: point.dbValue);
  }
}
