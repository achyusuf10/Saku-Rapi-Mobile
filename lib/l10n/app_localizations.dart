import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @today.
  ///
  /// In id, this message translates to:
  /// **'Hari Ini'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In id, this message translates to:
  /// **'Kemarin'**
  String get yesterday;

  /// No description provided for @thisWeek.
  ///
  /// In id, this message translates to:
  /// **'Minggu Ini'**
  String get thisWeek;

  /// No description provided for @last7Days.
  ///
  /// In id, this message translates to:
  /// **'7 Hari Terakhir'**
  String get last7Days;

  /// No description provided for @thisMonth.
  ///
  /// In id, this message translates to:
  /// **'Bulan Ini'**
  String get thisMonth;

  /// No description provided for @lastMonth.
  ///
  /// In id, this message translates to:
  /// **'Bulan Lalu'**
  String get lastMonth;

  /// No description provided for @thisYear.
  ///
  /// In id, this message translates to:
  /// **'Tahun Ini'**
  String get thisYear;

  /// No description provided for @lastYear.
  ///
  /// In id, this message translates to:
  /// **'Tahun Lalu'**
  String get lastYear;

  /// No description provided for @custom.
  ///
  /// In id, this message translates to:
  /// **'Kustom'**
  String get custom;

  /// No description provided for @yearSuffix.
  ///
  /// In id, this message translates to:
  /// **'tahun'**
  String get yearSuffix;

  /// No description provided for @monthSuffix.
  ///
  /// In id, this message translates to:
  /// **'bulan'**
  String get monthSuffix;

  /// No description provided for @weekSuffix.
  ///
  /// In id, this message translates to:
  /// **'minggu'**
  String get weekSuffix;

  /// No description provided for @daySuffix.
  ///
  /// In id, this message translates to:
  /// **'hari'**
  String get daySuffix;

  /// No description provided for @hourSuffix.
  ///
  /// In id, this message translates to:
  /// **'jam'**
  String get hourSuffix;

  /// No description provided for @minuteSuffix.
  ///
  /// In id, this message translates to:
  /// **'menit'**
  String get minuteSuffix;

  /// No description provided for @agoSuffix.
  ///
  /// In id, this message translates to:
  /// **'lalu'**
  String get agoSuffix;

  /// No description provided for @justNow.
  ///
  /// In id, this message translates to:
  /// **'baru saja'**
  String get justNow;

  /// No description provided for @fabVoiceInput.
  ///
  /// In id, this message translates to:
  /// **'Input Suara'**
  String get fabVoiceInput;

  /// No description provided for @fabScanReceipt.
  ///
  /// In id, this message translates to:
  /// **'Scan Struk'**
  String get fabScanReceipt;

  /// No description provided for @fabManualInput.
  ///
  /// In id, this message translates to:
  /// **'Input Manual'**
  String get fabManualInput;

  /// No description provided for @appName.
  ///
  /// In id, this message translates to:
  /// **'SakuRapi'**
  String get appName;

  /// No description provided for @loginSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Catat keuangan tanpa capek ngetik.'**
  String get loginSubtitle;

  /// No description provided for @loginWithGoogle.
  ///
  /// In id, this message translates to:
  /// **'Masuk dengan Google'**
  String get loginWithGoogle;

  /// No description provided for @loginErrorGeneric.
  ///
  /// In id, this message translates to:
  /// **'Gagal masuk. Silakan coba lagi.'**
  String get loginErrorGeneric;

  /// No description provided for @loginTitle.
  ///
  /// In id, this message translates to:
  /// **'Selamat Datang di SakuRapi'**
  String get loginTitle;

  /// No description provided for @loginSecurityNote.
  ///
  /// In id, this message translates to:
  /// **'Data kamu aman & terenkripsi'**
  String get loginSecurityNote;

  /// No description provided for @logoutConfirm.
  ///
  /// In id, this message translates to:
  /// **'Yakin ingin keluar?'**
  String get logoutConfirm;

  /// No description provided for @logoutButton.
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get logoutButton;

  /// No description provided for @walletTitle.
  ///
  /// In id, this message translates to:
  /// **'Dompet Saya'**
  String get walletTitle;

  /// No description provided for @walletAdd.
  ///
  /// In id, this message translates to:
  /// **'Tambah Dompet'**
  String get walletAdd;

  /// No description provided for @walletEdit.
  ///
  /// In id, this message translates to:
  /// **'Edit Dompet'**
  String get walletEdit;

  /// No description provided for @walletDelete.
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get walletDelete;

  /// No description provided for @walletDeleteConfirm.
  ///
  /// In id, this message translates to:
  /// **'Yakin ingin menghapus \"{name}\"? Semua transaksi di dompet ini juga akan terhapus.'**
  String walletDeleteConfirm(String name);

  /// No description provided for @walletName.
  ///
  /// In id, this message translates to:
  /// **'Nama Dompet'**
  String get walletName;

  /// No description provided for @walletNameHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: Cash, BCA, Jago'**
  String get walletNameHint;

  /// No description provided for @walletNameRequired.
  ///
  /// In id, this message translates to:
  /// **'Nama dompet tidak boleh kosong'**
  String get walletNameRequired;

  /// No description provided for @walletInitialBalance.
  ///
  /// In id, this message translates to:
  /// **'Saldo Awal'**
  String get walletInitialBalance;

  /// No description provided for @walletBalance.
  ///
  /// In id, this message translates to:
  /// **'Saldo'**
  String get walletBalance;

  /// No description provided for @walletBalanceRequired.
  ///
  /// In id, this message translates to:
  /// **'Saldo tidak boleh kosong'**
  String get walletBalanceRequired;

  /// No description provided for @walletIcon.
  ///
  /// In id, this message translates to:
  /// **'Ikon'**
  String get walletIcon;

  /// No description provided for @walletColor.
  ///
  /// In id, this message translates to:
  /// **'Warna'**
  String get walletColor;

  /// No description provided for @walletExcludeFromTotal.
  ///
  /// In id, this message translates to:
  /// **'Kecualikan dari Total'**
  String get walletExcludeFromTotal;

  /// No description provided for @walletExcludeHint.
  ///
  /// In id, this message translates to:
  /// **'Saldo dompet ini tidak dihitung ke total'**
  String get walletExcludeHint;

  /// No description provided for @walletSave.
  ///
  /// In id, this message translates to:
  /// **'Simpan'**
  String get walletSave;

  /// No description provided for @walletTotalBalance.
  ///
  /// In id, this message translates to:
  /// **'Total Saldo'**
  String get walletTotalBalance;

  /// No description provided for @walletIncludedSection.
  ///
  /// In id, this message translates to:
  /// **'Dimasukkan dalam Total'**
  String get walletIncludedSection;

  /// No description provided for @walletExcludedSection.
  ///
  /// In id, this message translates to:
  /// **'Dikecualikan dari Total'**
  String get walletExcludedSection;

  /// No description provided for @walletEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada dompet'**
  String get walletEmpty;

  /// No description provided for @walletEmptyHint.
  ///
  /// In id, this message translates to:
  /// **'Tap + untuk menambah dompet baru'**
  String get walletEmptyHint;

  /// No description provided for @walletAdjust.
  ///
  /// In id, this message translates to:
  /// **'Sesuaikan Saldo'**
  String get walletAdjust;

  /// No description provided for @walletAdjustActual.
  ///
  /// In id, this message translates to:
  /// **'Saldo Sebenarnya'**
  String get walletAdjustActual;

  /// No description provided for @walletAdjustDiff.
  ///
  /// In id, this message translates to:
  /// **'Selisih'**
  String get walletAdjustDiff;

  /// No description provided for @walletAdjustHint.
  ///
  /// In id, this message translates to:
  /// **'Masukkan saldo asli dompet ini'**
  String get walletAdjustHint;

  /// No description provided for @walletSuccessAdd.
  ///
  /// In id, this message translates to:
  /// **'\"{name}\" berhasil ditambahkan'**
  String walletSuccessAdd(String name);

  /// No description provided for @walletSuccessEdit.
  ///
  /// In id, this message translates to:
  /// **'\"{name}\" berhasil diperbarui'**
  String walletSuccessEdit(String name);

  /// No description provided for @walletSuccessDelete.
  ///
  /// In id, this message translates to:
  /// **'\"{name}\" berhasil dihapus'**
  String walletSuccessDelete(String name);

  /// No description provided for @walletSuccessAdjust.
  ///
  /// In id, this message translates to:
  /// **'Saldo berhasil disesuaikan'**
  String get walletSuccessAdjust;

  /// No description provided for @walletErrorAdd.
  ///
  /// In id, this message translates to:
  /// **'Gagal menambah dompet'**
  String get walletErrorAdd;

  /// No description provided for @walletErrorEdit.
  ///
  /// In id, this message translates to:
  /// **'Gagal memperbarui dompet'**
  String get walletErrorEdit;

  /// No description provided for @walletErrorDelete.
  ///
  /// In id, this message translates to:
  /// **'Gagal menghapus dompet'**
  String get walletErrorDelete;

  /// No description provided for @walletErrorAdjust.
  ///
  /// In id, this message translates to:
  /// **'Gagal menyesuaikan saldo'**
  String get walletErrorAdjust;

  /// No description provided for @walletOptionEdit.
  ///
  /// In id, this message translates to:
  /// **'Edit'**
  String get walletOptionEdit;

  /// No description provided for @walletOptionDelete.
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get walletOptionDelete;

  /// No description provided for @walletOptionAdjust.
  ///
  /// In id, this message translates to:
  /// **'Sesuaikan Saldo'**
  String get walletOptionAdjust;

  /// No description provided for @retryButton.
  ///
  /// In id, this message translates to:
  /// **'Coba Lagi'**
  String get retryButton;

  /// No description provided for @confirmYes.
  ///
  /// In id, this message translates to:
  /// **'Ya'**
  String get confirmYes;

  /// No description provided for @confirmCancel.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get confirmCancel;

  /// No description provided for @transactionExpense.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran'**
  String get transactionExpense;

  /// No description provided for @transactionIncome.
  ///
  /// In id, this message translates to:
  /// **'Pemasukan'**
  String get transactionIncome;

  /// No description provided for @transactionDebt.
  ///
  /// In id, this message translates to:
  /// **'Hutang'**
  String get transactionDebt;

  /// No description provided for @transactionLoan.
  ///
  /// In id, this message translates to:
  /// **'Piutang'**
  String get transactionLoan;

  /// No description provided for @transactionTransfer.
  ///
  /// In id, this message translates to:
  /// **'Transfer'**
  String get transactionTransfer;

  /// No description provided for @transactionAdjustment.
  ///
  /// In id, this message translates to:
  /// **'Penyesuaian'**
  String get transactionAdjustment;

  /// No description provided for @transactionAmount.
  ///
  /// In id, this message translates to:
  /// **'Nominal'**
  String get transactionAmount;

  /// No description provided for @transactionCategory.
  ///
  /// In id, this message translates to:
  /// **'Kategori'**
  String get transactionCategory;

  /// No description provided for @transactionWallet.
  ///
  /// In id, this message translates to:
  /// **'Dompet'**
  String get transactionWallet;

  /// No description provided for @transactionDate.
  ///
  /// In id, this message translates to:
  /// **'Tanggal'**
  String get transactionDate;

  /// No description provided for @transactionNote.
  ///
  /// In id, this message translates to:
  /// **'Catatan'**
  String get transactionNote;

  /// No description provided for @transactionAttachment.
  ///
  /// In id, this message translates to:
  /// **'Lampiran'**
  String get transactionAttachment;

  /// No description provided for @transactionWithPerson.
  ///
  /// In id, this message translates to:
  /// **'Nama Kontak'**
  String get transactionWithPerson;

  /// No description provided for @transactionWithPersonHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: Budi, Mama'**
  String get transactionWithPersonHint;

  /// No description provided for @transactionAddItem.
  ///
  /// In id, this message translates to:
  /// **'+ Tambah Item'**
  String get transactionAddItem;

  /// No description provided for @transactionGrandTotal.
  ///
  /// In id, this message translates to:
  /// **'Total'**
  String get transactionGrandTotal;

  /// No description provided for @transactionSave.
  ///
  /// In id, this message translates to:
  /// **'Simpan'**
  String get transactionSave;

  /// No description provided for @transactionSaveSuccess.
  ///
  /// In id, this message translates to:
  /// **'Transaksi berhasil disimpan'**
  String get transactionSaveSuccess;

  /// No description provided for @transactionDeleteConfirm.
  ///
  /// In id, this message translates to:
  /// **'Hapus transaksi ini?'**
  String get transactionDeleteConfirm;

  /// No description provided for @transactionPrefilledFromVoice.
  ///
  /// In id, this message translates to:
  /// **'Diisi dari suara'**
  String get transactionPrefilledFromVoice;

  /// No description provided for @transactionPrefilledFromOcr.
  ///
  /// In id, this message translates to:
  /// **'Diisi dari struk'**
  String get transactionPrefilledFromOcr;

  /// No description provided for @transactionDebtStatus.
  ///
  /// In id, this message translates to:
  /// **'Status'**
  String get transactionDebtStatus;

  /// No description provided for @transactionUnpaid.
  ///
  /// In id, this message translates to:
  /// **'Belum Lunas'**
  String get transactionUnpaid;

  /// No description provided for @transactionPaid.
  ///
  /// In id, this message translates to:
  /// **'Sudah Lunas'**
  String get transactionPaid;

  /// No description provided for @transactionDueDate.
  ///
  /// In id, this message translates to:
  /// **'Jatuh Tempo'**
  String get transactionDueDate;

  /// No description provided for @transactionSourceWallet.
  ///
  /// In id, this message translates to:
  /// **'Dompet Asal'**
  String get transactionSourceWallet;

  /// No description provided for @transactionDestWallet.
  ///
  /// In id, this message translates to:
  /// **'Dompet Tujuan'**
  String get transactionDestWallet;

  /// No description provided for @transactionMerchant.
  ///
  /// In id, this message translates to:
  /// **'Nama Merchant'**
  String get transactionMerchant;

  /// No description provided for @transactionMerchantHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: Indomaret, Grab'**
  String get transactionMerchantHint;

  /// No description provided for @transactionWalletRequired.
  ///
  /// In id, this message translates to:
  /// **'Pilih dompet terlebih dahulu'**
  String get transactionWalletRequired;

  /// No description provided for @transactionAmountRequired.
  ///
  /// In id, this message translates to:
  /// **'Nominal harus diisi'**
  String get transactionAmountRequired;

  /// No description provided for @transactionWithPersonRequired.
  ///
  /// In id, this message translates to:
  /// **'Nama kontak wajib diisi untuk hutang/piutang'**
  String get transactionWithPersonRequired;

  /// No description provided for @transactionDestWalletRequired.
  ///
  /// In id, this message translates to:
  /// **'Pilih dompet tujuan'**
  String get transactionDestWalletRequired;

  /// No description provided for @transactionSameWalletError.
  ///
  /// In id, this message translates to:
  /// **'Dompet asal dan tujuan tidak boleh sama'**
  String get transactionSameWalletError;

  /// No description provided for @transactionErrorSave.
  ///
  /// In id, this message translates to:
  /// **'Gagal menyimpan transaksi'**
  String get transactionErrorSave;

  /// No description provided for @transactionDebtTypeHutang.
  ///
  /// In id, this message translates to:
  /// **'Hutang (saya berhutang)'**
  String get transactionDebtTypeHutang;

  /// No description provided for @transactionDebtTypePiutang.
  ///
  /// In id, this message translates to:
  /// **'Piutang (saya yang memberi hutang)'**
  String get transactionDebtTypePiutang;

  /// No description provided for @transactionSelectCategory.
  ///
  /// In id, this message translates to:
  /// **'Pilih Kategori'**
  String get transactionSelectCategory;

  /// No description provided for @transactionSelectWallet.
  ///
  /// In id, this message translates to:
  /// **'Pilih Dompet'**
  String get transactionSelectWallet;

  /// No description provided for @transactionMultiItemToggle.
  ///
  /// In id, this message translates to:
  /// **'Beberapa Item'**
  String get transactionMultiItemToggle;

  /// No description provided for @transactionNewTitle.
  ///
  /// In id, this message translates to:
  /// **'Transaksi Baru'**
  String get transactionNewTitle;

  /// No description provided for @transactionAttachmentAdd.
  ///
  /// In id, this message translates to:
  /// **'Tambah Lampiran'**
  String get transactionAttachmentAdd;

  /// No description provided for @transactionAttachmentChange.
  ///
  /// In id, this message translates to:
  /// **'Ganti Lampiran'**
  String get transactionAttachmentChange;

  /// No description provided for @transactionOptionalFields.
  ///
  /// In id, this message translates to:
  /// **'Detail Tambahan'**
  String get transactionOptionalFields;

  /// No description provided for @dashboardTitle.
  ///
  /// In id, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @dashboardTotalBalance.
  ///
  /// In id, this message translates to:
  /// **'Total Saldo'**
  String get dashboardTotalBalance;

  /// No description provided for @dashboardMyWallets.
  ///
  /// In id, this message translates to:
  /// **'Dompet Saya'**
  String get dashboardMyWallets;

  /// No description provided for @dashboardSeeAll.
  ///
  /// In id, this message translates to:
  /// **'Lihat Semua'**
  String get dashboardSeeAll;

  /// No description provided for @dashboardSnapshotTitle.
  ///
  /// In id, this message translates to:
  /// **'Ringkasan Bulan Ini'**
  String get dashboardSnapshotTitle;

  /// No description provided for @dashboardTopExpenses.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran Terbesar'**
  String get dashboardTopExpenses;

  /// No description provided for @dashboardRecentTransactions.
  ///
  /// In id, this message translates to:
  /// **'Transaksi Terkini'**
  String get dashboardRecentTransactions;

  /// No description provided for @dashboardIncomeLabel.
  ///
  /// In id, this message translates to:
  /// **'Pemasukan'**
  String get dashboardIncomeLabel;

  /// No description provided for @dashboardExpenseLabel.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran'**
  String get dashboardExpenseLabel;

  /// No description provided for @dashboardEmptyTransactions.
  ///
  /// In id, this message translates to:
  /// **'Belum ada transaksi'**
  String get dashboardEmptyTransactions;

  /// No description provided for @dashboardHideBalance.
  ///
  /// In id, this message translates to:
  /// **'Sembunyikan saldo'**
  String get dashboardHideBalance;

  /// No description provided for @dashboardShowBalance.
  ///
  /// In id, this message translates to:
  /// **'Tampilkan saldo'**
  String get dashboardShowBalance;

  /// No description provided for @dashboardExcludedFromTotal.
  ///
  /// In id, this message translates to:
  /// **'Dikecualikan dari total'**
  String get dashboardExcludedFromTotal;

  /// No description provided for @dashboardWeekLabel.
  ///
  /// In id, this message translates to:
  /// **'Minggu {week}'**
  String dashboardWeekLabel(Object week);

  /// No description provided for @dashboardComingSoon.
  ///
  /// In id, this message translates to:
  /// **'Segera Hadir'**
  String get dashboardComingSoon;

  /// No description provided for @historyTitle.
  ///
  /// In id, this message translates to:
  /// **'Riwayat'**
  String get historyTitle;

  /// No description provided for @historyTabTransactions.
  ///
  /// In id, this message translates to:
  /// **'Transaksi'**
  String get historyTabTransactions;

  /// No description provided for @historyTabReport.
  ///
  /// In id, this message translates to:
  /// **'Laporan'**
  String get historyTabReport;

  /// No description provided for @historyNoTransactions.
  ///
  /// In id, this message translates to:
  /// **'Belum ada transaksi di periode ini'**
  String get historyNoTransactions;

  /// No description provided for @historyTotalIn.
  ///
  /// In id, this message translates to:
  /// **'Pemasukan'**
  String get historyTotalIn;

  /// No description provided for @historyTotalOut.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran'**
  String get historyTotalOut;

  /// No description provided for @historyFilter.
  ///
  /// In id, this message translates to:
  /// **'Filter'**
  String get historyFilter;

  /// No description provided for @historyAllWallets.
  ///
  /// In id, this message translates to:
  /// **'Semua Dompet'**
  String get historyAllWallets;

  /// No description provided for @historySelectWallet.
  ///
  /// In id, this message translates to:
  /// **'Pilih Dompet'**
  String get historySelectWallet;

  /// No description provided for @historyApplyFilter.
  ///
  /// In id, this message translates to:
  /// **'Terapkan Filter'**
  String get historyApplyFilter;

  /// No description provided for @historyResetFilter.
  ///
  /// In id, this message translates to:
  /// **'Reset'**
  String get historyResetFilter;

  /// No description provided for @breakdownTitle.
  ///
  /// In id, this message translates to:
  /// **'Rincian Biaya'**
  String get breakdownTitle;

  /// No description provided for @breakdownVsLastMonth.
  ///
  /// In id, this message translates to:
  /// **'vs Bulan Lalu'**
  String get breakdownVsLastMonth;

  /// No description provided for @breakdownDailyAverage.
  ///
  /// In id, this message translates to:
  /// **'Rata-rata Harian'**
  String get breakdownDailyAverage;

  /// No description provided for @breakdownSubcategories.
  ///
  /// In id, this message translates to:
  /// **'Sub-kategori'**
  String get breakdownSubcategories;

  /// No description provided for @breakdownTransactions.
  ///
  /// In id, this message translates to:
  /// **'Transaksi'**
  String get breakdownTransactions;

  /// No description provided for @breakdownNoData.
  ///
  /// In id, this message translates to:
  /// **'Belum ada data'**
  String get breakdownNoData;

  /// No description provided for @categoryTitle.
  ///
  /// In id, this message translates to:
  /// **'Kategori'**
  String get categoryTitle;

  /// No description provided for @categoryExpense.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran'**
  String get categoryExpense;

  /// No description provided for @categoryIncome.
  ///
  /// In id, this message translates to:
  /// **'Pemasukan'**
  String get categoryIncome;

  /// No description provided for @categoryAdd.
  ///
  /// In id, this message translates to:
  /// **'Tambah Kategori'**
  String get categoryAdd;

  /// No description provided for @categoryEdit.
  ///
  /// In id, this message translates to:
  /// **'Edit Kategori'**
  String get categoryEdit;

  /// No description provided for @categoryDelete.
  ///
  /// In id, this message translates to:
  /// **'Hapus Kategori'**
  String get categoryDelete;

  /// No description provided for @categoryDeleteConfirm.
  ///
  /// In id, this message translates to:
  /// **'Yakin ingin menghapus \"{name}\"? Transaksi yang menggunakan kategori ini tidak akan terpengaruh.'**
  String categoryDeleteConfirm(String name);

  /// No description provided for @categoryDeleteDefault.
  ///
  /// In id, this message translates to:
  /// **'Kategori bawaan tidak bisa dihapus'**
  String get categoryDeleteDefault;

  /// No description provided for @categoryHide.
  ///
  /// In id, this message translates to:
  /// **'Sembunyikan'**
  String get categoryHide;

  /// No description provided for @categoryShow.
  ///
  /// In id, this message translates to:
  /// **'Tampilkan'**
  String get categoryShow;

  /// No description provided for @categoryHidden.
  ///
  /// In id, this message translates to:
  /// **'Tersembunyi'**
  String get categoryHidden;

  /// No description provided for @categoryIconPicker.
  ///
  /// In id, this message translates to:
  /// **'Pilih Icon'**
  String get categoryIconPicker;

  /// No description provided for @categoryColorPicker.
  ///
  /// In id, this message translates to:
  /// **'Pilih Warna'**
  String get categoryColorPicker;

  /// No description provided for @categoryName.
  ///
  /// In id, this message translates to:
  /// **'Nama Kategori'**
  String get categoryName;

  /// No description provided for @categoryNameRequired.
  ///
  /// In id, this message translates to:
  /// **'Nama kategori tidak boleh kosong'**
  String get categoryNameRequired;

  /// No description provided for @categoryParent.
  ///
  /// In id, this message translates to:
  /// **'Kategori Induk'**
  String get categoryParent;

  /// No description provided for @categoryNoParent.
  ///
  /// In id, this message translates to:
  /// **'Tanpa Induk (Parent)'**
  String get categoryNoParent;

  /// No description provided for @categorySave.
  ///
  /// In id, this message translates to:
  /// **'Simpan'**
  String get categorySave;

  /// No description provided for @categorySuccessAdd.
  ///
  /// In id, this message translates to:
  /// **'\"{name}\" berhasil ditambahkan'**
  String categorySuccessAdd(String name);

  /// No description provided for @categorySuccessEdit.
  ///
  /// In id, this message translates to:
  /// **'\"{name}\" berhasil diperbarui'**
  String categorySuccessEdit(String name);

  /// No description provided for @categorySuccessDelete.
  ///
  /// In id, this message translates to:
  /// **'Kategori berhasil dihapus'**
  String get categorySuccessDelete;

  /// No description provided for @categorySuccessHide.
  ///
  /// In id, this message translates to:
  /// **'Kategori disembunyikan'**
  String get categorySuccessHide;

  /// No description provided for @categorySuccessShow.
  ///
  /// In id, this message translates to:
  /// **'Kategori ditampilkan'**
  String get categorySuccessShow;

  /// No description provided for @categoryErrorSave.
  ///
  /// In id, this message translates to:
  /// **'Gagal menyimpan kategori'**
  String get categoryErrorSave;

  /// No description provided for @categoryErrorDelete.
  ///
  /// In id, this message translates to:
  /// **'Gagal menghapus kategori'**
  String get categoryErrorDelete;

  /// No description provided for @categoryEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada kategori'**
  String get categoryEmpty;

  /// No description provided for @categorySearchIcon.
  ///
  /// In id, this message translates to:
  /// **'Cari icon...'**
  String get categorySearchIcon;

  /// No description provided for @categoryChildCount.
  ///
  /// In id, this message translates to:
  /// **'{count} sub-kategori'**
  String categoryChildCount(int count);

  /// No description provided for @voiceListening.
  ///
  /// In id, this message translates to:
  /// **'Sedang mendengarkan...'**
  String get voiceListening;

  /// No description provided for @voiceStop.
  ///
  /// In id, this message translates to:
  /// **'Stop'**
  String get voiceStop;

  /// No description provided for @voiceProcessing.
  ///
  /// In id, this message translates to:
  /// **'Memproses suara...'**
  String get voiceProcessing;

  /// No description provided for @voiceError.
  ///
  /// In id, this message translates to:
  /// **'Gagal mengenali suara, coba lagi'**
  String get voiceError;

  /// No description provided for @voicePermissionDenied.
  ///
  /// In id, this message translates to:
  /// **'Izin mikrofon diperlukan'**
  String get voicePermissionDenied;

  /// No description provided for @voiceCountdown.
  ///
  /// In id, this message translates to:
  /// **'Berhenti dalam {seconds} detik'**
  String voiceCountdown(int seconds);

  /// No description provided for @voicePrefilledBadge.
  ///
  /// In id, this message translates to:
  /// **'Diisi dari suara'**
  String get voicePrefilledBadge;

  /// No description provided for @ocrTitle.
  ///
  /// In id, this message translates to:
  /// **'Scan Struk'**
  String get ocrTitle;

  /// No description provided for @ocrCamera.
  ///
  /// In id, this message translates to:
  /// **'Kamera'**
  String get ocrCamera;

  /// No description provided for @ocrGallery.
  ///
  /// In id, this message translates to:
  /// **'Galeri'**
  String get ocrGallery;

  /// No description provided for @ocrCropInstruction.
  ///
  /// In id, this message translates to:
  /// **'Crop area struk'**
  String get ocrCropInstruction;

  /// No description provided for @ocrScanning.
  ///
  /// In id, this message translates to:
  /// **'Membaca struk...'**
  String get ocrScanning;

  /// No description provided for @ocrResultTitle.
  ///
  /// In id, this message translates to:
  /// **'Hasil Scan'**
  String get ocrResultTitle;

  /// No description provided for @ocrMerchant.
  ///
  /// In id, this message translates to:
  /// **'Merchant'**
  String get ocrMerchant;

  /// No description provided for @ocrGrandTotal.
  ///
  /// In id, this message translates to:
  /// **'Total'**
  String get ocrGrandTotal;

  /// No description provided for @ocrItemCount.
  ///
  /// In id, this message translates to:
  /// **'{count} item terdeteksi'**
  String ocrItemCount(int count);

  /// No description provided for @ocrContinue.
  ///
  /// In id, this message translates to:
  /// **'Lanjutkan'**
  String get ocrContinue;

  /// No description provided for @ocrRescan.
  ///
  /// In id, this message translates to:
  /// **'Scan Ulang'**
  String get ocrRescan;

  /// No description provided for @ocrAutoBalance.
  ///
  /// In id, this message translates to:
  /// **'Selisih ditambahkan otomatis'**
  String get ocrAutoBalance;

  /// No description provided for @ocrNoText.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada teks terdeteksi'**
  String get ocrNoText;

  /// No description provided for @ocrPrefilledBadge.
  ///
  /// In id, this message translates to:
  /// **'Diisi dari scan struk'**
  String get ocrPrefilledBadge;

  /// No description provided for @budgetTitle.
  ///
  /// In id, this message translates to:
  /// **'Anggaran Berjalan'**
  String get budgetTitle;

  /// No description provided for @budgetAdd.
  ///
  /// In id, this message translates to:
  /// **'Membuat Anggaran'**
  String get budgetAdd;

  /// No description provided for @budgetEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada anggaran'**
  String get budgetEmpty;

  /// No description provided for @budgetEmptyHint.
  ///
  /// In id, this message translates to:
  /// **'Mulai pantau pengeluaran dengan membuat anggaran pertama'**
  String get budgetEmptyHint;

  /// No description provided for @budgetActiveBudgets.
  ///
  /// In id, this message translates to:
  /// **'Anggaran Aktif'**
  String get budgetActiveBudgets;

  /// No description provided for @budgetSpendableLabel.
  ///
  /// In id, this message translates to:
  /// **'Jumlah yang dapat Anda belanjakan'**
  String get budgetSpendableLabel;

  /// No description provided for @budgetTotalBudgetLabel.
  ///
  /// In id, this message translates to:
  /// **'Total Anggaran'**
  String get budgetTotalBudgetLabel;

  /// No description provided for @budgetUsed.
  ///
  /// In id, this message translates to:
  /// **'Terpakai'**
  String get budgetUsed;

  /// No description provided for @budgetEndOfMonthLabel.
  ///
  /// In id, this message translates to:
  /// **'Akhir Bulan'**
  String get budgetEndOfMonthLabel;

  /// No description provided for @budgetDaysRemaining.
  ///
  /// In id, this message translates to:
  /// **'{days} hari'**
  String budgetDaysRemaining(int days);

  /// No description provided for @budgetRemaining.
  ///
  /// In id, this message translates to:
  /// **'Sisa {amount}'**
  String budgetRemaining(String amount);

  /// No description provided for @budgetOver.
  ///
  /// In id, this message translates to:
  /// **'Lebih {amount}'**
  String budgetOver(String amount);

  /// No description provided for @budgetToday.
  ///
  /// In id, this message translates to:
  /// **'Hari ini'**
  String get budgetToday;

  /// No description provided for @budgetPeriodTitle.
  ///
  /// In id, this message translates to:
  /// **'Pilih Periode'**
  String get budgetPeriodTitle;

  /// No description provided for @budgetPeriodThisWeek.
  ///
  /// In id, this message translates to:
  /// **'Minggu ini'**
  String get budgetPeriodThisWeek;

  /// No description provided for @budgetPeriodThisMonth.
  ///
  /// In id, this message translates to:
  /// **'Bulan ini'**
  String get budgetPeriodThisMonth;

  /// No description provided for @budgetPeriodThisQuarter.
  ///
  /// In id, this message translates to:
  /// **'Kuartal ini'**
  String get budgetPeriodThisQuarter;

  /// No description provided for @budgetPeriodThisYear.
  ///
  /// In id, this message translates to:
  /// **'Tahun ini'**
  String get budgetPeriodThisYear;

  /// No description provided for @budgetPeriodCustom.
  ///
  /// In id, this message translates to:
  /// **'Kustom'**
  String get budgetPeriodCustom;

  /// No description provided for @budgetAllWallets.
  ///
  /// In id, this message translates to:
  /// **'Semua Dompet'**
  String get budgetAllWallets;

  /// No description provided for @budgetSpecificWallet.
  ///
  /// In id, this message translates to:
  /// **'Dompet Tertentu'**
  String get budgetSpecificWallet;

  /// No description provided for @budgetFormTitleAdd.
  ///
  /// In id, this message translates to:
  /// **'Tambah Anggaran'**
  String get budgetFormTitleAdd;

  /// No description provided for @budgetFormTitleEdit.
  ///
  /// In id, this message translates to:
  /// **'Edit Anggaran'**
  String get budgetFormTitleEdit;

  /// No description provided for @budgetFormCategory.
  ///
  /// In id, this message translates to:
  /// **'Kategori'**
  String get budgetFormCategory;

  /// No description provided for @budgetFormCategorySelect.
  ///
  /// In id, this message translates to:
  /// **'Pilih kategori...'**
  String get budgetFormCategorySelect;

  /// No description provided for @budgetFormCategoryError.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat kategori'**
  String get budgetFormCategoryError;

  /// No description provided for @budgetFormCategoryRequired.
  ///
  /// In id, this message translates to:
  /// **'Pilih kategori terlebih dahulu'**
  String get budgetFormCategoryRequired;

  /// No description provided for @budgetFormAmount.
  ///
  /// In id, this message translates to:
  /// **'Nominal Anggaran'**
  String get budgetFormAmount;

  /// No description provided for @budgetFormAmountRequired.
  ///
  /// In id, this message translates to:
  /// **'Masukkan nominal anggaran'**
  String get budgetFormAmountRequired;

  /// No description provided for @budgetFormAmountInvalid.
  ///
  /// In id, this message translates to:
  /// **'Nominal harus lebih dari 0'**
  String get budgetFormAmountInvalid;

  /// No description provided for @budgetFormPeriod.
  ///
  /// In id, this message translates to:
  /// **'Periode'**
  String get budgetFormPeriod;

  /// No description provided for @budgetFormPeriodSelect.
  ///
  /// In id, this message translates to:
  /// **'Pilih periode...'**
  String get budgetFormPeriodSelect;

  /// No description provided for @budgetFormPeriodRequired.
  ///
  /// In id, this message translates to:
  /// **'Pilih periode terlebih dahulu'**
  String get budgetFormPeriodRequired;

  /// No description provided for @budgetFormWalletScope.
  ///
  /// In id, this message translates to:
  /// **'Berlaku untuk'**
  String get budgetFormWalletScope;

  /// No description provided for @budgetFormRecurringTitle.
  ///
  /// In id, this message translates to:
  /// **'Ulangi anggaran ini'**
  String get budgetFormRecurringTitle;

  /// No description provided for @budgetFormRecurringSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Anggaran otomatis diperpanjang setiap periode berikutnya'**
  String get budgetFormRecurringSubtitle;

  /// No description provided for @budgetSave.
  ///
  /// In id, this message translates to:
  /// **'Simpan'**
  String get budgetSave;

  /// No description provided for @budgetCancel.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get budgetCancel;

  /// No description provided for @budgetSuccessAdd.
  ///
  /// In id, this message translates to:
  /// **'Anggaran berhasil dibuat'**
  String get budgetSuccessAdd;

  /// No description provided for @budgetSuccessEdit.
  ///
  /// In id, this message translates to:
  /// **'Anggaran berhasil diperbarui'**
  String get budgetSuccessEdit;

  /// No description provided for @budgetSuccessDelete.
  ///
  /// In id, this message translates to:
  /// **'Anggaran berhasil dihapus'**
  String get budgetSuccessDelete;

  /// No description provided for @budgetErrorAdd.
  ///
  /// In id, this message translates to:
  /// **'Gagal membuat anggaran'**
  String get budgetErrorAdd;

  /// No description provided for @budgetErrorEdit.
  ///
  /// In id, this message translates to:
  /// **'Gagal memperbarui anggaran'**
  String get budgetErrorEdit;

  /// No description provided for @budgetErrorDelete.
  ///
  /// In id, this message translates to:
  /// **'Gagal menghapus anggaran'**
  String get budgetErrorDelete;

  /// No description provided for @budgetDeleteConfirmTitle.
  ///
  /// In id, this message translates to:
  /// **'Hapus Anggaran?'**
  String get budgetDeleteConfirmTitle;

  /// No description provided for @budgetDeleteConfirmMessage.
  ///
  /// In id, this message translates to:
  /// **'Anggaran untuk \"{name}\" akan dihapus permanen.'**
  String budgetDeleteConfirmMessage(String name);

  /// No description provided for @investmentTitle.
  ///
  /// In id, this message translates to:
  /// **'Investasi'**
  String get investmentTitle;

  /// No description provided for @investmentAdd.
  ///
  /// In id, this message translates to:
  /// **'Tambah Investasi'**
  String get investmentAdd;

  /// No description provided for @investmentEdit.
  ///
  /// In id, this message translates to:
  /// **'Edit Investasi'**
  String get investmentEdit;

  /// No description provided for @investmentDelete.
  ///
  /// In id, this message translates to:
  /// **'Hapus Investasi'**
  String get investmentDelete;

  /// No description provided for @investmentPortfolio.
  ///
  /// In id, this message translates to:
  /// **'Total Portofolio'**
  String get investmentPortfolio;

  /// No description provided for @investmentTotalValue.
  ///
  /// In id, this message translates to:
  /// **'Nilai Saat Ini'**
  String get investmentTotalValue;

  /// No description provided for @investmentTotalPL.
  ///
  /// In id, this message translates to:
  /// **'Total P&L'**
  String get investmentTotalPL;

  /// No description provided for @investmentTypeGold.
  ///
  /// In id, this message translates to:
  /// **'Emas'**
  String get investmentTypeGold;

  /// No description provided for @investmentTypeBtc.
  ///
  /// In id, this message translates to:
  /// **'Bitcoin'**
  String get investmentTypeBtc;

  /// No description provided for @investmentTypeCustom.
  ///
  /// In id, this message translates to:
  /// **'Kustom'**
  String get investmentTypeCustom;

  /// No description provided for @investmentBuyPrice.
  ///
  /// In id, this message translates to:
  /// **'Harga Beli'**
  String get investmentBuyPrice;

  /// No description provided for @investmentCurrentPrice.
  ///
  /// In id, this message translates to:
  /// **'Harga Saat Ini'**
  String get investmentCurrentPrice;

  /// No description provided for @investmentAmount.
  ///
  /// In id, this message translates to:
  /// **'Jumlah'**
  String get investmentAmount;

  /// No description provided for @investmentUnit.
  ///
  /// In id, this message translates to:
  /// **'unit'**
  String get investmentUnit;

  /// No description provided for @investmentEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum Ada Investasi'**
  String get investmentEmptyTitle;

  /// No description provided for @investmentEmptySubtitle.
  ///
  /// In id, this message translates to:
  /// **'Ketuk + untuk menambahkan aset pertama Anda'**
  String get investmentEmptySubtitle;

  /// No description provided for @investmentRefreshPrice.
  ///
  /// In id, this message translates to:
  /// **'Perbarui Harga'**
  String get investmentRefreshPrice;

  /// No description provided for @investmentFormTitleAdd.
  ///
  /// In id, this message translates to:
  /// **'Tambah Investasi'**
  String get investmentFormTitleAdd;

  /// No description provided for @investmentFormTitleEdit.
  ///
  /// In id, this message translates to:
  /// **'Edit Investasi'**
  String get investmentFormTitleEdit;

  /// No description provided for @investmentFormType.
  ///
  /// In id, this message translates to:
  /// **'Tipe Aset'**
  String get investmentFormType;

  /// No description provided for @investmentFormName.
  ///
  /// In id, this message translates to:
  /// **'Nama Aset'**
  String get investmentFormName;

  /// No description provided for @investmentFormNameHint.
  ///
  /// In id, this message translates to:
  /// **'misal: Emas Antam, BTC'**
  String get investmentFormNameHint;

  /// No description provided for @investmentFormNameRequired.
  ///
  /// In id, this message translates to:
  /// **'Nama aset wajib diisi'**
  String get investmentFormNameRequired;

  /// No description provided for @investmentFormAmount.
  ///
  /// In id, this message translates to:
  /// **'Jumlah Unit'**
  String get investmentFormAmount;

  /// No description provided for @investmentFormAmountRequired.
  ///
  /// In id, this message translates to:
  /// **'Jumlah wajib diisi'**
  String get investmentFormAmountRequired;

  /// No description provided for @investmentFormAmountInvalid.
  ///
  /// In id, this message translates to:
  /// **'Jumlah harus lebih dari 0'**
  String get investmentFormAmountInvalid;

  /// No description provided for @investmentFormBuyPrice.
  ///
  /// In id, this message translates to:
  /// **'Harga Beli per Unit (IDR)'**
  String get investmentFormBuyPrice;

  /// No description provided for @investmentFormBuyPriceRequired.
  ///
  /// In id, this message translates to:
  /// **'Harga beli wajib diisi'**
  String get investmentFormBuyPriceRequired;

  /// No description provided for @investmentFormBuyPriceInvalid.
  ///
  /// In id, this message translates to:
  /// **'Harga beli harus lebih dari 0'**
  String get investmentFormBuyPriceInvalid;

  /// No description provided for @investmentFormCurrentPrice.
  ///
  /// In id, this message translates to:
  /// **'Harga Saat Ini (IDR)'**
  String get investmentFormCurrentPrice;

  /// No description provided for @investmentFormCurrentPriceHint.
  ///
  /// In id, this message translates to:
  /// **'Opsional — untuk aset kustom'**
  String get investmentFormCurrentPriceHint;

  /// No description provided for @investmentFormDeductWallet.
  ///
  /// In id, this message translates to:
  /// **'Potong dari Dompet'**
  String get investmentFormDeductWallet;

  /// No description provided for @investmentFormDeductWalletSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Saldo dompet akan dikurangi otomatis'**
  String get investmentFormDeductWalletSubtitle;

  /// No description provided for @investmentFormWallet.
  ///
  /// In id, this message translates to:
  /// **'Pilih Dompet'**
  String get investmentFormWallet;

  /// No description provided for @investmentFormWalletRequired.
  ///
  /// In id, this message translates to:
  /// **'Pilih dompet terlebih dahulu'**
  String get investmentFormWalletRequired;

  /// No description provided for @investmentFormNotes.
  ///
  /// In id, this message translates to:
  /// **'Catatan'**
  String get investmentFormNotes;

  /// No description provided for @investmentFormNotesHint.
  ///
  /// In id, this message translates to:
  /// **'Opsional'**
  String get investmentFormNotesHint;

  /// No description provided for @investmentFormEstimatedCost.
  ///
  /// In id, this message translates to:
  /// **'Estimasi Total Biaya'**
  String get investmentFormEstimatedCost;

  /// No description provided for @investmentSave.
  ///
  /// In id, this message translates to:
  /// **'Simpan Investasi'**
  String get investmentSave;

  /// No description provided for @investmentSuccessAdd.
  ///
  /// In id, this message translates to:
  /// **'Investasi berhasil ditambahkan'**
  String get investmentSuccessAdd;

  /// No description provided for @investmentSuccessEdit.
  ///
  /// In id, this message translates to:
  /// **'Investasi berhasil diperbarui'**
  String get investmentSuccessEdit;

  /// No description provided for @investmentSuccessDelete.
  ///
  /// In id, this message translates to:
  /// **'Investasi berhasil dihapus'**
  String get investmentSuccessDelete;

  /// No description provided for @investmentErrorAdd.
  ///
  /// In id, this message translates to:
  /// **'Gagal menambahkan investasi'**
  String get investmentErrorAdd;

  /// No description provided for @investmentErrorEdit.
  ///
  /// In id, this message translates to:
  /// **'Gagal memperbarui investasi'**
  String get investmentErrorEdit;

  /// No description provided for @investmentErrorDelete.
  ///
  /// In id, this message translates to:
  /// **'Gagal menghapus investasi'**
  String get investmentErrorDelete;

  /// No description provided for @investmentDeleteConfirmTitle.
  ///
  /// In id, this message translates to:
  /// **'Hapus Investasi?'**
  String get investmentDeleteConfirmTitle;

  /// No description provided for @investmentDeleteConfirmMessage.
  ///
  /// In id, this message translates to:
  /// **'Aset \"{name}\" akan dihapus permanen.'**
  String investmentDeleteConfirmMessage(String name);

  /// No description provided for @notifTitle.
  ///
  /// In id, this message translates to:
  /// **'Notifikasi'**
  String get notifTitle;

  /// No description provided for @notifReminderTitle.
  ///
  /// In id, this message translates to:
  /// **'Pengingat Harian'**
  String get notifReminderTitle;

  /// No description provided for @notifReminderSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Ingatkan saya untuk catat transaksi'**
  String get notifReminderSubtitle;

  /// No description provided for @notifReminderTime.
  ///
  /// In id, this message translates to:
  /// **'Jam Pengingat'**
  String get notifReminderTime;

  /// No description provided for @notifBudgetTitle.
  ///
  /// In id, this message translates to:
  /// **'Alert Anggaran'**
  String get notifBudgetTitle;

  /// No description provided for @notifBudgetSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Notifikasi saat anggaran 80% dan 100%'**
  String get notifBudgetSubtitle;

  /// No description provided for @notifDebtTitle.
  ///
  /// In id, this message translates to:
  /// **'Pengingat Piutang'**
  String get notifDebtTitle;

  /// No description provided for @notifDebtSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Ingatkan sebelum jatuh tempo'**
  String get notifDebtSubtitle;

  /// No description provided for @notifDebtDaysBefore.
  ///
  /// In id, this message translates to:
  /// **'Ingatkan {days} hari sebelumnya'**
  String notifDebtDaysBefore(int days);

  /// No description provided for @notifBudgetAlert80.
  ///
  /// In id, this message translates to:
  /// **'Anggaran {category} sudah 80% terpakai!'**
  String notifBudgetAlert80(String category);

  /// No description provided for @notifBudgetAlert100.
  ///
  /// In id, this message translates to:
  /// **'Anggaran {category} sudah habis!'**
  String notifBudgetAlert100(String category);

  /// No description provided for @notifDebtDue.
  ///
  /// In id, this message translates to:
  /// **'Piutang ke {person} jatuh tempo {days} hari lagi'**
  String notifDebtDue(String person, int days);

  /// No description provided for @notifSave.
  ///
  /// In id, this message translates to:
  /// **'Simpan Pengaturan'**
  String get notifSave;

  /// No description provided for @notifSaveSuccess.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan notifikasi berhasil disimpan'**
  String get notifSaveSuccess;

  /// No description provided for @notifSaveError.
  ///
  /// In id, this message translates to:
  /// **'Gagal menyimpan pengaturan notifikasi'**
  String get notifSaveError;

  /// No description provided for @navDashboard.
  ///
  /// In id, this message translates to:
  /// **'Beranda'**
  String get navDashboard;

  /// No description provided for @navHistory.
  ///
  /// In id, this message translates to:
  /// **'Riwayat'**
  String get navHistory;

  /// No description provided for @navBudget.
  ///
  /// In id, this message translates to:
  /// **'Anggaran'**
  String get navBudget;

  /// No description provided for @navInvestment.
  ///
  /// In id, this message translates to:
  /// **'Investasi'**
  String get navInvestment;

  /// No description provided for @profileTitle.
  ///
  /// In id, this message translates to:
  /// **'Profil'**
  String get profileTitle;

  /// No description provided for @profileEditName.
  ///
  /// In id, this message translates to:
  /// **'Ubah Nama'**
  String get profileEditName;

  /// No description provided for @profileEmail.
  ///
  /// In id, this message translates to:
  /// **'Email'**
  String get profileEmail;

  /// No description provided for @profileMemberSince.
  ///
  /// In id, this message translates to:
  /// **'Bergabung sejak'**
  String get profileMemberSince;

  /// No description provided for @profileSettings.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan'**
  String get profileSettings;

  /// No description provided for @profileCategories.
  ///
  /// In id, this message translates to:
  /// **'Kategori'**
  String get profileCategories;

  /// No description provided for @profileWallets.
  ///
  /// In id, this message translates to:
  /// **'Dompet'**
  String get profileWallets;

  /// No description provided for @profileNotifications.
  ///
  /// In id, this message translates to:
  /// **'Notifikasi'**
  String get profileNotifications;

  /// No description provided for @profileLogout.
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get profileLogout;

  /// No description provided for @profileLogoutConfirmTitle.
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get profileLogoutConfirmTitle;

  /// No description provided for @profileLogoutConfirmMessage.
  ///
  /// In id, this message translates to:
  /// **'Apakah Anda yakin ingin keluar?'**
  String get profileLogoutConfirmMessage;

  /// No description provided for @profileDarkMode.
  ///
  /// In id, this message translates to:
  /// **'Mode Gelap'**
  String get profileDarkMode;

  /// No description provided for @profileLanguage.
  ///
  /// In id, this message translates to:
  /// **'Bahasa'**
  String get profileLanguage;

  /// No description provided for @pickerChooseIcon.
  ///
  /// In id, this message translates to:
  /// **'Pilih Ikon'**
  String get pickerChooseIcon;

  /// No description provided for @pickerChooseColor.
  ///
  /// In id, this message translates to:
  /// **'Pilih Warna'**
  String get pickerChooseColor;

  /// No description provided for @pickerSearchCategory.
  ///
  /// In id, this message translates to:
  /// **'Cari kategori...'**
  String get pickerSearchCategory;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
