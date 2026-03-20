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
  String get pickerChooseIcon => 'Pilih Ikon';

  @override
  String get pickerChooseColor => 'Pilih Warna';

  @override
  String get pickerSearchCategory => 'Cari kategori...';
}
