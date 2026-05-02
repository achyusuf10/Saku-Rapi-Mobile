// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get today => 'Hari Ini';

  @override
  String get yesterday => 'Kemarin';

  @override
  String get thisWeek => 'Minggu Ini';

  @override
  String get last7Days => '7 Hari Terakhir';

  @override
  String get thisMonth => 'Bulan Ini';

  @override
  String get lastMonth => 'Bulan Lalu';

  @override
  String get thisYear => 'Tahun Ini';

  @override
  String get lastYear => 'Tahun Lalu';

  @override
  String get custom => 'Kustom';

  @override
  String get yearSuffix => 'tahun';

  @override
  String get monthSuffix => 'bulan';

  @override
  String get weekSuffix => 'minggu';

  @override
  String get daySuffix => 'hari';

  @override
  String get hourSuffix => 'jam';

  @override
  String get minuteSuffix => 'menit';

  @override
  String get agoSuffix => 'lalu';

  @override
  String get justNow => 'baru saja';

  @override
  String get fabVoiceInput => 'Input Suara';

  @override
  String get fabScanReceipt => 'Scan Struk';

  @override
  String get fabManualInput => 'Input Manual';

  @override
  String get appName => 'SakuRapi';

  @override
  String get loginSubtitle => 'Catat keuangan tanpa capek ngetik.';

  @override
  String get loginWithGoogle => 'Masuk dengan Google';

  @override
  String get loginErrorGeneric => 'Gagal masuk. Silakan coba lagi.';

  @override
  String get loginTitle => 'Selamat Datang di SakuRapi';

  @override
  String get loginSecurityNote => 'Data kamu aman & terenkripsi';

  @override
  String get logoutConfirm => 'Yakin ingin keluar?';

  @override
  String get logoutButton => 'Keluar';

  @override
  String get walletTitle => 'Dompet Saya';

  @override
  String get walletAdd => 'Tambah Dompet';

  @override
  String get walletEdit => 'Edit Dompet';

  @override
  String get walletDelete => 'Hapus';

  @override
  String walletDeleteConfirm(String name) {
    return 'Yakin ingin menghapus \"$name\"? Semua transaksi di dompet ini juga akan terhapus.';
  }

  @override
  String get walletName => 'Nama Dompet';

  @override
  String get walletNameHint => 'Contoh: Cash, BCA, Jago';

  @override
  String get walletNameRequired => 'Nama dompet tidak boleh kosong';

  @override
  String get walletInitialBalance => 'Saldo Awal';

  @override
  String get walletBalance => 'Saldo';

  @override
  String get walletBalanceRequired => 'Saldo tidak boleh kosong';

  @override
  String get walletIcon => 'Ikon';

  @override
  String get walletColor => 'Warna';

  @override
  String get walletExcludeFromTotal => 'Kecualikan dari Total';

  @override
  String get walletExcludeHint => 'Saldo dompet ini tidak dihitung ke total';

  @override
  String get walletSave => 'Simpan';

  @override
  String get walletTotalBalance => 'Total Saldo';

  @override
  String get walletIncludedSection => 'Dimasukkan dalam Total';

  @override
  String get walletExcludedSection => 'Dikecualikan dari Total';

  @override
  String get walletEmpty => 'Belum ada dompet';

  @override
  String get walletEmptyHint => 'Tap + untuk menambah dompet baru';

  @override
  String get walletAdjust => 'Sesuaikan Saldo';

  @override
  String get walletAdjustActual => 'Saldo Sebenarnya';

  @override
  String get walletAdjustDiff => 'Selisih';

  @override
  String get walletAdjustHint => 'Masukkan saldo asli dompet ini';

  @override
  String walletSuccessAdd(String name) {
    return '\"$name\" berhasil ditambahkan';
  }

  @override
  String walletSuccessEdit(String name) {
    return '\"$name\" berhasil diperbarui';
  }

  @override
  String walletSuccessDelete(String name) {
    return '\"$name\" berhasil dihapus';
  }

  @override
  String get walletSuccessAdjust => 'Saldo berhasil disesuaikan';

  @override
  String get walletErrorAdd => 'Gagal menambah dompet';

  @override
  String get walletErrorEdit => 'Gagal memperbarui dompet';

  @override
  String get walletErrorDelete => 'Gagal menghapus dompet';

  @override
  String get walletErrorAdjust => 'Gagal menyesuaikan saldo';

  @override
  String get walletOptionEdit => 'Edit';

  @override
  String get walletOptionDelete => 'Hapus';

  @override
  String get walletOptionAdjust => 'Sesuaikan Saldo';

  @override
  String get retryButton => 'Coba Lagi';

  @override
  String get confirmYes => 'Ya';

  @override
  String get confirmCancel => 'Batal';

  @override
  String get transactionExpense => 'Pengeluaran';

  @override
  String get transactionIncome => 'Pemasukan';

  @override
  String get transactionDebt => 'Hutang';

  @override
  String get transactionLoan => 'Piutang';

  @override
  String get transactionTransfer => 'Transfer';

  @override
  String get transactionAdjustment => 'Penyesuaian';

  @override
  String get transactionAmount => 'Nominal';

  @override
  String get transactionCategory => 'Kategori';

  @override
  String get transactionWallet => 'Dompet';

  @override
  String get transactionDate => 'Tanggal';

  @override
  String get transactionNote => 'Catatan';

  @override
  String get transactionAttachment => 'Lampiran';

  @override
  String get transactionWithPerson => 'Nama Kontak';

  @override
  String get transactionWithPersonHint => 'Contoh: Budi, Mama';

  @override
  String get transactionAddItem => '+ Tambah Item';

  @override
  String get transactionGrandTotal => 'Total';

  @override
  String get transactionSave => 'Simpan';

  @override
  String get transactionSaveSuccess => 'Transaksi berhasil disimpan';

  @override
  String transactionSaveSuccessBatch(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transaksi berhasil disimpan',
      one: '1 transaksi berhasil disimpan',
    );
    return '$_temp0';
  }

  @override
  String transactionMultiManualAtLimitBanner(int max) {
    return 'Sudah mencapai batas maksimal $max transaksi per simpanan. Hapus satu untuk menambah lagi.';
  }

  @override
  String transactionMultiManualMaxReached(int max) {
    return 'Maksimal $max transaksi per simpanan. Hapus satu untuk menambah lagi.';
  }

  @override
  String get transactionDeleteConfirm => 'Hapus transaksi ini?';

  @override
  String get transactionPrefilledFromVoice => 'Diisi dari suara';

  @override
  String get transactionPrefilledFromOcr => 'Diisi dari struk';

  @override
  String get transactionDebtStatus => 'Status';

  @override
  String get transactionUnpaid => 'Belum Lunas';

  @override
  String get transactionPaid => 'Sudah Lunas';

  @override
  String get transactionDueDate => 'Jatuh Tempo';

  @override
  String get transactionSourceWallet => 'Dompet Asal';

  @override
  String get transactionDestWallet => 'Dompet Tujuan';

  @override
  String get transactionMerchant => 'Nama Merchant';

  @override
  String get transactionMerchantHint => 'Contoh: Indomaret, Grab';

  @override
  String get transactionWalletRequired => 'Pilih dompet terlebih dahulu';

  @override
  String get transactionAmountRequired => 'Nominal harus diisi';

  @override
  String get transactionWithPersonRequired =>
      'Nama kontak wajib diisi untuk hutang/piutang';

  @override
  String get contactPickerTitle => 'Pilih Kontak';

  @override
  String get contactPickerFromPhonebook => 'Dari Kontak HP';

  @override
  String get contactPickerSaved => 'Kontak Tersimpan';

  @override
  String get contactPickerSearch => 'Cari kontak...';

  @override
  String get contactPickerEmpty => 'Belum ada kontak tersimpan';

  @override
  String get contactPickerPhonePermissionDenied => 'Izin akses kontak ditolak';

  @override
  String get contactPickerNoPhone => 'Tidak ada nomor HP';

  @override
  String get contactPickerSelected => 'Kontak';

  @override
  String get transactionDestWalletRequired => 'Pilih dompet tujuan';

  @override
  String get transactionSameWalletError =>
      'Dompet asal dan tujuan tidak boleh sama';

  @override
  String get transactionErrorSave => 'Gagal menyimpan transaksi';

  @override
  String get transactionDebtTypeHutang => 'Hutang (saya berhutang)';

  @override
  String get transactionDebtTypePiutang => 'Piutang (saya yang memberi hutang)';

  @override
  String get transactionSelectCategory => 'Pilih Kategori';

  @override
  String get transactionSelectWallet => 'Pilih Dompet';

  @override
  String get transactionMultiItemToggle => 'Beberapa Item';

  @override
  String get transactionMultiManualHint =>
      'Catat beberapa transaksi sekaligus. Masing-masing punya dompet, kategori, detail opsional, dan baris item sendiri. Semua disimpan bersamaan dalam satu langkah.';

  @override
  String get transactionMultiManualSegmentSingle => 'Satu transaksi';

  @override
  String get transactionMultiManualSegmentMulti => 'Multi transaksi';

  @override
  String get transactionMultiManualAddAnother => 'Tambah transaksi lain';

  @override
  String transactionMultiManualCardTitle(int index) {
    return 'Transaksi $index';
  }

  @override
  String get transactionNewTitle => 'Transaksi Baru';

  @override
  String get transactionEditTitle => 'Edit Transaksi';

  @override
  String get transactionSettleDebt => 'Lunasi Hutang';

  @override
  String get transactionSettleLoan => 'Tagih Piutang';

  @override
  String get transactionSettleAmount => 'Jumlah Pelunasan';

  @override
  String get transactionSettleSuccess => 'Pelunasan berhasil disimpan';

  @override
  String get transactionAttachmentAdd => 'Tambah Lampiran';

  @override
  String get transactionAttachmentChange => 'Ganti Lampiran';

  @override
  String get transactionOptionalFields => 'Detail Tambahan';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get dashboardTotalBalance => 'Total Saldo';

  @override
  String get dashboardMyWallets => 'Dompet Saya';

  @override
  String get dashboardSeeAll => 'Lihat Semua';

  @override
  String dashboardSnapshotTitle(String period) {
    return 'Ringkasan $period';
  }

  @override
  String get dashboardTopExpenses => 'Pengeluaran Terbesar';

  @override
  String get dashboardRecentTransactions => 'Transaksi Terkini';

  @override
  String get dashboardIncomeLabel => 'Pemasukan';

  @override
  String get dashboardExpenseLabel => 'Pengeluaran';

  @override
  String get dashboardEmptyTransactions => 'Belum ada transaksi';

  @override
  String get dashboardHideBalance => 'Sembunyikan saldo';

  @override
  String get dashboardShowBalance => 'Tampilkan saldo';

  @override
  String get dashboardExcludedFromTotal => 'Dikecualikan dari total';

  @override
  String dashboardWeekLabel(Object week) {
    return 'Minggu $week';
  }

  @override
  String get dashboardComingSoon => 'Segera Hadir';

  @override
  String dashboardGreeting(String name) {
    return 'Halo, $name 👋';
  }

  @override
  String get dashboardEmptyWallets => 'Belum ada dompet';

  @override
  String get dashboardMonthlyIncome => 'Pemasukan Bulan Ini';

  @override
  String get dashboardMonthlyExpense => 'Pengeluaran Bulan Ini';

  @override
  String get dashboardChartTitle => 'Pemasukan vs Pengeluaran';

  @override
  String get dashboardThisMonth => 'Bulan Ini';

  @override
  String get dashboardLastMonth => 'Bulan Lalu';

  @override
  String get dashboardThisWeek => 'Minggu Ini';

  @override
  String get dashboardLastWeek => 'Minggu Lalu';

  @override
  String get dashboardMonthlyMode => 'Bulanan';

  @override
  String get dashboardWeeklyMode => 'Mingguan';

  @override
  String get dashboardDailyMode => 'Harian';

  @override
  String get dashboardToday => 'Hari Ini';

  @override
  String get dashboardYesterday => 'Kemarin';

  @override
  String get dashboardQuickAdd => 'Tambah Cepat';

  @override
  String get dashboardNetFlow => 'Netto';

  @override
  String get dashboardNoChange => 'Tidak berubah';

  @override
  String dashboardVsPrevious(String period) {
    return 'vs $period';
  }

  @override
  String get historyTitle => 'Riwayat';

  @override
  String get historyTabTransactions => 'Transaksi';

  @override
  String get historyTabReport => 'Laporan';

  @override
  String get historyNoTransactions => 'Belum ada transaksi di periode ini';

  @override
  String get historyTotalIn => 'Pemasukan';

  @override
  String get historyTotalOut => 'Pengeluaran';

  @override
  String get historyFilter => 'Filter';

  @override
  String get historyAllWallets => 'Semua Dompet';

  @override
  String get historySelectWallet => 'Pilih Dompet';

  @override
  String get historyApplyFilter => 'Terapkan Filter';

  @override
  String get historyResetFilter => 'Reset';

  @override
  String get historyDaily => 'Harian';

  @override
  String get historyWeekly => 'Mingguan';

  @override
  String get historyMonthly => 'Bulanan';

  @override
  String get historyQuarterly => '3 Bulanan';

  @override
  String get historyYearly => 'Tahunan';

  @override
  String get historyCustomRange => 'Kustom';

  @override
  String get historyGroupByDate => 'Berdasarkan Tanggal';

  @override
  String get historyGroupByCategory => 'Berdasarkan Kategori';

  @override
  String get historyAllTypes => 'Semua Tipe';

  @override
  String get historySelectType => 'Tipe Transaksi';

  @override
  String get historyPeriod => 'Periode';

  @override
  String get historyLoadMore => 'Muat lebih banyak';

  @override
  String historyTransactionCount(int count) {
    return '$count transaksi';
  }

  @override
  String get historyFilterEmpty => 'Tidak ada transaksi dengan filter ini';

  @override
  String get historySearchHint => 'Cari catatan atau kategori...';

  @override
  String get historyViewReport => 'Lihat Laporan';

  @override
  String get historyDeleteSuccess => 'Transaksi berhasil dihapus';

  @override
  String get historyDeleteConfirm => 'Hapus Transaksi';

  @override
  String get historyDeleteConfirmMessage =>
      'Yakin ingin menghapus transaksi ini? Saldo dompet akan dikembalikan.';

  @override
  String get historySelectDateRange => 'Pilih Rentang Tanggal';

  @override
  String get historyStartDate => 'Tanggal Mulai';

  @override
  String get historyEndDate => 'Tanggal Akhir';

  @override
  String get breakdownTitle => 'Rincian Biaya';

  @override
  String get breakdownVsLastMonth => 'vs Bulan Lalu';

  @override
  String get breakdownDailyAverage => 'Rata-rata Harian';

  @override
  String get breakdownSubcategories => 'Sub-kategori';

  @override
  String get breakdownTransactions => 'Transaksi';

  @override
  String get breakdownNoData => 'Belum ada data';

  @override
  String get categoryTitle => 'Kategori';

  @override
  String get categoryExpense => 'Pengeluaran';

  @override
  String get categoryIncome => 'Pemasukan';

  @override
  String get categoryAdd => 'Tambah Kategori';

  @override
  String get categoryEdit => 'Edit Kategori';

  @override
  String get categoryDelete => 'Hapus Kategori';

  @override
  String categoryDeleteConfirm(String name) {
    return 'Yakin ingin menghapus \"$name\"? Transaksi yang menggunakan kategori ini tidak akan terpengaruh.';
  }

  @override
  String get categoryDeleteDefault => 'Kategori bawaan tidak bisa dihapus';

  @override
  String get categoryHide => 'Sembunyikan';

  @override
  String get categoryShow => 'Tampilkan';

  @override
  String get categoryHidden => 'Tersembunyi';

  @override
  String get categoryIconPicker => 'Pilih Icon';

  @override
  String get categoryColorPicker => 'Pilih Warna';

  @override
  String get colorPickerPresetTab => 'Preset';

  @override
  String get colorPickerWheelTab => 'Kustom';

  @override
  String get colorPickerSelectButton => 'Pilih Warna Ini';

  @override
  String get categoryName => 'Nama Kategori';

  @override
  String get categoryNameRequired => 'Nama kategori tidak boleh kosong';

  @override
  String get categoryParent => 'Kategori Induk';

  @override
  String get categoryNoParent => 'Tanpa Induk (Parent)';

  @override
  String get categorySave => 'Simpan';

  @override
  String categorySuccessAdd(String name) {
    return '\"$name\" berhasil ditambahkan';
  }

  @override
  String categorySuccessEdit(String name) {
    return '\"$name\" berhasil diperbarui';
  }

  @override
  String get categorySuccessDelete => 'Kategori berhasil dihapus';

  @override
  String get categorySuccessHide => 'Kategori disembunyikan';

  @override
  String get categorySuccessShow => 'Kategori ditampilkan';

  @override
  String get categoryErrorSave => 'Gagal menyimpan kategori';

  @override
  String get categoryErrorDelete => 'Gagal menghapus kategori';

  @override
  String get categoryEmpty => 'Belum ada kategori';

  @override
  String get categorySearchIcon => 'Cari icon...';

  @override
  String get categorySortNone => 'Tidak Ada';

  @override
  String get categorySortNameAZ => 'Nama: A→Z';

  @override
  String get categorySortNameZA => 'Nama: Z→A';

  @override
  String get categorySortNewest => 'Terbaru';

  @override
  String get categorySortOldest => 'Terlama';

  @override
  String get categoryFilterAll => 'Semua';

  @override
  String get categoryFilterUserCreated => 'Buatan Saya';

  @override
  String get categoryFilterSystem => 'Dari Sistem';

  @override
  String get categoryFilterReset => 'Reset';

  @override
  String get categoryFilterNoResults =>
      'Tidak ada kategori yang cocok dengan filter';

  @override
  String categoryChildCount(int count) {
    return '$count sub-kategori';
  }

  @override
  String get voiceListening => 'Sedang mendengarkan...';

  @override
  String get voiceStop => 'Stop';

  @override
  String get voiceProcessing => 'Memproses suara...';

  @override
  String get voiceError => 'Gagal mengenali suara, coba lagi';

  @override
  String get voicePermissionDenied => 'Izin mikrofon diperlukan';

  @override
  String voiceCountdown(int seconds) {
    return 'Berhenti dalam $seconds detik';
  }

  @override
  String get voicePrefilledBadge => 'Diisi dari suara';

  @override
  String get ocrTitle => 'Scan Struk';

  @override
  String get ocrCamera => 'Kamera';

  @override
  String get ocrGallery => 'Galeri';

  @override
  String get ocrCropInstruction => 'Crop area struk';

  @override
  String get ocrScanning => 'Membaca struk...';

  @override
  String get ocrResultTitle => 'Hasil Scan';

  @override
  String get ocrMerchant => 'Merchant';

  @override
  String get ocrGrandTotal => 'Total';

  @override
  String ocrItemCount(int count) {
    return '$count item terdeteksi';
  }

  @override
  String get ocrContinue => 'Lanjutkan';

  @override
  String get ocrRescan => 'Scan Ulang';

  @override
  String get ocrAutoBalance => 'Selisih ditambahkan otomatis';

  @override
  String get ocrNoText => 'Tidak ada teks terdeteksi';

  @override
  String get ocrPrefilledBadge => 'Diisi dari scan struk';

  @override
  String get budgetTitle => 'Anggaran Berjalan';

  @override
  String get budgetAdd => 'Membuat Anggaran';

  @override
  String get budgetEmpty => 'Belum ada anggaran';

  @override
  String get budgetEmptyHint =>
      'Mulai pantau pengeluaran dengan membuat anggaran pertama';

  @override
  String get budgetActiveBudgets => 'Anggaran Aktif';

  @override
  String get budgetSpendableLabel => 'Jumlah yang dapat Anda belanjakan';

  @override
  String get budgetTotalBudgetLabel => 'Total Anggaran';

  @override
  String get budgetUsed => 'Terpakai';

  @override
  String get budgetEndOfMonthLabel => 'Akhir Bulan';

  @override
  String get budgetEndOfPeriodLabel => 'Akhir Periode';

  @override
  String budgetDaysRemaining(int days) {
    return '$days hari';
  }

  @override
  String budgetRemaining(String amount) {
    return 'Sisa $amount';
  }

  @override
  String budgetOver(String amount) {
    return 'Lebih $amount';
  }

  @override
  String get budgetToday => 'Hari ini';

  @override
  String get budgetPeriodTitle => 'Pilih Periode';

  @override
  String get budgetPeriodThisWeek => 'Minggu ini';

  @override
  String get budgetPeriodThisMonth => 'Bulan ini';

  @override
  String get budgetPeriodThisQuarter => 'Kuartal ini';

  @override
  String get budgetPeriodThisYear => 'Tahun ini';

  @override
  String get budgetPeriodCustom => 'Kustom';

  @override
  String get budgetAllWallets => 'Semua Dompet';

  @override
  String get budgetSpecificWallet => 'Dompet Tertentu';

  @override
  String get budgetFormTitleAdd => 'Tambah Anggaran';

  @override
  String get budgetFormTitleEdit => 'Edit Anggaran';

  @override
  String get budgetFormCategory => 'Kategori';

  @override
  String get budgetFormCategorySelect => 'Pilih kategori...';

  @override
  String get budgetFormCategoryError => 'Gagal memuat kategori';

  @override
  String get budgetFormCategoryRequired => 'Pilih kategori terlebih dahulu';

  @override
  String get budgetFormAmount => 'Nominal Anggaran';

  @override
  String get budgetFormAmountRequired => 'Masukkan nominal anggaran';

  @override
  String get budgetFormAmountInvalid => 'Nominal harus lebih dari 0';

  @override
  String get budgetFormPeriod => 'Periode';

  @override
  String get budgetFormPeriodSelect => 'Pilih periode...';

  @override
  String get budgetFormPeriodRequired => 'Pilih periode terlebih dahulu';

  @override
  String get budgetFormWalletScope => 'Berlaku untuk';

  @override
  String get budgetFormRecurringTitle => 'Ulangi anggaran ini';

  @override
  String get budgetFormRecurringSubtitle =>
      'Anggaran otomatis diperpanjang setiap periode berikutnya';

  @override
  String get budgetSave => 'Simpan';

  @override
  String get budgetCancel => 'Batal';

  @override
  String get budgetSuccessAdd => 'Anggaran berhasil dibuat';

  @override
  String get budgetSuccessEdit => 'Anggaran berhasil diperbarui';

  @override
  String get budgetSuccessDelete => 'Anggaran berhasil dihapus';

  @override
  String get budgetErrorAdd => 'Gagal membuat anggaran';

  @override
  String get budgetErrorEdit => 'Gagal memperbarui anggaran';

  @override
  String get budgetErrorDelete => 'Gagal menghapus anggaran';

  @override
  String get budgetDeleteConfirmTitle => 'Hapus Anggaran?';

  @override
  String budgetDeleteConfirmMessage(String name) {
    return 'Anggaran untuk \"$name\" akan dihapus permanen.';
  }

  @override
  String get budgetFilterAll => 'Semua Dompet';

  @override
  String get budgetCompletedTitle => 'Anggaran Selesai';

  @override
  String get budgetCompletedEmpty => 'Belum ada anggaran yang selesai';

  @override
  String get budgetCompleted => 'Selesai';

  @override
  String get budgetDuplicateTitle => 'Anggaran Sudah Ada';

  @override
  String budgetDuplicateMessage(String category, String wallet) {
    return 'Sudah ada anggaran aktif untuk kategori \"$category\" di $wallet. Ganti dengan yang baru?';
  }

  @override
  String get budgetDuplicateReplace => 'Ganti';

  @override
  String get budgetDuplicateKeep => 'Batal';

  @override
  String get budgetTabWeekly => 'Mingguan';

  @override
  String get budgetTabMonthly => 'Bulanan';

  @override
  String get budgetTabQuarterly => 'Kuartalan';

  @override
  String get budgetTabYearly => 'Tahunan';

  @override
  String get budgetTabCustom => 'Kustom';

  @override
  String get budgetDetailTitle => 'Detail Anggaran';

  @override
  String get budgetDetailSpent => 'Terpakai';

  @override
  String get budgetDetailRemaining => 'Sisa';

  @override
  String get budgetDetailPeriod => 'Periode';

  @override
  String get budgetDetailDaysLeft => 'Sisa Hari';

  @override
  String get budgetDetailWallet => 'Dompet';

  @override
  String get budgetDetailDailyRecommended => 'Rekomendasi Harian';

  @override
  String get budgetDetailProjectedSpend => 'Proyeksi Pengeluaran';

  @override
  String get budgetDetailActualDaily => 'Rata-rata Harian';

  @override
  String get budgetDetailTransactions => 'Transaksi';

  @override
  String get budgetDetailTransactionsEmpty => 'Belum ada transaksi';

  @override
  String get budgetFormCarryForwardTitle => 'Carry Forward';

  @override
  String get budgetFormCarryForwardSubtitle =>
      'Bawa sisa anggaran ke periode berikutnya saat diperpanjang';

  @override
  String get budgetFormDiscardTitle => 'Buang Perubahan?';

  @override
  String get budgetFormDiscardMessage =>
      'Kamu punya perubahan yang belum disimpan. Yakin ingin membuangnya?';

  @override
  String get budgetFormDiscardConfirm => 'Buang';

  @override
  String get budgetUpcomingBudgets => 'Anggaran Mendatang';

  @override
  String get notifTitle => 'Notifikasi';

  @override
  String get notifReminderTitle => 'Pengingat Harian';

  @override
  String get notifReminderSubtitle => 'Ingatkan saya untuk catat transaksi';

  @override
  String get notifReminderTime => 'Jam Pengingat';

  @override
  String get notifBudgetTitle => 'Alert Anggaran';

  @override
  String get notifBudgetSubtitle => 'Notifikasi saat anggaran 80% dan 100%';

  @override
  String get notifDebtTitle => 'Pengingat Piutang';

  @override
  String get notifDebtSubtitle => 'Ingatkan sebelum jatuh tempo';

  @override
  String notifDebtDaysBefore(int days) {
    return 'Ingatkan $days hari sebelumnya';
  }

  @override
  String notifBudgetAlert80(String category) {
    return 'Anggaran $category sudah 80% terpakai!';
  }

  @override
  String notifBudgetAlert100(String category) {
    return 'Anggaran $category sudah habis!';
  }

  @override
  String notifBudgetAlert50(String category) {
    return 'Anggaran $category sudah 50% terpakai';
  }

  @override
  String get notifBudget50Title => 'Alert Anggaran 50%';

  @override
  String get notifBudget50Subtitle => 'Notif saat anggaran mencapai 50%';

  @override
  String notifDebtDue(String person, int days) {
    return 'Piutang ke $person jatuh tempo $days hari lagi';
  }

  @override
  String get notifSave => 'Simpan Pengaturan';

  @override
  String get notifSaveSuccess => 'Pengaturan notifikasi berhasil disimpan';

  @override
  String get notifSaveError => 'Gagal menyimpan pengaturan notifikasi';

  @override
  String get navDashboard => 'Beranda';

  @override
  String get navHistory => 'Riwayat';

  @override
  String get navBudget => 'Anggaran';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileEditName => 'Ubah Nama';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileMemberSince => 'Bergabung sejak';

  @override
  String get profileSettings => 'Pengaturan';

  @override
  String get profileCategories => 'Kategori';

  @override
  String get profileWallets => 'Dompet';

  @override
  String get profileNotifications => 'Notifikasi';

  @override
  String get profileLogout => 'Keluar';

  @override
  String get profileLogoutConfirmTitle => 'Keluar';

  @override
  String get profileLogoutConfirmMessage => 'Apakah Anda yakin ingin keluar?';

  @override
  String get profileDarkMode => 'Mode Gelap';

  @override
  String get profileLanguage => 'Bahasa';

  @override
  String get profileThemeSystem => 'Ikuti Sistem';

  @override
  String get profileThemeLight => 'Terang';

  @override
  String get profileThemeDark => 'Gelap';

  @override
  String get profileThemeTitle => 'Tema Aplikasi';

  @override
  String get profileLanguageIndonesian => 'Indonesia';

  @override
  String get profileLanguageEnglish => 'English';

  @override
  String get profileLanguageTitle => 'Pilih Bahasa';

  @override
  String get profileExportImport => 'Export / Import';

  @override
  String get profileComingSoon => 'Segera Hadir';

  @override
  String get profileAppVersion => 'Versi Aplikasi';

  @override
  String get profileSectionAccount => 'Akun';

  @override
  String get profileSectionPreferences => 'Preferensi';

  @override
  String get profileSectionData => 'Data';

  @override
  String get profileSectionOther => 'Lainnya';

  @override
  String get pickerChooseIcon => 'Pilih Ikon';

  @override
  String get pickerChooseColor => 'Pilih Warna';

  @override
  String get pickerSearchCategory => 'Cari kategori...';

  @override
  String get voiceInitializing => 'Mempersiapkan mikrofon...';

  @override
  String get voiceAnalyzingAi => 'Menganalisis dengan AI...';

  @override
  String get voiceDoneButton => 'Selesai';

  @override
  String get voicePleaseWait => 'Mohon tunggu...';

  @override
  String get voiceNoSpeech => 'Tidak ada suara terdeteksi';

  @override
  String get voiceOpenSettings => 'Buka Pengaturan';

  @override
  String get voicePermissionExplainer =>
      'Izin mikrofon diperlukan untuk fitur input suara. Silakan aktifkan di pengaturan.';

  @override
  String get voiceParseFailed =>
      'Gagal menganalisis, data dari suara diisi manual';

  @override
  String get voiceAiBusy => 'AI sedang sibuk, coba lagi nanti';

  @override
  String get voiceTapToSpeak => 'Tekan & tahan untuk bicara';

  @override
  String get voiceTranscript => 'Teks terdengar';

  @override
  String get voiceNotTransaction =>
      'Input tidak terdeteksi sebagai transaksi. Coba ucapkan ulang dengan menyebutkan nominal atau jenis transaksi.';

  @override
  String get voiceContinueButton => 'Lanjutkan';

  @override
  String get voiceRetryButton => 'Ulangi';

  @override
  String get voicePreviewTitle => 'Preview Transaksi';

  @override
  String get voicePreviewType => 'Tipe';

  @override
  String get voicePreviewDestWallet => 'Wallet Tujuan';

  @override
  String get ocrAnalyzingAi => 'Menganalisis dengan AI...';

  @override
  String get ocrPickerTitle => 'Scan Struk Belanja';

  @override
  String get ocrCropToolbar => 'Pilih Area Struk';

  @override
  String get ocrErrorGeneric => 'Gagal memproses gambar';

  @override
  String get ocrPermissionDenied => 'Izin kamera ditolak';

  @override
  String get ocrPermissionExplainer =>
      'Izin kamera diperlukan untuk scan struk. Silakan aktifkan di pengaturan.';

  @override
  String get ocrAiBusy => 'AI sedang sibuk, coba lagi nanti';

  @override
  String get ocrPartialResult => 'Sebagian data berhasil dibaca';

  @override
  String ocrTotalMismatch(String itemsTotal, String receiptTotal) {
    return 'Total item ($itemsTotal) tidak cocok dengan total struk ($receiptTotal)';
  }

  @override
  String get ocrDate => 'Tanggal';

  @override
  String get ocrItemsSection => 'Daftar Item';

  @override
  String get ocrProcessing => 'Memproses...';

  @override
  String get ocrImageBlurry => 'Gambar tidak terbaca, coba foto ulang';

  @override
  String get ocrNotTransaction =>
      'Gambar ini bukan dokumen transaksi keuangan. Coba foto struk, bukti transfer, atau nota lainnya.';

  @override
  String get ocrTypeExpense => 'Pengeluaran';

  @override
  String get ocrTypeIncome => 'Pemasukan';

  @override
  String get ocrTypeTransfer => 'Transfer';

  @override
  String get ocrTypeDebt => 'Hutang';

  @override
  String get ocrTypeLoan => 'Piutang';

  @override
  String get ocrSourceWallet => 'Dari';

  @override
  String get ocrDestWallet => 'Ke';

  @override
  String get ocrWithPerson => 'Orang';

  @override
  String get ocrPaymentMethod => 'Pembayaran';

  @override
  String get ocrUseResult => 'Gunakan Hasil';

  @override
  String get transactionListTitle => 'Transaksi';

  @override
  String get transactionRangeTitle => 'Pilih Rentang Waktu';

  @override
  String get transactionRangeHari => 'Hari Ini';

  @override
  String get transactionRangeMinggu => 'Minggu Ini';

  @override
  String get transactionRangeBulan => 'Bulan Ini';

  @override
  String get transactionRangeKuartal => 'Kuartal Ini';

  @override
  String get transactionRangeTahun => 'Tahun Ini';

  @override
  String get transactionRangeSemua => 'Semua';

  @override
  String get transactionRangeSesuaikan => 'Sesuaikan';

  @override
  String get transactionViewByCategory => 'Lihat per Kategori';

  @override
  String get transactionViewByTransaction => 'Lihat per Transaksi';

  @override
  String get transactionTransferMoney => 'Transfer Uang';

  @override
  String get transactionDetailTitle => 'Detail Transaksi';

  @override
  String get transactionDuplicate => 'Duplikasi';

  @override
  String get transactionShareDetail => 'Bagikan';

  @override
  String get transactionDeleteSuccess => 'Transaksi berhasil dihapus';

  @override
  String get transactionItemQty => 'Jumlah';

  @override
  String get transactionItemUnitPrice => 'Harga Satuan';

  @override
  String get transactionItemSubtotal => 'Subtotal';

  @override
  String get transactionItemName => 'Nama Item';

  @override
  String get transactionItemNameHint => 'Contoh: Kopi, Nasi Goreng';

  @override
  String get transactionTotalMismatch =>
      'Total item tidak cocok dengan total transaksi';

  @override
  String get transactionReorderHint => 'Geser untuk mengatur urutan';

  @override
  String get transactionRemoveItem => 'Hapus Item';

  @override
  String get transactionItemNote => 'Catatan item';

  @override
  String get dashboardExpenseReport => 'Laporan Pengeluaran';

  @override
  String get dashboardTrendReport => 'Laporan Tren';

  @override
  String get dashboardTotalExpenseLabel => 'Total pengeluaran';

  @override
  String get dashboardTotalIncomeLabel => 'Total pendapatan';

  @override
  String get dashboardThisMonthCumulative => 'Bulan ini';

  @override
  String get dashboardAvg3MonthLabel => 'Rata-rata 3 bulan lalu';

  @override
  String get dashboardPrevMonthLabel => 'Bulan lalu';

  @override
  String get dashboardAvg3WeekLabel => 'Rata-rata 3 minggu lalu';

  @override
  String get dashboardAvg3DayLabel => 'Rata-rata 3 hari lalu';

  @override
  String dashboardInsightExpenseDown(
    String period,
    String percent,
    String prevPeriod,
  ) {
    return 'Pengeluaranmu $period ini $percent% lebih rendah dari $prevPeriod. Bagus, terus pertahankan!';
  }

  @override
  String dashboardInsightExpenseUp(
    String period,
    String percent,
    String prevPeriod,
  ) {
    return 'Pengeluaranmu $period ini $percent% lebih tinggi dari $prevPeriod. Coba kurangi pengeluaran yang tidak perlu.';
  }

  @override
  String dashboardInsightExpenseSame(String prevPeriod) {
    return 'Pengeluaranmu stabil dibandingkan $prevPeriod.';
  }

  @override
  String get dashboardInsightTrendBelowAvg =>
      'Pengeluaranmu di bawah rata-rata 3 bulan. Kamu di jalur yang benar!';

  @override
  String get dashboardInsightTrendAboveAvg =>
      'Pengeluaranmu di atas rata-rata 3 bulan. Perhatikan pengeluaranmu.';

  @override
  String get dashboardInsightNoData =>
      'Mulai catat transaksi untuk melihat insight.';

  @override
  String get dashboardLast7Days => '7 Hari Ini';

  @override
  String get dashboardPrev7Days => '7 Hari Lalu';

  @override
  String get dashboardAvg3x7DaysLabel => 'Rata-rata 3 minggu lalu';

  @override
  String dashboardInsightTrendProjHigh(
    String projected,
    String excess,
    String avg,
    String dailyCap,
  ) {
    return '⚠️ Pengeluaranmu diprediksi mencapai $projected sampai akhir periode — lebih boros $excess dari biasanya ($avg). Coba batasi pengeluaranmu jadi sekitar $dailyCap/hari agar tetap aman.';
  }

  @override
  String dashboardInsightTrendProjMid(String projected, String avg) {
    return 'Pengeluaranmu sedikit lebih tinggi dari biasanya. Diperkirakan $projected, sedangkan biasanya $avg. Tetap pantau agar tidak melonjak!';
  }

  @override
  String dashboardInsightTrendProjLow(
    String projected,
    String saving,
    String avg,
  ) {
    return '🎉 Pengeluaranmu terkendali! Diperkirakan hanya $projected, lebih hemat $saving dari biasanya ($avg). Selisihnya bisa kamu tabung!';
  }

  @override
  String dashboardInsightTrendDailyHigh(
    String burnRate,
    String excess,
    String avg,
  ) {
    return '⚠️ Rata-rata pengeluaranmu $burnRate/hari, lebih tinggi $excess/hari dari kebiasaanmu ($avg/hari). Coba perhatikan pengeluaran yang bisa dikurangi.';
  }

  @override
  String dashboardInsightTrendDailyMid(String burnRate, String avg) {
    return 'Pengeluaran harianmu sedikit lebih tinggi dari kebiasaanmu ($burnRate/hari vs $avg/hari). Tetap pantau ya!';
  }

  @override
  String dashboardInsightTrendDailyLow(String burnRate, String avg) {
    return '🎉 Pengeluaranmu lebih hemat dari kebiasaan! Rata-rata $burnRate/hari, di bawah kebiasaanmu $avg/hari. Terus pertahankan!';
  }

  @override
  String dashboardInsightTrendNoHistory(String total) {
    return 'Pengeluaranmu periode ini: $total. Terus catat transaksi agar kamu bisa melihat tren dan perbandingan pengeluaranmu.';
  }

  @override
  String get reportTitle => 'Laporan';

  @override
  String get reportNet => 'Selisih Bersih';

  @override
  String get reportIncome => 'Pemasukan';

  @override
  String get reportExpense => 'Pengeluaran';

  @override
  String get reportPeriodWeekly => 'Mingguan';

  @override
  String get reportPeriodMonthly => 'Bulanan';

  @override
  String get reportPeriodQuarterly => 'Kuartal';

  @override
  String get reportPeriodYearly => 'Tahunan';

  @override
  String get reportAllWallets => 'Semua Dompet';

  @override
  String get reportCategoryBreakdown => 'Breakdown Kategori';

  @override
  String get reportDailyTrend => 'Tren Harian';

  @override
  String get reportNoCategory => 'Belum ada data kategori.';

  @override
  String get reportNoTrendData => 'Belum ada data tren.';

  @override
  String get reportEmptyTitle => 'Belum Ada Data';

  @override
  String get reportEmptyMessage =>
      'Mulai catat transaksi untuk melihat laporan lengkap.';

  @override
  String get reportErrorGeneric => 'Gagal memuat laporan. Coba lagi.';

  @override
  String reportInsightExpenseDown(String percent) {
    return 'Pengeluaranmu turun $percent% dari periode sebelumnya. Bagus!';
  }

  @override
  String reportInsightExpenseUp(String percent) {
    return 'Pengeluaranmu naik $percent% dari periode sebelumnya. Perhatikan lebih.';
  }

  @override
  String get reportInsightStable =>
      'Pengeluaranmu relatif stabil dibanding periode sebelumnya.';

  @override
  String get reportInsightNoData =>
      'Mulai catat transaksi untuk melihat insight laporan.';

  @override
  String get reportSeeFullReport => 'Lihat Laporan Lengkap';

  @override
  String get thisQuarter => 'Kuartal Ini';

  @override
  String get transactionDeleteConfirmTitle => 'Hapus Transaksi?';

  @override
  String get transactionDeleteConfirmMessage =>
      'Transaksi ini akan dihapus permanen dan saldo dompet akan disesuaikan.';

  @override
  String get transactionTransferToAsset => 'Transfer ke Aset';

  @override
  String transactionItemCount(int count) {
    return '$count item';
  }

  @override
  String get reportOthersCategory => 'Lainnya';

  @override
  String get reportTransactionCountLabel => 'transaksi';

  @override
  String get ocrBalanceItem => 'Item lainnya';

  @override
  String get ocrDiscountItem => 'Diskon/potongan';

  @override
  String get validationAmountPositive => 'Nominal harus lebih dari 0';

  @override
  String get validationTransferNeedsDest => 'Transfer memerlukan dompet tujuan';

  @override
  String get validationMinOneItem => 'Transaksi harus memiliki minimal 1 item';

  @override
  String validationItemsTotalMismatch(String itemsSum, String totalAmount) {
    return 'Total item ($itemsSum) tidak sama dengan total transaksi ($totalAmount)';
  }

  @override
  String get validationCategoryRequired =>
      'Kategori wajib dipilih untuk setiap item';

  @override
  String get validationBudgetAmountPositive =>
      'Nominal anggaran harus lebih dari 0';

  @override
  String get validationEndBeforeStart =>
      'Tanggal akhir tidak boleh sebelum tanggal mulai';

  @override
  String get validationBudgetDuplicate =>
      'Sudah ada anggaran aktif untuk kategori dan periode yang sama';

  @override
  String get validationDeleteOldBudgetFailed => 'Gagal menghapus anggaran lama';

  @override
  String get validationWalletNameEmpty => 'Nama dompet tidak boleh kosong';

  @override
  String get validationInitialBalanceNegative =>
      'Saldo awal tidak boleh negatif';

  @override
  String get validationWalletNameDuplicate => 'Nama dompet sudah digunakan';

  @override
  String get validationWalletHasTransactions =>
      'Dompet tidak bisa dihapus karena masih memiliki transaksi. Hapus transaksi terlebih dahulu.';

  @override
  String get debtLoanTitle => 'Hutang & Piutang';

  @override
  String get debtLoanTabToPay => 'Untuk Dibayar';

  @override
  String get debtLoanTabToReceive => 'Untuk Diterima';

  @override
  String get debtLoanUnpaid => 'BELUM LUNAS';

  @override
  String get debtLoanPaid => 'LUNAS';

  @override
  String get debtLoanAllWallets => 'Semua Dompet';

  @override
  String debtLoanTransactionCount(int count) {
    return '$count transaksi';
  }

  @override
  String get debtLoanRemaining => 'tersisa';

  @override
  String get debtLoanSettled => 'terlunasi';

  @override
  String get debtLoanPersonTitle => 'Daftar Transaksi';

  @override
  String debtLoanPersonResult(int count) {
    return '$count hasil';
  }

  @override
  String get debtLoanPersonIncome => 'Pemasukan';

  @override
  String get debtLoanPersonExpense => 'Pengeluaran';

  @override
  String get debtLoanSettlementTitle => 'Pelunasan';

  @override
  String get debtLoanSettlementAmount => 'Jumlah Pelunasan';

  @override
  String get debtLoanSettlementWallet => 'Dompet Pembayaran';

  @override
  String get debtLoanSettlementNote => 'Catatan (opsional)';

  @override
  String get debtLoanSettlementSubmit => 'Simpan Pelunasan';

  @override
  String get debtLoanSettlementSuccess => 'Pelunasan berhasil disimpan';

  @override
  String debtLoanSettlementRemainder(String amount) {
    return 'Sisa: $amount';
  }

  @override
  String get debtLoanPayDebt => 'Lunasi Hutang';

  @override
  String get debtLoanCollectLoan => 'Terima Pembayaran';

  @override
  String get debtLoanSettlementHistory => 'DAFTAR TRANSAKSI';

  @override
  String get debtLoanLender => 'Pemberi Pinjaman';

  @override
  String get debtLoanBorrower => 'Peminjam';

  @override
  String get debtLoanStatusPaid => 'Lunas';

  @override
  String get debtLoanStatusRemaining => 'Tersisa';

  @override
  String debtLoanDebtPaymentDesc(String person) {
    return 'Hutang dibayar ke $person';
  }

  @override
  String debtLoanLoanCollectionDesc(String person) {
    return 'Piutang diterima dari $person';
  }

  @override
  String get debtLoanRepayment => 'Pembayaran kembali';

  @override
  String get debtLoanCollection => 'Penerimaan';

  @override
  String get debtLoanEmpty => 'Belum ada catatan hutang atau piutang';

  @override
  String get debtLoanEmptyPerson => 'Belum ada transaksi';

  @override
  String get debtLoanSomeone => 'Seseorang';

  @override
  String get debtLoanExcludedFromReport =>
      'Transaksi ini dikecualikan dari laporan';

  @override
  String get debtLoanSettlementHistoryTitle => 'Riwayat Pelunasan';

  @override
  String debtLoanTitleDebt(String person) {
    return 'Hutang ke $person';
  }

  @override
  String debtLoanTitleLoan(String person) {
    return 'Piutang ke $person';
  }

  @override
  String debtLoanTitlePayment(String person) {
    return 'Pelunasan ke $person';
  }

  @override
  String debtLoanTitleReceipt(String person) {
    return 'Penerimaan dari $person';
  }

  @override
  String get profileDebtLoan => 'Hutang & Piutang';

  @override
  String get debtLoanFormSubCategory => 'Kategori';

  @override
  String get debtLoanFormPickTransaction => 'Pilih Transaksi';

  @override
  String get debtLoanFormNoUnpaidDebt => 'Tidak ada hutang yang belum lunas';

  @override
  String get debtLoanFormNoUnpaidLoan => 'Tidak ada piutang yang belum lunas';

  @override
  String debtLoanFormAmountExceedsRemaining(String amount) {
    return 'Nominal melebihi sisa $amount';
  }

  @override
  String get debtLoanFormTabLabel => 'Hutang/Piutang';

  @override
  String get debtLoanFormSelectedTransaction => 'Transaksi Terpilih';

  @override
  String debtLoanFormRemainingAmount(String amount) {
    return 'Sisa: $amount';
  }

  @override
  String get debtLoanSettlementEditTitle => 'Edit Pelunasan';

  @override
  String get debtLoanSettlementEditSuccess => 'Pelunasan berhasil diperbarui';

  @override
  String get debtLoanSettlementDeleteConfirm => 'Hapus pelunasan ini?';

  @override
  String get debtLoanSettlementDeleteMessage =>
      'Saldo dompet akan dikembalikan dan status hutang/piutang akan dihitung ulang.';

  @override
  String get debtLoanSettlementDeleteSuccess => 'Pelunasan berhasil dihapus';

  @override
  String debtLoanSettlementMaxAmount(String amount) {
    return 'Maks: $amount';
  }

  @override
  String get fabTextInput => 'Input Teks';

  @override
  String get textInputTitle => 'Input via Teks';

  @override
  String get textInputHint => 'cth. Makan siang di warteg 15rb';

  @override
  String get textInputSubmit => 'Analisis';

  @override
  String get textInputAnalyzing => 'Menganalisis dengan AI...';

  @override
  String get textInputError => 'Gagal menganalisis teks';

  @override
  String get textInputEmpty => 'Silakan masukkan deskripsi transaksi';

  @override
  String get aiParseCancelTitle => 'Batalkan Analisis?';

  @override
  String get aiParseCancelMessage =>
      'AI sedang menganalisis data. Yakin ingin membatalkan?';

  @override
  String get aiParseCancelConfirm => 'Ya, Batalkan';

  @override
  String get aiPreviewDiscardTitle => 'Buang Hasil?';

  @override
  String get aiPreviewDiscardMessage =>
      'Hasil analisa AI akan dibuang. Kamu harus memulai ulang untuk mendapatkan hasil baru.';

  @override
  String get aiPreviewDiscardConfirm => 'Ya, Buang';

  @override
  String aiPreviewItemsHeader(int count) {
    return '$count item terdeteksi';
  }

  @override
  String get aiPreviewGrandTotal => 'Total';

  @override
  String aiPreviewTotalMismatch(String itemsTotal, String grandTotal) {
    return 'Total item ($itemsTotal) tidak cocok dengan total ($grandTotal)';
  }

  @override
  String get aiPreviewMultiTitle => 'Beberapa transaksi';

  @override
  String get aiPreviewMultiSubtitle =>
      'Akan dibuka dalam mode multi transaksi. Periksa tiap baris sebelum menyimpan.';

  @override
  String get aiPreviewMultiOcrAttachmentHint =>
      'Foto struk dilampirkan ke transaksi pertama; kamu bisa memindahkannya jika perlu.';

  @override
  String get aiPreviewMultiCombinedTotal => 'Total gabungan';

  @override
  String aiPreviewMultiTransactionN(int n) {
    return 'Transaksi $n';
  }

  @override
  String get navInvestment => 'Investasi';

  @override
  String get navSettings => 'Pengaturan';

  @override
  String get investmentTitle => 'Portofolio Investasi';

  @override
  String get investmentTotalValue => 'Total Nilai Portofolio';

  @override
  String get investmentTotalInvested => 'Total Modal';

  @override
  String get investmentProfitLoss => 'Keuntungan/Kerugian';

  @override
  String get investmentProfit => 'Untung';

  @override
  String get investmentLoss => 'Rugi';

  @override
  String get investmentEmpty => 'Belum ada investasi';

  @override
  String get investmentEmptyHint =>
      'Tap + untuk mulai catat investasi pertamamu';

  @override
  String get investmentAddAsset => 'Tambah Investasi';

  @override
  String get investmentActiveAssets => 'Aset Aktif';

  @override
  String get investmentInactiveAssets => 'Aset Tidak Aktif';

  @override
  String get investmentViewInactive => 'Lihat Aset Tidak Aktif';

  @override
  String get investmentSectionGold => 'Emas';

  @override
  String get investmentSectionBitcoin => 'Bitcoin';

  @override
  String get investmentSectionCustom => 'Aset Kustom';

  @override
  String get investmentTypeGold => 'Emas';

  @override
  String get investmentTypeBitcoin => 'Bitcoin';

  @override
  String get investmentTypeCustom => 'Kustom';

  @override
  String get investmentDetailTitle => 'Detail Investasi';

  @override
  String get investmentDetailCurrentPrice => 'Harga Saat Ini';

  @override
  String get investmentDetailAvgBuyPrice => 'Rata-rata Harga Beli';

  @override
  String get investmentDetailTotalUnits => 'Total Unit';

  @override
  String get investmentDetailTotalInvested => 'Total Modal';

  @override
  String get investmentDetailCurrentValue => 'Nilai Saat Ini';

  @override
  String get investmentDetailProfitLoss => 'Keuntungan/Kerugian';

  @override
  String get investmentDetailTotalFee => 'Total Biaya';

  @override
  String get investmentPriceLastUpdated => 'Terakhir diperbarui';

  @override
  String get investmentDetailTransactions => 'Riwayat Transaksi';

  @override
  String get investmentDetailBuyHistory => 'Riwayat Beli';

  @override
  String get investmentDetailSellHistory => 'Riwayat Jual';

  @override
  String get investmentDetailNoTransactions => 'Belum ada transaksi';

  @override
  String get investmentDetailTopUp => 'Top Up';

  @override
  String get investmentDetailSell => 'Jual';

  @override
  String get investmentDetailSettings => 'Pengaturan';

  @override
  String get investmentFormCreateTitle => 'Investasi Baru';

  @override
  String get investmentFormTopUpTitle => 'Top Up Investasi';

  @override
  String get investmentFormEditTitle => 'Edit Transaksi';

  @override
  String get investmentFormAssetName => 'Nama Aset';

  @override
  String get investmentFormAssetNameHint =>
      'Contoh: Emas Antam, Bitcoin, Saham BBCA';

  @override
  String get investmentFormAssetNameRequired => 'Nama aset tidak boleh kosong';

  @override
  String get investmentFormType => 'Jenis Aset';

  @override
  String get investmentFormGoldType => 'Jenis Emas';

  @override
  String get investmentFormGoldTypeHint => 'Pilih jenis emas';

  @override
  String get investmentFormCustomCategory => 'Kategori Aset';

  @override
  String get investmentFormCustomCategoryHint => 'Pilih kategori';

  @override
  String get investmentFormUnits => 'Jumlah Unit';

  @override
  String get investmentFormUnitsHint => 'Contoh: 1.5';

  @override
  String get investmentFormUnitsRequired => 'Jumlah unit tidak boleh kosong';

  @override
  String get investmentFormPricePerUnit => 'Harga per Unit';

  @override
  String get investmentFormPricePerUnitRequired =>
      'Harga per unit tidak boleh kosong';

  @override
  String get investmentFormFee => 'Biaya (opsional)';

  @override
  String get investmentFormFeeHint => 'Biaya admin/spread';

  @override
  String get investmentFormDate => 'Tanggal Transaksi';

  @override
  String get investmentFormNote => 'Catatan (opsional)';

  @override
  String get investmentFormDeductWallet => 'Potong Saldo Dompet';

  @override
  String get investmentFormDeductWalletHint =>
      'Kurangi saldo dompet sesuai total pembelian';

  @override
  String get investmentFormSelectWallet => 'Pilih Dompet';

  @override
  String get investmentFormWalletRequired => 'Pilih dompet terlebih dahulu';

  @override
  String get investmentFormSave => 'Simpan';

  @override
  String get investmentFormTotalCost => 'Total Biaya Pembelian';

  @override
  String get investmentFormCurrentPrice => 'Harga Saat Ini (opsional)';

  @override
  String get investmentSellTitle => 'Jual Investasi';

  @override
  String get investmentSellUnits => 'Jumlah Unit Dijual';

  @override
  String investmentSellUnitsHint(String maxUnits) {
    return 'Maks: $maxUnits';
  }

  @override
  String get investmentSellUnitsRequired =>
      'Jumlah unit dijual tidak boleh kosong';

  @override
  String investmentSellUnitsExceed(String available) {
    return 'Unit dijual melebihi unit tersedia ($available)';
  }

  @override
  String get investmentSellPricePerUnit => 'Harga Jual per Unit';

  @override
  String get investmentSellPriceRequired => 'Harga jual tidak boleh kosong';

  @override
  String get investmentSellFee => 'Biaya Jual (opsional)';

  @override
  String get investmentSellCreditWallet => 'Tambah ke Saldo Dompet';

  @override
  String get investmentSellCreditWalletHint =>
      'Tambahkan hasil penjualan ke saldo dompet';

  @override
  String get investmentSellTotal => 'Total Hasil Penjualan';

  @override
  String get investmentSellConfirm => 'Konfirmasi Jual';

  @override
  String get investmentSellAll => 'Jual Semua';

  @override
  String get investmentSettingsTitle => 'Pengaturan Aset';

  @override
  String get investmentSettingsName => 'Nama Aset';

  @override
  String get investmentSettingsCurrentPrice => 'Harga Saat Ini';

  @override
  String get investmentSettingsCategory => 'Kategori Aset';

  @override
  String get investmentSettingsCategoryHint =>
      'Pilih kategori untuk menentukan satuan';

  @override
  String get investmentSettingsStatus => 'Status';

  @override
  String get investmentSettingsActive => 'Aktif';

  @override
  String get investmentSettingsInactive => 'Tidak Aktif';

  @override
  String get investmentSettingsSave => 'Simpan Perubahan';

  @override
  String get investmentSettingsDelete => 'Hapus Investasi';

  @override
  String investmentSettingsDeleteConfirm(String name) {
    return 'Yakin ingin menghapus \"$name\"? Semua transaksi investasi ini juga akan terhapus.';
  }

  @override
  String get investmentSettingsDeleteWalletRevert =>
      'Saldo dompet terkait akan dikembalikan.';

  @override
  String get investmentGoldTypeTitle => 'Jenis Emas Kustom';

  @override
  String get investmentGoldTypeAdd => 'Tambah Jenis Emas';

  @override
  String get investmentGoldTypeEdit => 'Edit Jenis Emas';

  @override
  String get investmentGoldTypeName => 'Nama Jenis Emas';

  @override
  String get investmentGoldTypeNameHint => 'Contoh: UBS, Galeri 24';

  @override
  String get investmentGoldTypeNameRequired =>
      'Nama jenis emas tidak boleh kosong';

  @override
  String investmentGoldTypeMax(int max) {
    return 'Maksimal $max jenis emas kustom';
  }

  @override
  String investmentGoldTypeDeleteConfirm(String name) {
    return 'Yakin hapus jenis emas \"$name\"?';
  }

  @override
  String get investmentCategoryTitle => 'Kategori Aset Kustom';

  @override
  String get investmentCategoryAdd => 'Tambah Kategori';

  @override
  String get investmentCategoryEdit => 'Edit Kategori';

  @override
  String get investmentCategoryName => 'Nama Kategori';

  @override
  String get investmentCategoryNameHint => 'Contoh: Saham, Reksadana';

  @override
  String get investmentCategoryNameRequired =>
      'Nama kategori tidak boleh kosong';

  @override
  String get investmentCategoryUnitLabel => 'Satuan';

  @override
  String get investmentCategoryUnitLabelHint => 'Contoh: lot, unit, lembar';

  @override
  String get investmentCategoryUnitLabelRequired => 'Satuan tidak boleh kosong';

  @override
  String investmentCategoryMax(int max) {
    return 'Maksimal $max kategori kustom';
  }

  @override
  String investmentCategoryDeleteConfirm(String name) {
    return 'Yakin hapus kategori \"$name\"?';
  }

  @override
  String get investmentCategoryManage => 'Kelola Kategori';

  @override
  String get investmentInactiveTitle => 'Aset Tidak Aktif';

  @override
  String get investmentInactiveEmpty => 'Tidak ada aset tidak aktif';

  @override
  String get investmentInactiveHint =>
      'Aset yang telah dijual sepenuhnya akan muncul di sini';

  @override
  String get investmentInactiveReactivate => 'Aktifkan Kembali';

  @override
  String investmentSuccessCreate(String name) {
    return 'Investasi \"$name\" berhasil ditambahkan';
  }

  @override
  String get investmentSuccessTopUp => 'Top up berhasil';

  @override
  String get investmentSuccessSell => 'Penjualan berhasil';

  @override
  String get investmentSuccessEdit => 'Transaksi berhasil diperbarui';

  @override
  String get investmentSuccessDelete => 'Investasi berhasil dihapus';

  @override
  String get investmentSuccessUpdate => 'Investasi berhasil diperbarui';

  @override
  String get investmentSuccessDeleteTransaction => 'Transaksi berhasil dihapus';

  @override
  String get investmentErrorGeneric => 'Gagal memproses. Coba lagi.';

  @override
  String get investmentErrorLoad => 'Gagal memuat data investasi';

  @override
  String get investmentErrorCreate => 'Gagal menambah investasi';

  @override
  String get investmentErrorTopUp => 'Gagal top up investasi';

  @override
  String get investmentErrorSell => 'Gagal menjual investasi';

  @override
  String get investmentErrorEdit => 'Gagal memperbarui transaksi';

  @override
  String get investmentErrorDelete => 'Gagal menghapus investasi';

  @override
  String get investmentErrorDeleteTransaction => 'Gagal menghapus transaksi';

  @override
  String get investmentUnitGram => 'gram';

  @override
  String get investmentUnitBtc => 'BTC';

  @override
  String get investmentGoldAntam => 'Antam';

  @override
  String get investmentGoldPerhiasan => 'Perhiasan';

  @override
  String investmentPriceSource(String source) {
    return 'Sumber: $source';
  }

  @override
  String investmentLastUpdated(String time) {
    return 'Diperbarui: $time';
  }

  @override
  String get investmentBuyPrice => 'Harga Beli';

  @override
  String get investmentSellPrice => 'Harga Jual';

  @override
  String get investmentDirection => 'Tipe';

  @override
  String get investmentDirectionBuy => 'Beli';

  @override
  String get investmentDirectionSell => 'Jual';

  @override
  String investmentTransactionCount(int count) {
    return '$count transaksi';
  }

  @override
  String get investmentFormPriceSource => 'Sumber Harga';

  @override
  String get investmentFormPriceSourceHint => 'Pilih sumber harga';

  @override
  String get investmentPriceSourceAntaremas => 'antaremas.com';

  @override
  String get investmentPriceSourceLogammulia => 'logammulia.com';

  @override
  String get investmentPriceSourceManual => 'Input Manual';

  @override
  String get investmentPriceSourceIndodax => 'Indodax';

  @override
  String get investmentPriceSourceCoingecko => 'CoinGecko';

  @override
  String get investmentPriceSourceLocked =>
      'Terkunci ke Manual untuk jenis emas ini';

  @override
  String get investmentManageGoldTypes => 'Kelola Jenis Emas';

  @override
  String get investmentDeleteTransaction => 'Hapus Transaksi';

  @override
  String get investmentDeleteTransactionConfirm =>
      'Yakin ingin menghapus transaksi ini? Saldo dompet akan dikembalikan jika terkait.';

  @override
  String get investmentSettingsRevertWallet =>
      'Kembalikan saldo dompet terkait';

  @override
  String get investmentEditCurrentPrice => 'Perbarui Harga Pasar';

  @override
  String get investmentEditCurrentPriceHint => 'Masukkan harga pasar saat ini';

  @override
  String get investmentSettingsGoldType => 'Jenis Emas';

  @override
  String get investmentSettingsPriceSource => 'Sumber Harga';

  @override
  String get investmentWalletRequired => 'Silakan pilih dompet terlebih dahulu';

  @override
  String aiQuotaRemaining(int remaining, int limit) {
    return 'Sisa $remaining dari $limit kali hari ini';
  }

  @override
  String get aiQuotaExhausted => 'Batas harian tercapai. Coba lagi besok.';

  @override
  String get aiQuotaText => 'Input Teks';

  @override
  String get aiQuotaVoice => 'Input Suara';

  @override
  String get aiQuotaOcr => 'Scan Struk';

  @override
  String get aiQuotaLabel => 'Kuota AI';

  @override
  String get settingsSendReport => 'Kirim Laporan';

  @override
  String get sendReportTitle => 'Kirim Laporan';

  @override
  String get sendReportCategory => 'Kategori';

  @override
  String get sendReportCategoryHint => 'Pilih kategori laporan';

  @override
  String get sendReportFormTitle => 'Judul';

  @override
  String get sendReportFormTitleHint => 'Tuliskan judul laporan singkat';

  @override
  String get sendReportDescription => 'Deskripsi';

  @override
  String get sendReportDescriptionHint =>
      'Jelaskan masalah atau permintaanmu secara detail';

  @override
  String get sendReportPhoto => 'Foto Lampiran';

  @override
  String get sendReportAddPhoto => 'Tambah Foto (Opsional)';

  @override
  String get sendReportChangePhoto => 'Ganti Foto';

  @override
  String get sendReportRemovePhoto => 'Hapus Foto';

  @override
  String get sendReportSubmit => 'Kirim Laporan';

  @override
  String get sendReportSuccessTitle => 'Laporan Terkirim';

  @override
  String get sendReportSuccessMessage =>
      'Terima kasih! Laporan kamu sudah kami terima.';

  @override
  String get sendReportValidateCategory => 'Pilih kategori laporan';

  @override
  String get sendReportValidateTitle => 'Judul minimal 5 karakter';

  @override
  String get sendReportValidateDescription => 'Deskripsi minimal 10 karakter';

  @override
  String get sendReportCategoryBugReport => 'Laporan Bug';

  @override
  String get sendReportCategoryFeatureRequest => 'Permintaan Fitur';

  @override
  String get sendReportCategoryAccountIssue => 'Masalah Akun';

  @override
  String get sendReportCategoryPaymentIssue => 'Masalah Pembayaran';

  @override
  String get sendReportCategoryOther => 'Lainnya';

  @override
  String reportInsightRatioHealthy(String percent) {
    return 'Kamu membelanjakan $percent% dari pemasukanmu. Sisanya bisa ditabung atau diinvestasikan. Lanjutkan! 👏';
  }

  @override
  String reportInsightRatioWarning(String percent) {
    return 'Kamu membelanjakan $percent% dari pemasukanmu. Idealnya di bawah 50% supaya ada ruang menabung.';
  }

  @override
  String reportInsightRatioDanger(String percent) {
    return 'Kamu membelanjakan $percent% dari pemasukanmu — hampir tidak ada sisa. Coba kurangi pengeluaran yang tidak mendesak.';
  }

  @override
  String reportInsightRatioCritical(String amount) {
    return 'Pengeluaranmu melebihi pemasukan sebesar $amount. Kamu sedang memakai tabungan. Perlu segera dievaluasi.';
  }

  @override
  String get reportInsightRatioNoIncome =>
      'Belum ada pemasukan tercatat. Catat pemasukan agar bisa menganalisis kesehatan keuanganmu.';

  @override
  String reportInsightTrendDownBig(String amount, String percent) {
    return 'Pengeluaranmu turun $amount ($percent%) dari periode lalu. Kerja bagus — pertahankan pola ini! 👍';
  }

  @override
  String reportInsightTrendDownSmall(String percent) {
    return 'Pengeluaranmu turun sedikit ($percent%). Sudah di jalur yang baik!';
  }

  @override
  String reportInsightTrendStable(String amount) {
    return 'Pengeluaranmu stabil — total $amount periode ini.';
  }

  @override
  String reportInsightTrendUpSmall(String percent) {
    return 'Pengeluaranmu naik sedikit ($percent%). Cek apakah ada kebutuhan dadakan atau bisa dikurangi.';
  }

  @override
  String reportInsightTrendUpBig(
    String amount,
    String percent,
    String category,
  ) {
    return 'Pengeluaranmu naik $amount ($percent%). Penyebab terbesar: $category. Coba batasi di kategori ini.';
  }

  @override
  String reportInsightTrendUpBigNoCategory(String amount, String percent) {
    return 'Pengeluaranmu naik $amount ($percent%) dari periode lalu. Coba evaluasi pengeluaran yang bisa dikurangi.';
  }

  @override
  String reportInsightCategoryDominant(
    String category,
    String percent,
    String amount,
  ) {
    return 'Kategori $category mendominasi $percent% pengeluaranmu ($amount). Cek apakah bisa dikurangi.';
  }

  @override
  String reportInsightPeakDay(String date, String amount, String percent) {
    return 'Pengeluaran terbesar di tanggal $date ($amount), yaitu $percent% dari total pengeluaran.';
  }

  @override
  String get iconPickerTitle => 'Pilih Ikon';

  @override
  String get iconPickerSearch => 'Cari ikon...';

  @override
  String get iconSearchEmpty => 'Ikon tidak ditemukan';

  @override
  String get iconSectionFinance => 'Keuangan';

  @override
  String get iconSectionShopping => 'Belanja & Gaya Hidup';

  @override
  String get iconSectionFoodDrink => 'Makanan & Minuman';

  @override
  String get iconSectionHousehold => 'Rumah Tangga';

  @override
  String get iconSectionTransport => 'Transportasi';

  @override
  String get iconSectionHealth => 'Kesehatan & Kebugaran';

  @override
  String get iconSectionBills => 'Tagihan & Utilitas';

  @override
  String get iconSectionTech => 'Teknologi';

  @override
  String get iconSectionEducation => 'Pendidikan & Karier';

  @override
  String get iconSectionEntertainment => 'Hiburan';

  @override
  String get iconSectionNature => 'Alam & Hewan';

  @override
  String get iconSectionSocial => 'Sosial & Keluarga';

  @override
  String get iconSectionOther => 'Lainnya';

  @override
  String get noMoreData => 'Data kamu cukup sampai sini nih..';

  @override
  String get exportImportTitle => 'Import & Export';

  @override
  String get exportTabExport => 'Export';

  @override
  String get exportTabImport => 'Import';

  @override
  String get exportImportComingTitle => 'Segera hadir';

  @override
  String get exportImportComingBody =>
      'Impor data ke SakuRapi akan tersedia di pembaruan berikutnya.';

  @override
  String get exportFormatLabel => 'Format file';

  @override
  String get exportFormatExcel => 'Excel (.xlsx)';

  @override
  String get exportFormatPdf => 'PDF';

  @override
  String get exportFormatCsv => 'CSV';

  @override
  String get exportSoonShort => 'Segera hadir';

  @override
  String get exportPeriodLabel => 'Periode laporan';

  @override
  String get exportSelectPeriod => 'Pilih periode';

  @override
  String get exportPeriodThisMonth => 'Bulan ini';

  @override
  String get exportPeriodLastMonth => 'Bulan lalu';

  @override
  String get exportPeriodThisQuarter => 'Quartal ini';

  @override
  String get exportPeriodThisYear => 'Tahun ini';

  @override
  String get exportPeriodCustom => 'Kustom';

  @override
  String get exportSelectCustomRange => 'Pilih rentang tanggal kustom';

  @override
  String get exportTapCustomToPickRange =>
      'Ketuk \"Kustom\", lalu pilih rentang tanggal.';

  @override
  String get exportScopeAlwaysIncluded =>
      'Pemasukan & pengeluaran (selalu disertakan)';

  @override
  String get exportIncludeDebt => 'Sertakan Hutang & Piutang';

  @override
  String get exportIncludeTransfer => 'Sertakan transfer antar dompet';

  @override
  String get exportDashboardNote =>
      'Ringkasan di lembar Dashboard hanya memakai pemasukan dan pengeluaran periode. Transfer tidak ikut dihitung di sana.';

  @override
  String get exportBuildButton => 'Buat laporan Excel';

  @override
  String get exportProgressMessage =>
      'Mohon tunggu, data kamu sedang diproses…';

  @override
  String get exportCancel => 'Batalkan';

  @override
  String get exportStopAndBuild => 'Hentikan dan buat sekarang';

  @override
  String get exportSuccessTitle => 'Laporan siap';

  @override
  String get exportOpenFile => 'Buka file';

  @override
  String get exportShareFile => 'Bagikan';

  @override
  String get exportClose => 'Tutup';

  @override
  String get exportErrorGeneric => 'Gagal membuat laporan. Coba lagi.';

  @override
  String get exportPartialWarning =>
      'Beberapa data periode mungkin belum terambil. File ini dibuat dari data yang sudah tersedia.';

  @override
  String exportSavedPath(String path) {
    return 'Disimpan ke: $path';
  }

  @override
  String get exportReportBrandTitle => 'Laporan Keuangan SakuRapi';

  @override
  String get exportSheetDashboard => 'Dashboard';

  @override
  String get exportSheetTransactions => 'Data Transaksi';

  @override
  String get exportSheetCategoryAnalysis => 'Analisis Kategori';

  @override
  String get exportSheetDebt => 'Hutang Piutang';

  @override
  String get exportSheetTransfer => 'Transfer';

  @override
  String get exportSummaryIncomeBox => 'Total Pemasukan';

  @override
  String get exportSummaryExpenseBox => 'Total Pengeluaran';

  @override
  String get exportSummaryBalanceBox => 'Saldo Akhir';

  @override
  String get exportDebtUnpaidTotalTitle => 'Total Hutang yang Belum Dibayar';

  @override
  String get exportReceivableUnpaidTotalTitle =>
      'Total Piutang yang Belum Dibayar';

  @override
  String get exportColNo => 'No';

  @override
  String get exportColDate => 'Tanggal';

  @override
  String get exportColType => 'Tipe';

  @override
  String get exportColCategory => 'Kategori';

  @override
  String get exportColNote => 'Catatan';

  @override
  String get exportColWallet => 'Dompet';

  @override
  String get exportColAmount => 'Nominal';

  @override
  String get exportColPerson => 'Nama Orang';

  @override
  String get exportColDueDate => 'Jatuh Tempo';

  @override
  String get exportColStatus => 'Status';

  @override
  String get exportColWalletSource => 'Dompet Asal';

  @override
  String get exportColWalletDest => 'Dompet Tujuan';

  @override
  String get exportAnalysisCategory => 'Nama Kategori';

  @override
  String get exportAnalysisTotal => 'Total Nominal';

  @override
  String get exportAnalysisPercent => 'Persentase (%)';

  @override
  String get exportDailySummaryTitle => 'Ringkasan harian (grafik)';

  @override
  String get exportDailyDate => 'Tanggal';

  @override
  String get exportDailyIncome => 'Pemasukan';

  @override
  String get exportDailyExpense => 'Pengeluaran';

  @override
  String get exportChartCategoryTitle => 'Porsi pengeluaran per kategori';

  @override
  String get exportChartCategoryOthers => 'Lain-lain';

  @override
  String get exportChartBarTitle => 'Pemasukan vs pengeluaran harian';

  @override
  String get exportStatusLunas => 'Lunas';

  @override
  String get exportStatusBelumLunas => 'Belum Lunas';

  @override
  String exportPeriodExcelLabel(String range) {
    return 'Periode: $range';
  }

  @override
  String get exportPartialIncompleteNote =>
      'Catatan: export sebagian — data periode mungkin tidak lengkap.';

  @override
  String get exportBuildButtonPdf => 'Buat laporan PDF';

  @override
  String get exportTocTitle => 'Daftar isi';

  @override
  String get exportCoverAppBrand => 'SakuRapi';

  @override
  String get exportCoverGeneratedLabel => 'Dibuat:';

  @override
  String get exportPdfDailyTableSectionTitle => 'Ringkasan harian';

  @override
  String get exportChartDailyTrendTitle => 'Tren harian';

  @override
  String get exportPdfDashboardSectionTitle => 'Dashboard & ringkasan harian';
}
