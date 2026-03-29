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
  String get dashboardSnapshotTitle => 'Ringkasan Bulan Ini';

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
  String get investmentTitle => 'Investasi';

  @override
  String get investmentAdd => 'Tambah Investasi';

  @override
  String get investmentEdit => 'Edit Investasi';

  @override
  String get investmentDelete => 'Hapus Investasi';

  @override
  String get investmentPortfolio => 'Total Portofolio';

  @override
  String get investmentTotalValue => 'Nilai Saat Ini';

  @override
  String get investmentTotalPL => 'Total P&L';

  @override
  String get investmentTypeGold => 'Emas';

  @override
  String get investmentTypeBtc => 'Bitcoin';

  @override
  String get investmentTypeCustom => 'Kustom';

  @override
  String get investmentBuyPrice => 'Harga Beli';

  @override
  String get investmentCurrentPrice => 'Harga Saat Ini';

  @override
  String get investmentAmount => 'Jumlah';

  @override
  String get investmentUnit => 'unit';

  @override
  String get investmentEmptyTitle => 'Belum Ada Investasi';

  @override
  String get investmentEmptySubtitle =>
      'Ketuk + untuk menambahkan aset pertama Anda';

  @override
  String get investmentRefreshPrice => 'Perbarui Harga';

  @override
  String get investmentFormTitleAdd => 'Tambah Investasi';

  @override
  String get investmentFormTitleEdit => 'Edit Investasi';

  @override
  String get investmentFormType => 'Tipe Aset';

  @override
  String get investmentFormName => 'Nama Aset';

  @override
  String get investmentFormNameHint => 'misal: Emas Antam, BTC';

  @override
  String get investmentFormNameRequired => 'Nama aset wajib diisi';

  @override
  String get investmentFormAmount => 'Jumlah Unit';

  @override
  String get investmentFormAmountRequired => 'Jumlah wajib diisi';

  @override
  String get investmentFormAmountInvalid => 'Jumlah harus lebih dari 0';

  @override
  String get investmentFormBuyPrice => 'Harga Beli per Unit (IDR)';

  @override
  String get investmentFormBuyPriceRequired => 'Harga beli wajib diisi';

  @override
  String get investmentFormBuyPriceInvalid => 'Harga beli harus lebih dari 0';

  @override
  String get investmentFormCurrentPrice => 'Harga Saat Ini (IDR)';

  @override
  String get investmentFormCurrentPriceHint => 'Opsional — untuk aset kustom';

  @override
  String get investmentFormDeductWallet => 'Potong dari Dompet';

  @override
  String get investmentFormDeductWalletSubtitle =>
      'Saldo dompet akan dikurangi otomatis';

  @override
  String get investmentFormWallet => 'Pilih Dompet';

  @override
  String get investmentFormWalletRequired => 'Pilih dompet terlebih dahulu';

  @override
  String get investmentFormNotes => 'Catatan';

  @override
  String get investmentFormNotesHint => 'Opsional';

  @override
  String get investmentFormEstimatedCost => 'Estimasi Total Biaya';

  @override
  String get investmentSave => 'Simpan Investasi';

  @override
  String get investmentSuccessAdd => 'Investasi berhasil ditambahkan';

  @override
  String get investmentSuccessEdit => 'Investasi berhasil diperbarui';

  @override
  String get investmentSuccessDelete => 'Investasi berhasil dihapus';

  @override
  String get investmentErrorAdd => 'Gagal menambahkan investasi';

  @override
  String get investmentErrorEdit => 'Gagal memperbarui investasi';

  @override
  String get investmentErrorDelete => 'Gagal menghapus investasi';

  @override
  String get investmentDeleteConfirmTitle => 'Hapus Investasi?';

  @override
  String investmentDeleteConfirmMessage(String name) {
    return 'Aset \"$name\" akan dihapus permanen.';
  }

  @override
  String get investmentTotalUnits => 'Total Kepemilikan';

  @override
  String get investmentGram => 'gram';

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
  String get navInvestment => 'Investasi';

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
  String get profileEntryPoint => 'Entri Awal Transaksi';

  @override
  String get profileEntryManual => 'Form Manual';

  @override
  String get profileEntryVoice => 'Input Suara';

  @override
  String get profileEntryScan => 'Scan Struk';

  @override
  String get profileEntryPointTitle => 'Entri Awal Transaksi';

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
  String get voiceAiBusy => 'AI sedang sibuk, menggunakan parser lokal';

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
  String get ocrExtractingText => 'Membaca teks dari struk...';

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
  String get ocrAiBusy => 'AI sedang sibuk, menggunakan parser lokal';

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
  String get investmentFormSymbol => 'Symbol';

  @override
  String get investmentFormSymbolHint => 'TSLA, AAPL, etc.';

  @override
  String get assetTypeTitle => 'Kelola Jenis Aset';

  @override
  String get assetTypeAdd => 'Tambah Jenis Aset';

  @override
  String get assetTypeEdit => 'Edit Jenis Aset';

  @override
  String get assetTypeEmpty => 'Belum ada jenis aset';

  @override
  String get assetTypeEmptyHint => 'Ketuk + untuk membuat jenis aset pertama';

  @override
  String get assetTypeFormName => 'Nama Aset';

  @override
  String get assetTypeFormNameHint => 'misal: Saham BCA, Tanah, Obligasi';

  @override
  String get assetTypeFormSymbol => 'Symbol';

  @override
  String get assetTypeFormSymbolHint => 'misal: BBCA, OBL';

  @override
  String get assetTypeFormCurrentPrice => 'Harga Saat Ini (IDR)';

  @override
  String get assetTypeFormCurrentPriceHint => 'Harga per unit saat ini';

  @override
  String get assetTypeSave => 'Simpan Jenis Aset';

  @override
  String get assetTypeSuccessAdd => 'Jenis aset berhasil ditambahkan';

  @override
  String get assetTypeSuccessEdit => 'Jenis aset berhasil diperbarui';

  @override
  String get assetTypeSuccessDelete => 'Jenis aset berhasil dihapus';

  @override
  String get assetTypeErrorAdd => 'Gagal menambahkan jenis aset';

  @override
  String get assetTypeErrorEdit => 'Gagal memperbarui jenis aset';

  @override
  String get assetTypeErrorDelete => 'Gagal menghapus jenis aset';

  @override
  String get assetTypeDeleteConfirmTitle => 'Hapus Jenis Aset?';

  @override
  String assetTypeDeleteConfirmMessage(String name) {
    return '\"$name\" dan semua investasi yang menggunakan jenis aset ini akan disembunyikan.';
  }

  @override
  String assetTypeErrorDuplicateName(String name) {
    return 'Nama jenis aset \"$name\" sudah ada';
  }

  @override
  String get investmentFormAssetType => 'Jenis Aset';

  @override
  String get investmentFormAssetTypeHint => 'Pilih jenis aset';

  @override
  String get investmentFormAssetTypeEmpty =>
      'Belum ada jenis aset. Buat terlebih dahulu.';

  @override
  String get investmentManageAssetTypes => 'Kelola Jenis Aset';

  @override
  String get investmentFormCreateAssetType => 'Buat Jenis Aset Baru';

  @override
  String get investmentFilterTitle => 'Filter & Urutkan';

  @override
  String get investmentFilterSort => 'Urutkan';

  @override
  String get investmentFilterSortNewest => 'Terbaru';

  @override
  String get investmentFilterSortOldest => 'Terlama';

  @override
  String get investmentFilterSortHighest => 'Nilai Terbesar';

  @override
  String get investmentFilterSortLowest => 'Nilai Terendah';

  @override
  String get investmentFilterType => 'Tipe';

  @override
  String get investmentFilterAll => 'Semua';

  @override
  String get investmentFilterSearch => 'Cari berdasarkan nama...';

  @override
  String get investmentFilterApply => 'Terapkan Filter';

  @override
  String get investmentFilterReset => 'Reset';

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
}
