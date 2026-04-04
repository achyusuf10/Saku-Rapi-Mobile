/// Flavor aplikasi — menentukan environment yang aktif saat runtime.
///
/// Diset sekali saja di `main_dev.dart` atau `main_prod.dart` sebelum
/// `runApp()`. Digunakan untuk:
/// - Menampilkan banner/label debug
/// - Conditional logging
/// - Menentukan konfigurasi per-environment
enum AppFlavor { dev, prod }

/// Konfigurasi global flavor yang aktif saat runtime.
///
/// Harus dipanggil `AppFlavorConfig.init()` di entrypoint sebelum `runApp()`.
class AppFlavorConfig {
  AppFlavorConfig._();

  static AppFlavor _flavor = AppFlavor.prod;

  /// Flavor yang sedang aktif.
  static AppFlavor get flavor => _flavor;

  /// Apakah sedang di mode development.
  static bool get isDev => _flavor == AppFlavor.dev;

  /// Apakah sedang di mode production.
  static bool get isProd => _flavor == AppFlavor.prod;

  /// Nama tampilan flavor (untuk logging/debug).
  static String get name => _flavor.name.toUpperCase();

  /// Inisialisasi flavor. Panggil sekali di entrypoint.
  static void init(AppFlavor flavor) {
    _flavor = flavor;
  }
}
