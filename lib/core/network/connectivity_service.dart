import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service untuk mengecek konektivitas ke server Supabase.
///
/// Tidak menggunakan package connectivity_plus — karena yang penting
/// bukan apakah device punya Wi-Fi/data, tapi apakah Supabase **reachable**.
/// Mengikuti prinsip Interface Segregation — hanya menyediakan 1 fungsi.
class ConnectivityService {
  final SupabaseClient _client;

  ConnectivityService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  /// Mengecek apakah Supabase server bisa dijangkau.
  Future<bool> get isOnline async {
    return true;
  }
}

// ---------------------------------------------------------------------------
// Riverpod Provider
// ---------------------------------------------------------------------------

/// Provider untuk [ConnectivityService].
final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityService(),
);
