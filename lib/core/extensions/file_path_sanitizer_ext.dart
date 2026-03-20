extension FilePathSanitizer on String {
  /// Membersihkan path dari format URI (file://) menjadi path sistem file biasa.
  ///
  /// Contoh:
  /// "file:///var/mobile/Containers/.../My%20Video.mp4"
  /// Menjadi:
  /// "/var/mobile/Containers/.../My Video.mp4"
  ///
  /// Otomatis melakukan decode URL (mengubah %20 menjadi spasi).
  String get extToSanitizedFilePath {
    try {
      // Cek apakah string diawali 'file://'.
      // Jika ya, gunakan Uri parsing bawaan Dart yang sangat robust.
      if (startsWith('file://')) {
        return Uri.parse(this).toFilePath();
      }

      // Jika tidak ada 'file://', kembalikan string aslinya.
      // (Biasanya path Android atau path iOS yang sudah bersih)
      return this;
    } catch (e) {
      // Safety net: Jika format URL hancur/error, kembalikan aslinya
      // agar tidak crash, biarkan error ditangani saat File(path).exists()
      return this;
    }
  }
}
