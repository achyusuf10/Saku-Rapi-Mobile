import 'package:app_saku_rapi/features/history/models/history_models.dart';

/// Argument untuk navigasi ke [ReportPage] dengan nilai awal.
///
/// Digunakan ketika pengguna menekan tombol "Lihat Laporan" dari halaman
/// riwayat, sehingga report page dibuka dengan period, sub-period, dan
/// wallet filter yang sama.
class ReportPageArgument {
  const ReportPageArgument({
    required this.period,
    this.subPeriodIndex,
    this.walletId,
  });

  /// Period awal yang akan diterapkan di report page.
  final AppPeriod period;

  /// Index sub-period tab yang akan diaktifkan. Jika null, gunakan tab terakhir.
  final int? subPeriodIndex;

  /// ID dompet yang akan dijadikan filter awal. Jika null, tampilkan semua.
  final String? walletId;
}
