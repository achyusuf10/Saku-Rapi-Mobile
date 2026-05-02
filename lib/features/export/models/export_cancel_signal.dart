/// Sinyal pembatalan dan "hentikan chunk" yang dibagikan repository ↔ UI.
///
/// [cancel] menghentikan seluruh operasi export. [requestPartialStop] hanya
/// menghentikan pengambilan chunk periode berikutnya; data yang sudah ada
/// tetap dipakai untuk workbook.
class ExportCancelSignal {
  bool _cancelled = false;
  bool _partialStop = false;

  /// True jika user membatalkan sepenuhnya.
  bool get isCancelled => _cancelled;

  /// True jika chunk harus dihentikan (batal penuh atau partial).
  bool get stopChunks => _cancelled || _partialStop;

  /// Partial: hentikan fetch chunk baru, lanjut bangun file.
  bool get isPartialStop => _partialStop;

  void cancel() {
    _cancelled = true;
  }

  void requestPartialStop() {
    _partialStop = true;
  }

  void reset() {
    _cancelled = false;
    _partialStop = false;
  }
}
