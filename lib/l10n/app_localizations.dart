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

  /// No description provided for @transactionSaveSuccessBatch.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, one{1 transaksi berhasil disimpan} other{{count} transaksi berhasil disimpan}}'**
  String transactionSaveSuccessBatch(int count);

  /// No description provided for @transactionMultiManualAtLimitBanner.
  ///
  /// In id, this message translates to:
  /// **'Sudah mencapai batas maksimal {max} transaksi per simpanan. Hapus satu untuk menambah lagi.'**
  String transactionMultiManualAtLimitBanner(int max);

  /// No description provided for @transactionMultiManualMaxReached.
  ///
  /// In id, this message translates to:
  /// **'Maksimal {max} transaksi per simpanan. Hapus satu untuk menambah lagi.'**
  String transactionMultiManualMaxReached(int max);

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

  /// No description provided for @contactPickerTitle.
  ///
  /// In id, this message translates to:
  /// **'Pilih Kontak'**
  String get contactPickerTitle;

  /// No description provided for @contactPickerFromPhonebook.
  ///
  /// In id, this message translates to:
  /// **'Dari Kontak HP'**
  String get contactPickerFromPhonebook;

  /// No description provided for @contactPickerSaved.
  ///
  /// In id, this message translates to:
  /// **'Kontak Tersimpan'**
  String get contactPickerSaved;

  /// No description provided for @contactPickerSearch.
  ///
  /// In id, this message translates to:
  /// **'Cari kontak...'**
  String get contactPickerSearch;

  /// No description provided for @contactPickerEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada kontak tersimpan'**
  String get contactPickerEmpty;

  /// No description provided for @contactPickerPhonePermissionDenied.
  ///
  /// In id, this message translates to:
  /// **'Izin akses kontak ditolak'**
  String get contactPickerPhonePermissionDenied;

  /// No description provided for @contactPickerNoPhone.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada nomor HP'**
  String get contactPickerNoPhone;

  /// No description provided for @contactPickerSelected.
  ///
  /// In id, this message translates to:
  /// **'Kontak'**
  String get contactPickerSelected;

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

  /// No description provided for @transactionMultiManualHint.
  ///
  /// In id, this message translates to:
  /// **'Catat beberapa transaksi sekaligus. Masing-masing punya dompet, kategori, detail opsional, dan baris item sendiri. Semua disimpan bersamaan dalam satu langkah.'**
  String get transactionMultiManualHint;

  /// No description provided for @transactionMultiManualSegmentSingle.
  ///
  /// In id, this message translates to:
  /// **'Satu transaksi'**
  String get transactionMultiManualSegmentSingle;

  /// No description provided for @transactionMultiManualSegmentMulti.
  ///
  /// In id, this message translates to:
  /// **'Multi transaksi'**
  String get transactionMultiManualSegmentMulti;

  /// No description provided for @transactionMultiManualAddAnother.
  ///
  /// In id, this message translates to:
  /// **'Tambah transaksi lain'**
  String get transactionMultiManualAddAnother;

  /// No description provided for @transactionMultiManualCardTitle.
  ///
  /// In id, this message translates to:
  /// **'Transaksi {index}'**
  String transactionMultiManualCardTitle(int index);

  /// No description provided for @transactionNewTitle.
  ///
  /// In id, this message translates to:
  /// **'Transaksi Baru'**
  String get transactionNewTitle;

  /// No description provided for @transactionEditTitle.
  ///
  /// In id, this message translates to:
  /// **'Edit Transaksi'**
  String get transactionEditTitle;

  /// No description provided for @transactionSettleDebt.
  ///
  /// In id, this message translates to:
  /// **'Lunasi Hutang'**
  String get transactionSettleDebt;

  /// No description provided for @transactionSettleLoan.
  ///
  /// In id, this message translates to:
  /// **'Tagih Piutang'**
  String get transactionSettleLoan;

  /// No description provided for @transactionSettleAmount.
  ///
  /// In id, this message translates to:
  /// **'Jumlah Pelunasan'**
  String get transactionSettleAmount;

  /// No description provided for @transactionSettleSuccess.
  ///
  /// In id, this message translates to:
  /// **'Pelunasan berhasil disimpan'**
  String get transactionSettleSuccess;

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
  /// **'Ringkasan {period}'**
  String dashboardSnapshotTitle(String period);

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

  /// No description provided for @dashboardGreeting.
  ///
  /// In id, this message translates to:
  /// **'Halo, {name} 👋'**
  String dashboardGreeting(String name);

  /// No description provided for @dashboardEmptyWallets.
  ///
  /// In id, this message translates to:
  /// **'Belum ada dompet'**
  String get dashboardEmptyWallets;

  /// No description provided for @dashboardMonthlyIncome.
  ///
  /// In id, this message translates to:
  /// **'Pemasukan Bulan Ini'**
  String get dashboardMonthlyIncome;

  /// No description provided for @dashboardMonthlyExpense.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran Bulan Ini'**
  String get dashboardMonthlyExpense;

  /// No description provided for @dashboardChartTitle.
  ///
  /// In id, this message translates to:
  /// **'Pemasukan vs Pengeluaran'**
  String get dashboardChartTitle;

  /// No description provided for @dashboardThisMonth.
  ///
  /// In id, this message translates to:
  /// **'Bulan Ini'**
  String get dashboardThisMonth;

  /// No description provided for @dashboardLastMonth.
  ///
  /// In id, this message translates to:
  /// **'Bulan Lalu'**
  String get dashboardLastMonth;

  /// No description provided for @dashboardThisWeek.
  ///
  /// In id, this message translates to:
  /// **'Minggu Ini'**
  String get dashboardThisWeek;

  /// No description provided for @dashboardLastWeek.
  ///
  /// In id, this message translates to:
  /// **'Minggu Lalu'**
  String get dashboardLastWeek;

  /// No description provided for @dashboardMonthlyMode.
  ///
  /// In id, this message translates to:
  /// **'Bulanan'**
  String get dashboardMonthlyMode;

  /// No description provided for @dashboardWeeklyMode.
  ///
  /// In id, this message translates to:
  /// **'Mingguan'**
  String get dashboardWeeklyMode;

  /// No description provided for @dashboardDailyMode.
  ///
  /// In id, this message translates to:
  /// **'Harian'**
  String get dashboardDailyMode;

  /// No description provided for @dashboardToday.
  ///
  /// In id, this message translates to:
  /// **'Hari Ini'**
  String get dashboardToday;

  /// No description provided for @dashboardYesterday.
  ///
  /// In id, this message translates to:
  /// **'Kemarin'**
  String get dashboardYesterday;

  /// No description provided for @dashboardQuickAdd.
  ///
  /// In id, this message translates to:
  /// **'Tambah Cepat'**
  String get dashboardQuickAdd;

  /// No description provided for @dashboardNetFlow.
  ///
  /// In id, this message translates to:
  /// **'Netto'**
  String get dashboardNetFlow;

  /// No description provided for @dashboardNoChange.
  ///
  /// In id, this message translates to:
  /// **'Tidak berubah'**
  String get dashboardNoChange;

  /// No description provided for @dashboardVsPrevious.
  ///
  /// In id, this message translates to:
  /// **'vs {period}'**
  String dashboardVsPrevious(String period);

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

  /// No description provided for @historyDaily.
  ///
  /// In id, this message translates to:
  /// **'Harian'**
  String get historyDaily;

  /// No description provided for @historyWeekly.
  ///
  /// In id, this message translates to:
  /// **'Mingguan'**
  String get historyWeekly;

  /// No description provided for @historyMonthly.
  ///
  /// In id, this message translates to:
  /// **'Bulanan'**
  String get historyMonthly;

  /// No description provided for @historyQuarterly.
  ///
  /// In id, this message translates to:
  /// **'3 Bulanan'**
  String get historyQuarterly;

  /// No description provided for @historyYearly.
  ///
  /// In id, this message translates to:
  /// **'Tahunan'**
  String get historyYearly;

  /// No description provided for @historyCustomRange.
  ///
  /// In id, this message translates to:
  /// **'Kustom'**
  String get historyCustomRange;

  /// No description provided for @historyGroupByDate.
  ///
  /// In id, this message translates to:
  /// **'Berdasarkan Tanggal'**
  String get historyGroupByDate;

  /// No description provided for @historyGroupByCategory.
  ///
  /// In id, this message translates to:
  /// **'Berdasarkan Kategori'**
  String get historyGroupByCategory;

  /// No description provided for @historyAllTypes.
  ///
  /// In id, this message translates to:
  /// **'Semua Tipe'**
  String get historyAllTypes;

  /// No description provided for @historySelectType.
  ///
  /// In id, this message translates to:
  /// **'Tipe Transaksi'**
  String get historySelectType;

  /// No description provided for @historyPeriod.
  ///
  /// In id, this message translates to:
  /// **'Periode'**
  String get historyPeriod;

  /// No description provided for @historyLoadMore.
  ///
  /// In id, this message translates to:
  /// **'Muat lebih banyak'**
  String get historyLoadMore;

  /// No description provided for @historyTransactionCount.
  ///
  /// In id, this message translates to:
  /// **'{count} transaksi'**
  String historyTransactionCount(int count);

  /// No description provided for @historyFilterEmpty.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada transaksi dengan filter ini'**
  String get historyFilterEmpty;

  /// No description provided for @historySearchHint.
  ///
  /// In id, this message translates to:
  /// **'Cari catatan atau kategori...'**
  String get historySearchHint;

  /// No description provided for @historyViewReport.
  ///
  /// In id, this message translates to:
  /// **'Lihat Laporan'**
  String get historyViewReport;

  /// No description provided for @historyDeleteSuccess.
  ///
  /// In id, this message translates to:
  /// **'Transaksi berhasil dihapus'**
  String get historyDeleteSuccess;

  /// No description provided for @historyDeleteConfirm.
  ///
  /// In id, this message translates to:
  /// **'Hapus Transaksi'**
  String get historyDeleteConfirm;

  /// No description provided for @historyDeleteConfirmMessage.
  ///
  /// In id, this message translates to:
  /// **'Yakin ingin menghapus transaksi ini? Saldo dompet akan dikembalikan.'**
  String get historyDeleteConfirmMessage;

  /// No description provided for @historySelectDateRange.
  ///
  /// In id, this message translates to:
  /// **'Pilih Rentang Tanggal'**
  String get historySelectDateRange;

  /// No description provided for @historyStartDate.
  ///
  /// In id, this message translates to:
  /// **'Tanggal Mulai'**
  String get historyStartDate;

  /// No description provided for @historyEndDate.
  ///
  /// In id, this message translates to:
  /// **'Tanggal Akhir'**
  String get historyEndDate;

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

  /// No description provided for @colorPickerPresetTab.
  ///
  /// In id, this message translates to:
  /// **'Preset'**
  String get colorPickerPresetTab;

  /// No description provided for @colorPickerWheelTab.
  ///
  /// In id, this message translates to:
  /// **'Kustom'**
  String get colorPickerWheelTab;

  /// No description provided for @colorPickerSelectButton.
  ///
  /// In id, this message translates to:
  /// **'Pilih Warna Ini'**
  String get colorPickerSelectButton;

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

  /// No description provided for @categorySortNone.
  ///
  /// In id, this message translates to:
  /// **'Tidak Ada'**
  String get categorySortNone;

  /// No description provided for @categorySortNameAZ.
  ///
  /// In id, this message translates to:
  /// **'Nama: A→Z'**
  String get categorySortNameAZ;

  /// No description provided for @categorySortNameZA.
  ///
  /// In id, this message translates to:
  /// **'Nama: Z→A'**
  String get categorySortNameZA;

  /// No description provided for @categorySortNewest.
  ///
  /// In id, this message translates to:
  /// **'Terbaru'**
  String get categorySortNewest;

  /// No description provided for @categorySortOldest.
  ///
  /// In id, this message translates to:
  /// **'Terlama'**
  String get categorySortOldest;

  /// No description provided for @categoryFilterAll.
  ///
  /// In id, this message translates to:
  /// **'Semua'**
  String get categoryFilterAll;

  /// No description provided for @categoryFilterUserCreated.
  ///
  /// In id, this message translates to:
  /// **'Buatan Saya'**
  String get categoryFilterUserCreated;

  /// No description provided for @categoryFilterSystem.
  ///
  /// In id, this message translates to:
  /// **'Dari Sistem'**
  String get categoryFilterSystem;

  /// No description provided for @categoryFilterReset.
  ///
  /// In id, this message translates to:
  /// **'Reset'**
  String get categoryFilterReset;

  /// No description provided for @categoryFilterNoResults.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada kategori yang cocok dengan filter'**
  String get categoryFilterNoResults;

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

  /// No description provided for @budgetEndOfPeriodLabel.
  ///
  /// In id, this message translates to:
  /// **'Akhir Periode'**
  String get budgetEndOfPeriodLabel;

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

  /// No description provided for @budgetFilterAll.
  ///
  /// In id, this message translates to:
  /// **'Semua Dompet'**
  String get budgetFilterAll;

  /// No description provided for @budgetCompletedTitle.
  ///
  /// In id, this message translates to:
  /// **'Anggaran Selesai'**
  String get budgetCompletedTitle;

  /// No description provided for @budgetCompletedEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada anggaran yang selesai'**
  String get budgetCompletedEmpty;

  /// No description provided for @budgetCompleted.
  ///
  /// In id, this message translates to:
  /// **'Selesai'**
  String get budgetCompleted;

  /// No description provided for @budgetDuplicateTitle.
  ///
  /// In id, this message translates to:
  /// **'Anggaran Sudah Ada'**
  String get budgetDuplicateTitle;

  /// No description provided for @budgetDuplicateMessage.
  ///
  /// In id, this message translates to:
  /// **'Sudah ada anggaran aktif untuk kategori \"{category}\" di {wallet}. Ganti dengan yang baru?'**
  String budgetDuplicateMessage(String category, String wallet);

  /// No description provided for @budgetDuplicateReplace.
  ///
  /// In id, this message translates to:
  /// **'Ganti'**
  String get budgetDuplicateReplace;

  /// No description provided for @budgetDuplicateKeep.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get budgetDuplicateKeep;

  /// No description provided for @budgetTabWeekly.
  ///
  /// In id, this message translates to:
  /// **'Mingguan'**
  String get budgetTabWeekly;

  /// No description provided for @budgetTabMonthly.
  ///
  /// In id, this message translates to:
  /// **'Bulanan'**
  String get budgetTabMonthly;

  /// No description provided for @budgetTabQuarterly.
  ///
  /// In id, this message translates to:
  /// **'Kuartalan'**
  String get budgetTabQuarterly;

  /// No description provided for @budgetTabYearly.
  ///
  /// In id, this message translates to:
  /// **'Tahunan'**
  String get budgetTabYearly;

  /// No description provided for @budgetTabCustom.
  ///
  /// In id, this message translates to:
  /// **'Kustom'**
  String get budgetTabCustom;

  /// No description provided for @budgetDetailTitle.
  ///
  /// In id, this message translates to:
  /// **'Detail Anggaran'**
  String get budgetDetailTitle;

  /// No description provided for @budgetDetailSpent.
  ///
  /// In id, this message translates to:
  /// **'Terpakai'**
  String get budgetDetailSpent;

  /// No description provided for @budgetDetailRemaining.
  ///
  /// In id, this message translates to:
  /// **'Sisa'**
  String get budgetDetailRemaining;

  /// No description provided for @budgetDetailPeriod.
  ///
  /// In id, this message translates to:
  /// **'Periode'**
  String get budgetDetailPeriod;

  /// No description provided for @budgetDetailDaysLeft.
  ///
  /// In id, this message translates to:
  /// **'Sisa Hari'**
  String get budgetDetailDaysLeft;

  /// No description provided for @budgetDetailWallet.
  ///
  /// In id, this message translates to:
  /// **'Dompet'**
  String get budgetDetailWallet;

  /// No description provided for @budgetDetailDailyRecommended.
  ///
  /// In id, this message translates to:
  /// **'Rekomendasi Harian'**
  String get budgetDetailDailyRecommended;

  /// No description provided for @budgetDetailProjectedSpend.
  ///
  /// In id, this message translates to:
  /// **'Proyeksi Pengeluaran'**
  String get budgetDetailProjectedSpend;

  /// No description provided for @budgetDetailActualDaily.
  ///
  /// In id, this message translates to:
  /// **'Rata-rata Harian'**
  String get budgetDetailActualDaily;

  /// No description provided for @budgetDetailTransactions.
  ///
  /// In id, this message translates to:
  /// **'Transaksi'**
  String get budgetDetailTransactions;

  /// No description provided for @budgetDetailTransactionsEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada transaksi'**
  String get budgetDetailTransactionsEmpty;

  /// No description provided for @budgetFormCarryForwardTitle.
  ///
  /// In id, this message translates to:
  /// **'Carry Forward'**
  String get budgetFormCarryForwardTitle;

  /// No description provided for @budgetFormCarryForwardSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Bawa sisa anggaran ke periode berikutnya saat diperpanjang'**
  String get budgetFormCarryForwardSubtitle;

  /// No description provided for @budgetFormDiscardTitle.
  ///
  /// In id, this message translates to:
  /// **'Buang Perubahan?'**
  String get budgetFormDiscardTitle;

  /// No description provided for @budgetFormDiscardMessage.
  ///
  /// In id, this message translates to:
  /// **'Kamu punya perubahan yang belum disimpan. Yakin ingin membuangnya?'**
  String get budgetFormDiscardMessage;

  /// No description provided for @budgetFormDiscardConfirm.
  ///
  /// In id, this message translates to:
  /// **'Buang'**
  String get budgetFormDiscardConfirm;

  /// No description provided for @budgetUpcomingBudgets.
  ///
  /// In id, this message translates to:
  /// **'Anggaran Mendatang'**
  String get budgetUpcomingBudgets;

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

  /// No description provided for @notifBudgetAlert50.
  ///
  /// In id, this message translates to:
  /// **'Anggaran {category} sudah 50% terpakai'**
  String notifBudgetAlert50(String category);

  /// No description provided for @notifBudget50Title.
  ///
  /// In id, this message translates to:
  /// **'Alert Anggaran 50%'**
  String get notifBudget50Title;

  /// No description provided for @notifBudget50Subtitle.
  ///
  /// In id, this message translates to:
  /// **'Notif saat anggaran mencapai 50%'**
  String get notifBudget50Subtitle;

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

  /// No description provided for @profileThemeSystem.
  ///
  /// In id, this message translates to:
  /// **'Ikuti Sistem'**
  String get profileThemeSystem;

  /// No description provided for @profileThemeLight.
  ///
  /// In id, this message translates to:
  /// **'Terang'**
  String get profileThemeLight;

  /// No description provided for @profileThemeDark.
  ///
  /// In id, this message translates to:
  /// **'Gelap'**
  String get profileThemeDark;

  /// No description provided for @profileThemeTitle.
  ///
  /// In id, this message translates to:
  /// **'Tema Aplikasi'**
  String get profileThemeTitle;

  /// No description provided for @profileLanguageIndonesian.
  ///
  /// In id, this message translates to:
  /// **'Indonesia'**
  String get profileLanguageIndonesian;

  /// No description provided for @profileLanguageEnglish.
  ///
  /// In id, this message translates to:
  /// **'English'**
  String get profileLanguageEnglish;

  /// No description provided for @profileLanguageTitle.
  ///
  /// In id, this message translates to:
  /// **'Pilih Bahasa'**
  String get profileLanguageTitle;

  /// No description provided for @profileExportImport.
  ///
  /// In id, this message translates to:
  /// **'Export / Import'**
  String get profileExportImport;

  /// No description provided for @profileComingSoon.
  ///
  /// In id, this message translates to:
  /// **'Segera Hadir'**
  String get profileComingSoon;

  /// No description provided for @profileAppVersion.
  ///
  /// In id, this message translates to:
  /// **'Versi Aplikasi'**
  String get profileAppVersion;

  /// No description provided for @profileSectionAccount.
  ///
  /// In id, this message translates to:
  /// **'Akun'**
  String get profileSectionAccount;

  /// No description provided for @profileSectionPreferences.
  ///
  /// In id, this message translates to:
  /// **'Preferensi'**
  String get profileSectionPreferences;

  /// No description provided for @profileSectionData.
  ///
  /// In id, this message translates to:
  /// **'Data'**
  String get profileSectionData;

  /// No description provided for @profileSectionOther.
  ///
  /// In id, this message translates to:
  /// **'Lainnya'**
  String get profileSectionOther;

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

  /// No description provided for @voiceInitializing.
  ///
  /// In id, this message translates to:
  /// **'Mempersiapkan mikrofon...'**
  String get voiceInitializing;

  /// No description provided for @voiceAnalyzingAi.
  ///
  /// In id, this message translates to:
  /// **'Menganalisis dengan AI...'**
  String get voiceAnalyzingAi;

  /// No description provided for @voiceDoneButton.
  ///
  /// In id, this message translates to:
  /// **'Selesai'**
  String get voiceDoneButton;

  /// No description provided for @voicePleaseWait.
  ///
  /// In id, this message translates to:
  /// **'Mohon tunggu...'**
  String get voicePleaseWait;

  /// No description provided for @voiceNoSpeech.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada suara terdeteksi'**
  String get voiceNoSpeech;

  /// No description provided for @voiceOpenSettings.
  ///
  /// In id, this message translates to:
  /// **'Buka Pengaturan'**
  String get voiceOpenSettings;

  /// No description provided for @voicePermissionExplainer.
  ///
  /// In id, this message translates to:
  /// **'Izin mikrofon diperlukan untuk fitur input suara. Silakan aktifkan di pengaturan.'**
  String get voicePermissionExplainer;

  /// No description provided for @voiceParseFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal menganalisis, data dari suara diisi manual'**
  String get voiceParseFailed;

  /// No description provided for @voiceAiBusy.
  ///
  /// In id, this message translates to:
  /// **'AI sedang sibuk, coba lagi nanti'**
  String get voiceAiBusy;

  /// No description provided for @voiceTapToSpeak.
  ///
  /// In id, this message translates to:
  /// **'Tekan & tahan untuk bicara'**
  String get voiceTapToSpeak;

  /// No description provided for @voiceTranscript.
  ///
  /// In id, this message translates to:
  /// **'Teks terdengar'**
  String get voiceTranscript;

  /// No description provided for @voiceNotTransaction.
  ///
  /// In id, this message translates to:
  /// **'Input tidak terdeteksi sebagai transaksi. Coba ucapkan ulang dengan menyebutkan nominal atau jenis transaksi.'**
  String get voiceNotTransaction;

  /// No description provided for @voiceContinueButton.
  ///
  /// In id, this message translates to:
  /// **'Lanjutkan'**
  String get voiceContinueButton;

  /// No description provided for @voiceRetryButton.
  ///
  /// In id, this message translates to:
  /// **'Ulangi'**
  String get voiceRetryButton;

  /// No description provided for @voicePreviewTitle.
  ///
  /// In id, this message translates to:
  /// **'Preview Transaksi'**
  String get voicePreviewTitle;

  /// No description provided for @voicePreviewType.
  ///
  /// In id, this message translates to:
  /// **'Tipe'**
  String get voicePreviewType;

  /// No description provided for @voicePreviewDestWallet.
  ///
  /// In id, this message translates to:
  /// **'Wallet Tujuan'**
  String get voicePreviewDestWallet;

  /// No description provided for @ocrAnalyzingAi.
  ///
  /// In id, this message translates to:
  /// **'Menganalisis dengan AI...'**
  String get ocrAnalyzingAi;

  /// No description provided for @ocrPickerTitle.
  ///
  /// In id, this message translates to:
  /// **'Scan Struk Belanja'**
  String get ocrPickerTitle;

  /// No description provided for @ocrCropToolbar.
  ///
  /// In id, this message translates to:
  /// **'Pilih Area Struk'**
  String get ocrCropToolbar;

  /// No description provided for @ocrErrorGeneric.
  ///
  /// In id, this message translates to:
  /// **'Gagal memproses gambar'**
  String get ocrErrorGeneric;

  /// No description provided for @ocrPermissionDenied.
  ///
  /// In id, this message translates to:
  /// **'Izin kamera ditolak'**
  String get ocrPermissionDenied;

  /// No description provided for @ocrPermissionExplainer.
  ///
  /// In id, this message translates to:
  /// **'Izin kamera diperlukan untuk scan struk. Silakan aktifkan di pengaturan.'**
  String get ocrPermissionExplainer;

  /// No description provided for @ocrAiBusy.
  ///
  /// In id, this message translates to:
  /// **'AI sedang sibuk, coba lagi nanti'**
  String get ocrAiBusy;

  /// No description provided for @ocrPartialResult.
  ///
  /// In id, this message translates to:
  /// **'Sebagian data berhasil dibaca'**
  String get ocrPartialResult;

  /// No description provided for @ocrTotalMismatch.
  ///
  /// In id, this message translates to:
  /// **'Total item ({itemsTotal}) tidak cocok dengan total struk ({receiptTotal})'**
  String ocrTotalMismatch(String itemsTotal, String receiptTotal);

  /// No description provided for @ocrDate.
  ///
  /// In id, this message translates to:
  /// **'Tanggal'**
  String get ocrDate;

  /// No description provided for @ocrItemsSection.
  ///
  /// In id, this message translates to:
  /// **'Daftar Item'**
  String get ocrItemsSection;

  /// No description provided for @ocrProcessing.
  ///
  /// In id, this message translates to:
  /// **'Memproses...'**
  String get ocrProcessing;

  /// No description provided for @ocrImageBlurry.
  ///
  /// In id, this message translates to:
  /// **'Gambar tidak terbaca, coba foto ulang'**
  String get ocrImageBlurry;

  /// No description provided for @ocrNotTransaction.
  ///
  /// In id, this message translates to:
  /// **'Gambar ini bukan dokumen transaksi keuangan. Coba foto struk, bukti transfer, atau nota lainnya.'**
  String get ocrNotTransaction;

  /// No description provided for @ocrTypeExpense.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran'**
  String get ocrTypeExpense;

  /// No description provided for @ocrTypeIncome.
  ///
  /// In id, this message translates to:
  /// **'Pemasukan'**
  String get ocrTypeIncome;

  /// No description provided for @ocrTypeTransfer.
  ///
  /// In id, this message translates to:
  /// **'Transfer'**
  String get ocrTypeTransfer;

  /// No description provided for @ocrTypeDebt.
  ///
  /// In id, this message translates to:
  /// **'Hutang'**
  String get ocrTypeDebt;

  /// No description provided for @ocrTypeLoan.
  ///
  /// In id, this message translates to:
  /// **'Piutang'**
  String get ocrTypeLoan;

  /// No description provided for @ocrSourceWallet.
  ///
  /// In id, this message translates to:
  /// **'Dari'**
  String get ocrSourceWallet;

  /// No description provided for @ocrDestWallet.
  ///
  /// In id, this message translates to:
  /// **'Ke'**
  String get ocrDestWallet;

  /// No description provided for @ocrWithPerson.
  ///
  /// In id, this message translates to:
  /// **'Orang'**
  String get ocrWithPerson;

  /// No description provided for @ocrPaymentMethod.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran'**
  String get ocrPaymentMethod;

  /// No description provided for @ocrUseResult.
  ///
  /// In id, this message translates to:
  /// **'Gunakan Hasil'**
  String get ocrUseResult;

  /// No description provided for @transactionListTitle.
  ///
  /// In id, this message translates to:
  /// **'Transaksi'**
  String get transactionListTitle;

  /// No description provided for @transactionRangeTitle.
  ///
  /// In id, this message translates to:
  /// **'Pilih Rentang Waktu'**
  String get transactionRangeTitle;

  /// No description provided for @transactionRangeHari.
  ///
  /// In id, this message translates to:
  /// **'Hari Ini'**
  String get transactionRangeHari;

  /// No description provided for @transactionRangeMinggu.
  ///
  /// In id, this message translates to:
  /// **'Minggu Ini'**
  String get transactionRangeMinggu;

  /// No description provided for @transactionRangeBulan.
  ///
  /// In id, this message translates to:
  /// **'Bulan Ini'**
  String get transactionRangeBulan;

  /// No description provided for @transactionRangeKuartal.
  ///
  /// In id, this message translates to:
  /// **'Kuartal Ini'**
  String get transactionRangeKuartal;

  /// No description provided for @transactionRangeTahun.
  ///
  /// In id, this message translates to:
  /// **'Tahun Ini'**
  String get transactionRangeTahun;

  /// No description provided for @transactionRangeSemua.
  ///
  /// In id, this message translates to:
  /// **'Semua'**
  String get transactionRangeSemua;

  /// No description provided for @transactionRangeSesuaikan.
  ///
  /// In id, this message translates to:
  /// **'Sesuaikan'**
  String get transactionRangeSesuaikan;

  /// No description provided for @transactionViewByCategory.
  ///
  /// In id, this message translates to:
  /// **'Lihat per Kategori'**
  String get transactionViewByCategory;

  /// No description provided for @transactionViewByTransaction.
  ///
  /// In id, this message translates to:
  /// **'Lihat per Transaksi'**
  String get transactionViewByTransaction;

  /// No description provided for @transactionTransferMoney.
  ///
  /// In id, this message translates to:
  /// **'Transfer Uang'**
  String get transactionTransferMoney;

  /// No description provided for @transactionDetailTitle.
  ///
  /// In id, this message translates to:
  /// **'Detail Transaksi'**
  String get transactionDetailTitle;

  /// No description provided for @transactionDuplicate.
  ///
  /// In id, this message translates to:
  /// **'Duplikasi'**
  String get transactionDuplicate;

  /// No description provided for @transactionShareDetail.
  ///
  /// In id, this message translates to:
  /// **'Bagikan'**
  String get transactionShareDetail;

  /// No description provided for @transactionDeleteSuccess.
  ///
  /// In id, this message translates to:
  /// **'Transaksi berhasil dihapus'**
  String get transactionDeleteSuccess;

  /// No description provided for @transactionItemQty.
  ///
  /// In id, this message translates to:
  /// **'Jumlah'**
  String get transactionItemQty;

  /// No description provided for @transactionItemUnitPrice.
  ///
  /// In id, this message translates to:
  /// **'Harga Satuan'**
  String get transactionItemUnitPrice;

  /// No description provided for @transactionItemSubtotal.
  ///
  /// In id, this message translates to:
  /// **'Subtotal'**
  String get transactionItemSubtotal;

  /// No description provided for @transactionItemName.
  ///
  /// In id, this message translates to:
  /// **'Nama Item'**
  String get transactionItemName;

  /// No description provided for @transactionItemNameHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: Kopi, Nasi Goreng'**
  String get transactionItemNameHint;

  /// No description provided for @transactionTotalMismatch.
  ///
  /// In id, this message translates to:
  /// **'Total item tidak cocok dengan total transaksi'**
  String get transactionTotalMismatch;

  /// No description provided for @transactionReorderHint.
  ///
  /// In id, this message translates to:
  /// **'Geser untuk mengatur urutan'**
  String get transactionReorderHint;

  /// No description provided for @transactionRemoveItem.
  ///
  /// In id, this message translates to:
  /// **'Hapus Item'**
  String get transactionRemoveItem;

  /// No description provided for @transactionItemNote.
  ///
  /// In id, this message translates to:
  /// **'Catatan item'**
  String get transactionItemNote;

  /// No description provided for @dashboardExpenseReport.
  ///
  /// In id, this message translates to:
  /// **'Laporan Pengeluaran'**
  String get dashboardExpenseReport;

  /// No description provided for @dashboardTrendReport.
  ///
  /// In id, this message translates to:
  /// **'Laporan Tren'**
  String get dashboardTrendReport;

  /// No description provided for @dashboardTotalExpenseLabel.
  ///
  /// In id, this message translates to:
  /// **'Total pengeluaran'**
  String get dashboardTotalExpenseLabel;

  /// No description provided for @dashboardTotalIncomeLabel.
  ///
  /// In id, this message translates to:
  /// **'Total pendapatan'**
  String get dashboardTotalIncomeLabel;

  /// No description provided for @dashboardThisMonthCumulative.
  ///
  /// In id, this message translates to:
  /// **'Bulan ini'**
  String get dashboardThisMonthCumulative;

  /// No description provided for @dashboardAvg3MonthLabel.
  ///
  /// In id, this message translates to:
  /// **'Rata-rata 3 bulan lalu'**
  String get dashboardAvg3MonthLabel;

  /// No description provided for @dashboardPrevMonthLabel.
  ///
  /// In id, this message translates to:
  /// **'Bulan lalu'**
  String get dashboardPrevMonthLabel;

  /// No description provided for @dashboardAvg3WeekLabel.
  ///
  /// In id, this message translates to:
  /// **'Rata-rata 3 minggu lalu'**
  String get dashboardAvg3WeekLabel;

  /// No description provided for @dashboardAvg3DayLabel.
  ///
  /// In id, this message translates to:
  /// **'Rata-rata 3 hari lalu'**
  String get dashboardAvg3DayLabel;

  /// No description provided for @dashboardInsightExpenseDown.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaranmu {period} ini {percent}% lebih rendah dari {prevPeriod}. Bagus, terus pertahankan!'**
  String dashboardInsightExpenseDown(
    String period,
    String percent,
    String prevPeriod,
  );

  /// No description provided for @dashboardInsightExpenseUp.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaranmu {period} ini {percent}% lebih tinggi dari {prevPeriod}. Coba kurangi pengeluaran yang tidak perlu.'**
  String dashboardInsightExpenseUp(
    String period,
    String percent,
    String prevPeriod,
  );

  /// No description provided for @dashboardInsightExpenseSame.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaranmu stabil dibandingkan {prevPeriod}.'**
  String dashboardInsightExpenseSame(String prevPeriod);

  /// No description provided for @dashboardInsightTrendBelowAvg.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaranmu di bawah rata-rata 3 bulan. Kamu di jalur yang benar!'**
  String get dashboardInsightTrendBelowAvg;

  /// No description provided for @dashboardInsightTrendAboveAvg.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaranmu di atas rata-rata 3 bulan. Perhatikan pengeluaranmu.'**
  String get dashboardInsightTrendAboveAvg;

  /// No description provided for @dashboardInsightNoData.
  ///
  /// In id, this message translates to:
  /// **'Mulai catat transaksi untuk melihat insight.'**
  String get dashboardInsightNoData;

  /// No description provided for @dashboardLast7Days.
  ///
  /// In id, this message translates to:
  /// **'7 Hari Ini'**
  String get dashboardLast7Days;

  /// No description provided for @dashboardPrev7Days.
  ///
  /// In id, this message translates to:
  /// **'7 Hari Lalu'**
  String get dashboardPrev7Days;

  /// No description provided for @dashboardAvg3x7DaysLabel.
  ///
  /// In id, this message translates to:
  /// **'Rata-rata 3 minggu lalu'**
  String get dashboardAvg3x7DaysLabel;

  /// No description provided for @dashboardInsightTrendProjHigh.
  ///
  /// In id, this message translates to:
  /// **'⚠️ Pengeluaranmu diprediksi mencapai {projected} sampai akhir periode — lebih boros {excess} dari biasanya ({avg}). Coba batasi pengeluaranmu jadi sekitar {dailyCap}/hari agar tetap aman.'**
  String dashboardInsightTrendProjHigh(
    String projected,
    String excess,
    String avg,
    String dailyCap,
  );

  /// No description provided for @dashboardInsightTrendProjMid.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaranmu sedikit lebih tinggi dari biasanya. Diperkirakan {projected}, sedangkan biasanya {avg}. Tetap pantau agar tidak melonjak!'**
  String dashboardInsightTrendProjMid(String projected, String avg);

  /// No description provided for @dashboardInsightTrendProjLow.
  ///
  /// In id, this message translates to:
  /// **'🎉 Pengeluaranmu terkendali! Diperkirakan hanya {projected}, lebih hemat {saving} dari biasanya ({avg}). Selisihnya bisa kamu tabung!'**
  String dashboardInsightTrendProjLow(
    String projected,
    String saving,
    String avg,
  );

  /// No description provided for @dashboardInsightTrendDailyHigh.
  ///
  /// In id, this message translates to:
  /// **'⚠️ Rata-rata pengeluaranmu {burnRate}/hari, lebih tinggi {excess}/hari dari kebiasaanmu ({avg}/hari). Coba perhatikan pengeluaran yang bisa dikurangi.'**
  String dashboardInsightTrendDailyHigh(
    String burnRate,
    String excess,
    String avg,
  );

  /// No description provided for @dashboardInsightTrendDailyMid.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran harianmu sedikit lebih tinggi dari kebiasaanmu ({burnRate}/hari vs {avg}/hari). Tetap pantau ya!'**
  String dashboardInsightTrendDailyMid(String burnRate, String avg);

  /// No description provided for @dashboardInsightTrendDailyLow.
  ///
  /// In id, this message translates to:
  /// **'🎉 Pengeluaranmu lebih hemat dari kebiasaan! Rata-rata {burnRate}/hari, di bawah kebiasaanmu {avg}/hari. Terus pertahankan!'**
  String dashboardInsightTrendDailyLow(String burnRate, String avg);

  /// No description provided for @dashboardInsightTrendNoHistory.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaranmu periode ini: {total}. Terus catat transaksi agar kamu bisa melihat tren dan perbandingan pengeluaranmu.'**
  String dashboardInsightTrendNoHistory(String total);

  /// No description provided for @reportTitle.
  ///
  /// In id, this message translates to:
  /// **'Laporan'**
  String get reportTitle;

  /// No description provided for @reportNet.
  ///
  /// In id, this message translates to:
  /// **'Selisih Bersih'**
  String get reportNet;

  /// No description provided for @reportIncome.
  ///
  /// In id, this message translates to:
  /// **'Pemasukan'**
  String get reportIncome;

  /// No description provided for @reportExpense.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran'**
  String get reportExpense;

  /// No description provided for @reportPeriodWeekly.
  ///
  /// In id, this message translates to:
  /// **'Mingguan'**
  String get reportPeriodWeekly;

  /// No description provided for @reportPeriodMonthly.
  ///
  /// In id, this message translates to:
  /// **'Bulanan'**
  String get reportPeriodMonthly;

  /// No description provided for @reportPeriodQuarterly.
  ///
  /// In id, this message translates to:
  /// **'Kuartal'**
  String get reportPeriodQuarterly;

  /// No description provided for @reportPeriodYearly.
  ///
  /// In id, this message translates to:
  /// **'Tahunan'**
  String get reportPeriodYearly;

  /// No description provided for @reportAllWallets.
  ///
  /// In id, this message translates to:
  /// **'Semua Dompet'**
  String get reportAllWallets;

  /// No description provided for @reportCategoryBreakdown.
  ///
  /// In id, this message translates to:
  /// **'Breakdown Kategori'**
  String get reportCategoryBreakdown;

  /// No description provided for @reportDailyTrend.
  ///
  /// In id, this message translates to:
  /// **'Tren Harian'**
  String get reportDailyTrend;

  /// No description provided for @reportNoCategory.
  ///
  /// In id, this message translates to:
  /// **'Belum ada data kategori.'**
  String get reportNoCategory;

  /// No description provided for @reportNoTrendData.
  ///
  /// In id, this message translates to:
  /// **'Belum ada data tren.'**
  String get reportNoTrendData;

  /// No description provided for @reportEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum Ada Data'**
  String get reportEmptyTitle;

  /// No description provided for @reportEmptyMessage.
  ///
  /// In id, this message translates to:
  /// **'Mulai catat transaksi untuk melihat laporan lengkap.'**
  String get reportEmptyMessage;

  /// No description provided for @reportErrorGeneric.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat laporan. Coba lagi.'**
  String get reportErrorGeneric;

  /// No description provided for @reportInsightExpenseDown.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaranmu turun {percent}% dari periode sebelumnya. Bagus!'**
  String reportInsightExpenseDown(String percent);

  /// No description provided for @reportInsightExpenseUp.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaranmu naik {percent}% dari periode sebelumnya. Perhatikan lebih.'**
  String reportInsightExpenseUp(String percent);

  /// No description provided for @reportInsightStable.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaranmu relatif stabil dibanding periode sebelumnya.'**
  String get reportInsightStable;

  /// No description provided for @reportInsightNoData.
  ///
  /// In id, this message translates to:
  /// **'Mulai catat transaksi untuk melihat insight laporan.'**
  String get reportInsightNoData;

  /// No description provided for @reportSeeFullReport.
  ///
  /// In id, this message translates to:
  /// **'Lihat Laporan Lengkap'**
  String get reportSeeFullReport;

  /// No description provided for @thisQuarter.
  ///
  /// In id, this message translates to:
  /// **'Kuartal Ini'**
  String get thisQuarter;

  /// No description provided for @transactionDeleteConfirmTitle.
  ///
  /// In id, this message translates to:
  /// **'Hapus Transaksi?'**
  String get transactionDeleteConfirmTitle;

  /// No description provided for @transactionDeleteConfirmMessage.
  ///
  /// In id, this message translates to:
  /// **'Transaksi ini akan dihapus permanen dan saldo dompet akan disesuaikan.'**
  String get transactionDeleteConfirmMessage;

  /// No description provided for @transactionTransferToAsset.
  ///
  /// In id, this message translates to:
  /// **'Transfer ke Aset'**
  String get transactionTransferToAsset;

  /// No description provided for @transactionItemCount.
  ///
  /// In id, this message translates to:
  /// **'{count} item'**
  String transactionItemCount(int count);

  /// No description provided for @reportOthersCategory.
  ///
  /// In id, this message translates to:
  /// **'Lainnya'**
  String get reportOthersCategory;

  /// No description provided for @reportTransactionCountLabel.
  ///
  /// In id, this message translates to:
  /// **'transaksi'**
  String get reportTransactionCountLabel;

  /// No description provided for @ocrBalanceItem.
  ///
  /// In id, this message translates to:
  /// **'Item lainnya'**
  String get ocrBalanceItem;

  /// No description provided for @ocrDiscountItem.
  ///
  /// In id, this message translates to:
  /// **'Diskon/potongan'**
  String get ocrDiscountItem;

  /// No description provided for @validationAmountPositive.
  ///
  /// In id, this message translates to:
  /// **'Nominal harus lebih dari 0'**
  String get validationAmountPositive;

  /// No description provided for @validationTransferNeedsDest.
  ///
  /// In id, this message translates to:
  /// **'Transfer memerlukan dompet tujuan'**
  String get validationTransferNeedsDest;

  /// No description provided for @validationMinOneItem.
  ///
  /// In id, this message translates to:
  /// **'Transaksi harus memiliki minimal 1 item'**
  String get validationMinOneItem;

  /// No description provided for @validationItemsTotalMismatch.
  ///
  /// In id, this message translates to:
  /// **'Total item ({itemsSum}) tidak sama dengan total transaksi ({totalAmount})'**
  String validationItemsTotalMismatch(String itemsSum, String totalAmount);

  /// No description provided for @validationCategoryRequired.
  ///
  /// In id, this message translates to:
  /// **'Kategori wajib dipilih untuk setiap item'**
  String get validationCategoryRequired;

  /// No description provided for @validationBudgetAmountPositive.
  ///
  /// In id, this message translates to:
  /// **'Nominal anggaran harus lebih dari 0'**
  String get validationBudgetAmountPositive;

  /// No description provided for @validationEndBeforeStart.
  ///
  /// In id, this message translates to:
  /// **'Tanggal akhir tidak boleh sebelum tanggal mulai'**
  String get validationEndBeforeStart;

  /// No description provided for @validationBudgetDuplicate.
  ///
  /// In id, this message translates to:
  /// **'Sudah ada anggaran aktif untuk kategori dan periode yang sama'**
  String get validationBudgetDuplicate;

  /// No description provided for @validationDeleteOldBudgetFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal menghapus anggaran lama'**
  String get validationDeleteOldBudgetFailed;

  /// No description provided for @validationWalletNameEmpty.
  ///
  /// In id, this message translates to:
  /// **'Nama dompet tidak boleh kosong'**
  String get validationWalletNameEmpty;

  /// No description provided for @validationInitialBalanceNegative.
  ///
  /// In id, this message translates to:
  /// **'Saldo awal tidak boleh negatif'**
  String get validationInitialBalanceNegative;

  /// No description provided for @validationWalletNameDuplicate.
  ///
  /// In id, this message translates to:
  /// **'Nama dompet sudah digunakan'**
  String get validationWalletNameDuplicate;

  /// No description provided for @validationWalletHasTransactions.
  ///
  /// In id, this message translates to:
  /// **'Dompet tidak bisa dihapus karena masih memiliki transaksi. Hapus transaksi terlebih dahulu.'**
  String get validationWalletHasTransactions;

  /// No description provided for @debtLoanTitle.
  ///
  /// In id, this message translates to:
  /// **'Hutang & Piutang'**
  String get debtLoanTitle;

  /// No description provided for @debtLoanTabToPay.
  ///
  /// In id, this message translates to:
  /// **'Untuk Dibayar'**
  String get debtLoanTabToPay;

  /// No description provided for @debtLoanTabToReceive.
  ///
  /// In id, this message translates to:
  /// **'Untuk Diterima'**
  String get debtLoanTabToReceive;

  /// No description provided for @debtLoanUnpaid.
  ///
  /// In id, this message translates to:
  /// **'BELUM LUNAS'**
  String get debtLoanUnpaid;

  /// No description provided for @debtLoanPaid.
  ///
  /// In id, this message translates to:
  /// **'LUNAS'**
  String get debtLoanPaid;

  /// No description provided for @debtLoanAllWallets.
  ///
  /// In id, this message translates to:
  /// **'Semua Dompet'**
  String get debtLoanAllWallets;

  /// No description provided for @debtLoanTransactionCount.
  ///
  /// In id, this message translates to:
  /// **'{count} transaksi'**
  String debtLoanTransactionCount(int count);

  /// No description provided for @debtLoanRemaining.
  ///
  /// In id, this message translates to:
  /// **'tersisa'**
  String get debtLoanRemaining;

  /// No description provided for @debtLoanSettled.
  ///
  /// In id, this message translates to:
  /// **'terlunasi'**
  String get debtLoanSettled;

  /// No description provided for @debtLoanPersonTitle.
  ///
  /// In id, this message translates to:
  /// **'Daftar Transaksi'**
  String get debtLoanPersonTitle;

  /// No description provided for @debtLoanPersonResult.
  ///
  /// In id, this message translates to:
  /// **'{count} hasil'**
  String debtLoanPersonResult(int count);

  /// No description provided for @debtLoanPersonIncome.
  ///
  /// In id, this message translates to:
  /// **'Pemasukan'**
  String get debtLoanPersonIncome;

  /// No description provided for @debtLoanPersonExpense.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran'**
  String get debtLoanPersonExpense;

  /// No description provided for @debtLoanSettlementTitle.
  ///
  /// In id, this message translates to:
  /// **'Pelunasan'**
  String get debtLoanSettlementTitle;

  /// No description provided for @debtLoanSettlementAmount.
  ///
  /// In id, this message translates to:
  /// **'Jumlah Pelunasan'**
  String get debtLoanSettlementAmount;

  /// No description provided for @debtLoanSettlementWallet.
  ///
  /// In id, this message translates to:
  /// **'Dompet Pembayaran'**
  String get debtLoanSettlementWallet;

  /// No description provided for @debtLoanSettlementNote.
  ///
  /// In id, this message translates to:
  /// **'Catatan (opsional)'**
  String get debtLoanSettlementNote;

  /// No description provided for @debtLoanSettlementSubmit.
  ///
  /// In id, this message translates to:
  /// **'Simpan Pelunasan'**
  String get debtLoanSettlementSubmit;

  /// No description provided for @debtLoanSettlementSuccess.
  ///
  /// In id, this message translates to:
  /// **'Pelunasan berhasil disimpan'**
  String get debtLoanSettlementSuccess;

  /// No description provided for @debtLoanSettlementRemainder.
  ///
  /// In id, this message translates to:
  /// **'Sisa: {amount}'**
  String debtLoanSettlementRemainder(String amount);

  /// No description provided for @debtLoanPayDebt.
  ///
  /// In id, this message translates to:
  /// **'Lunasi Hutang'**
  String get debtLoanPayDebt;

  /// No description provided for @debtLoanCollectLoan.
  ///
  /// In id, this message translates to:
  /// **'Terima Pembayaran'**
  String get debtLoanCollectLoan;

  /// No description provided for @debtLoanSettlementHistory.
  ///
  /// In id, this message translates to:
  /// **'DAFTAR TRANSAKSI'**
  String get debtLoanSettlementHistory;

  /// No description provided for @debtLoanLender.
  ///
  /// In id, this message translates to:
  /// **'Pemberi Pinjaman'**
  String get debtLoanLender;

  /// No description provided for @debtLoanBorrower.
  ///
  /// In id, this message translates to:
  /// **'Peminjam'**
  String get debtLoanBorrower;

  /// No description provided for @debtLoanStatusPaid.
  ///
  /// In id, this message translates to:
  /// **'Lunas'**
  String get debtLoanStatusPaid;

  /// No description provided for @debtLoanStatusRemaining.
  ///
  /// In id, this message translates to:
  /// **'Tersisa'**
  String get debtLoanStatusRemaining;

  /// No description provided for @debtLoanDebtPaymentDesc.
  ///
  /// In id, this message translates to:
  /// **'Hutang dibayar ke {person}'**
  String debtLoanDebtPaymentDesc(String person);

  /// No description provided for @debtLoanLoanCollectionDesc.
  ///
  /// In id, this message translates to:
  /// **'Piutang diterima dari {person}'**
  String debtLoanLoanCollectionDesc(String person);

  /// No description provided for @debtLoanRepayment.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran kembali'**
  String get debtLoanRepayment;

  /// No description provided for @debtLoanCollection.
  ///
  /// In id, this message translates to:
  /// **'Penerimaan'**
  String get debtLoanCollection;

  /// No description provided for @debtLoanEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada catatan hutang atau piutang'**
  String get debtLoanEmpty;

  /// No description provided for @debtLoanEmptyPerson.
  ///
  /// In id, this message translates to:
  /// **'Belum ada transaksi'**
  String get debtLoanEmptyPerson;

  /// No description provided for @debtLoanSomeone.
  ///
  /// In id, this message translates to:
  /// **'Seseorang'**
  String get debtLoanSomeone;

  /// No description provided for @debtLoanExcludedFromReport.
  ///
  /// In id, this message translates to:
  /// **'Transaksi ini dikecualikan dari laporan'**
  String get debtLoanExcludedFromReport;

  /// No description provided for @debtLoanSettlementHistoryTitle.
  ///
  /// In id, this message translates to:
  /// **'Riwayat Pelunasan'**
  String get debtLoanSettlementHistoryTitle;

  /// No description provided for @debtLoanTitleDebt.
  ///
  /// In id, this message translates to:
  /// **'Hutang ke {person}'**
  String debtLoanTitleDebt(String person);

  /// No description provided for @debtLoanTitleLoan.
  ///
  /// In id, this message translates to:
  /// **'Piutang ke {person}'**
  String debtLoanTitleLoan(String person);

  /// No description provided for @debtLoanTitlePayment.
  ///
  /// In id, this message translates to:
  /// **'Pelunasan ke {person}'**
  String debtLoanTitlePayment(String person);

  /// No description provided for @debtLoanTitleReceipt.
  ///
  /// In id, this message translates to:
  /// **'Penerimaan dari {person}'**
  String debtLoanTitleReceipt(String person);

  /// No description provided for @profileDebtLoan.
  ///
  /// In id, this message translates to:
  /// **'Hutang & Piutang'**
  String get profileDebtLoan;

  /// No description provided for @debtLoanFormSubCategory.
  ///
  /// In id, this message translates to:
  /// **'Kategori'**
  String get debtLoanFormSubCategory;

  /// No description provided for @debtLoanFormPickTransaction.
  ///
  /// In id, this message translates to:
  /// **'Pilih Transaksi'**
  String get debtLoanFormPickTransaction;

  /// No description provided for @debtLoanFormNoUnpaidDebt.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada hutang yang belum lunas'**
  String get debtLoanFormNoUnpaidDebt;

  /// No description provided for @debtLoanFormNoUnpaidLoan.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada piutang yang belum lunas'**
  String get debtLoanFormNoUnpaidLoan;

  /// No description provided for @debtLoanFormAmountExceedsRemaining.
  ///
  /// In id, this message translates to:
  /// **'Nominal melebihi sisa {amount}'**
  String debtLoanFormAmountExceedsRemaining(String amount);

  /// No description provided for @debtLoanFormTabLabel.
  ///
  /// In id, this message translates to:
  /// **'Hutang/Piutang'**
  String get debtLoanFormTabLabel;

  /// No description provided for @debtLoanFormSelectedTransaction.
  ///
  /// In id, this message translates to:
  /// **'Transaksi Terpilih'**
  String get debtLoanFormSelectedTransaction;

  /// No description provided for @debtLoanFormRemainingAmount.
  ///
  /// In id, this message translates to:
  /// **'Sisa: {amount}'**
  String debtLoanFormRemainingAmount(String amount);

  /// No description provided for @debtLoanSettlementEditTitle.
  ///
  /// In id, this message translates to:
  /// **'Edit Pelunasan'**
  String get debtLoanSettlementEditTitle;

  /// No description provided for @debtLoanSettlementEditSuccess.
  ///
  /// In id, this message translates to:
  /// **'Pelunasan berhasil diperbarui'**
  String get debtLoanSettlementEditSuccess;

  /// No description provided for @debtLoanSettlementDeleteConfirm.
  ///
  /// In id, this message translates to:
  /// **'Hapus pelunasan ini?'**
  String get debtLoanSettlementDeleteConfirm;

  /// No description provided for @debtLoanSettlementDeleteMessage.
  ///
  /// In id, this message translates to:
  /// **'Saldo dompet akan dikembalikan dan status hutang/piutang akan dihitung ulang.'**
  String get debtLoanSettlementDeleteMessage;

  /// No description provided for @debtLoanSettlementDeleteSuccess.
  ///
  /// In id, this message translates to:
  /// **'Pelunasan berhasil dihapus'**
  String get debtLoanSettlementDeleteSuccess;

  /// No description provided for @debtLoanSettlementMaxAmount.
  ///
  /// In id, this message translates to:
  /// **'Maks: {amount}'**
  String debtLoanSettlementMaxAmount(String amount);

  /// No description provided for @fabTextInput.
  ///
  /// In id, this message translates to:
  /// **'Input Teks'**
  String get fabTextInput;

  /// No description provided for @textInputTitle.
  ///
  /// In id, this message translates to:
  /// **'Input via Teks'**
  String get textInputTitle;

  /// No description provided for @textInputHint.
  ///
  /// In id, this message translates to:
  /// **'cth. Makan siang di warteg 15rb'**
  String get textInputHint;

  /// No description provided for @textInputSubmit.
  ///
  /// In id, this message translates to:
  /// **'Analisis'**
  String get textInputSubmit;

  /// No description provided for @textInputAnalyzing.
  ///
  /// In id, this message translates to:
  /// **'Menganalisis dengan AI...'**
  String get textInputAnalyzing;

  /// No description provided for @textInputError.
  ///
  /// In id, this message translates to:
  /// **'Gagal menganalisis teks'**
  String get textInputError;

  /// No description provided for @textInputEmpty.
  ///
  /// In id, this message translates to:
  /// **'Silakan masukkan deskripsi transaksi'**
  String get textInputEmpty;

  /// No description provided for @aiParseCancelTitle.
  ///
  /// In id, this message translates to:
  /// **'Batalkan Analisis?'**
  String get aiParseCancelTitle;

  /// No description provided for @aiParseCancelMessage.
  ///
  /// In id, this message translates to:
  /// **'AI sedang menganalisis data. Yakin ingin membatalkan?'**
  String get aiParseCancelMessage;

  /// No description provided for @aiParseCancelConfirm.
  ///
  /// In id, this message translates to:
  /// **'Ya, Batalkan'**
  String get aiParseCancelConfirm;

  /// No description provided for @aiPreviewDiscardTitle.
  ///
  /// In id, this message translates to:
  /// **'Buang Hasil?'**
  String get aiPreviewDiscardTitle;

  /// No description provided for @aiPreviewDiscardMessage.
  ///
  /// In id, this message translates to:
  /// **'Hasil analisa AI akan dibuang. Kamu harus memulai ulang untuk mendapatkan hasil baru.'**
  String get aiPreviewDiscardMessage;

  /// No description provided for @aiPreviewDiscardConfirm.
  ///
  /// In id, this message translates to:
  /// **'Ya, Buang'**
  String get aiPreviewDiscardConfirm;

  /// No description provided for @aiPreviewItemsHeader.
  ///
  /// In id, this message translates to:
  /// **'{count} item terdeteksi'**
  String aiPreviewItemsHeader(int count);

  /// No description provided for @aiPreviewGrandTotal.
  ///
  /// In id, this message translates to:
  /// **'Total'**
  String get aiPreviewGrandTotal;

  /// No description provided for @aiPreviewTotalMismatch.
  ///
  /// In id, this message translates to:
  /// **'Total item ({itemsTotal}) tidak cocok dengan total ({grandTotal})'**
  String aiPreviewTotalMismatch(String itemsTotal, String grandTotal);

  /// No description provided for @aiPreviewMultiTitle.
  ///
  /// In id, this message translates to:
  /// **'Beberapa transaksi'**
  String get aiPreviewMultiTitle;

  /// No description provided for @aiPreviewMultiSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Akan dibuka dalam mode multi transaksi. Periksa tiap baris sebelum menyimpan.'**
  String get aiPreviewMultiSubtitle;

  /// No description provided for @aiPreviewMultiOcrAttachmentHint.
  ///
  /// In id, this message translates to:
  /// **'Foto struk dilampirkan ke transaksi pertama; kamu bisa memindahkannya jika perlu.'**
  String get aiPreviewMultiOcrAttachmentHint;

  /// No description provided for @aiPreviewMultiCombinedTotal.
  ///
  /// In id, this message translates to:
  /// **'Total gabungan'**
  String get aiPreviewMultiCombinedTotal;

  /// No description provided for @aiPreviewMultiTransactionN.
  ///
  /// In id, this message translates to:
  /// **'Transaksi {n}'**
  String aiPreviewMultiTransactionN(int n);

  /// No description provided for @navInvestment.
  ///
  /// In id, this message translates to:
  /// **'Investasi'**
  String get navInvestment;

  /// No description provided for @navSettings.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan'**
  String get navSettings;

  /// No description provided for @investmentTitle.
  ///
  /// In id, this message translates to:
  /// **'Portofolio Investasi'**
  String get investmentTitle;

  /// No description provided for @investmentTotalValue.
  ///
  /// In id, this message translates to:
  /// **'Total Nilai Portofolio'**
  String get investmentTotalValue;

  /// No description provided for @investmentTotalInvested.
  ///
  /// In id, this message translates to:
  /// **'Total Modal'**
  String get investmentTotalInvested;

  /// No description provided for @investmentProfitLoss.
  ///
  /// In id, this message translates to:
  /// **'Keuntungan/Kerugian'**
  String get investmentProfitLoss;

  /// No description provided for @investmentProfit.
  ///
  /// In id, this message translates to:
  /// **'Untung'**
  String get investmentProfit;

  /// No description provided for @investmentLoss.
  ///
  /// In id, this message translates to:
  /// **'Rugi'**
  String get investmentLoss;

  /// No description provided for @investmentEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada investasi'**
  String get investmentEmpty;

  /// No description provided for @investmentEmptyHint.
  ///
  /// In id, this message translates to:
  /// **'Tap + untuk mulai catat investasi pertamamu'**
  String get investmentEmptyHint;

  /// No description provided for @investmentAddAsset.
  ///
  /// In id, this message translates to:
  /// **'Tambah Investasi'**
  String get investmentAddAsset;

  /// No description provided for @investmentActiveAssets.
  ///
  /// In id, this message translates to:
  /// **'Aset Aktif'**
  String get investmentActiveAssets;

  /// No description provided for @investmentInactiveAssets.
  ///
  /// In id, this message translates to:
  /// **'Aset Tidak Aktif'**
  String get investmentInactiveAssets;

  /// No description provided for @investmentViewInactive.
  ///
  /// In id, this message translates to:
  /// **'Lihat Aset Tidak Aktif'**
  String get investmentViewInactive;

  /// No description provided for @investmentSectionGold.
  ///
  /// In id, this message translates to:
  /// **'Emas'**
  String get investmentSectionGold;

  /// No description provided for @investmentSectionBitcoin.
  ///
  /// In id, this message translates to:
  /// **'Bitcoin'**
  String get investmentSectionBitcoin;

  /// No description provided for @investmentSectionCustom.
  ///
  /// In id, this message translates to:
  /// **'Aset Kustom'**
  String get investmentSectionCustom;

  /// No description provided for @investmentTypeGold.
  ///
  /// In id, this message translates to:
  /// **'Emas'**
  String get investmentTypeGold;

  /// No description provided for @investmentTypeBitcoin.
  ///
  /// In id, this message translates to:
  /// **'Bitcoin'**
  String get investmentTypeBitcoin;

  /// No description provided for @investmentTypeCustom.
  ///
  /// In id, this message translates to:
  /// **'Kustom'**
  String get investmentTypeCustom;

  /// No description provided for @investmentDetailTitle.
  ///
  /// In id, this message translates to:
  /// **'Detail Investasi'**
  String get investmentDetailTitle;

  /// No description provided for @investmentDetailCurrentPrice.
  ///
  /// In id, this message translates to:
  /// **'Harga Saat Ini'**
  String get investmentDetailCurrentPrice;

  /// No description provided for @investmentDetailAvgBuyPrice.
  ///
  /// In id, this message translates to:
  /// **'Rata-rata Harga Beli'**
  String get investmentDetailAvgBuyPrice;

  /// No description provided for @investmentDetailTotalUnits.
  ///
  /// In id, this message translates to:
  /// **'Total Unit'**
  String get investmentDetailTotalUnits;

  /// No description provided for @investmentDetailTotalInvested.
  ///
  /// In id, this message translates to:
  /// **'Total Modal'**
  String get investmentDetailTotalInvested;

  /// No description provided for @investmentDetailCurrentValue.
  ///
  /// In id, this message translates to:
  /// **'Nilai Saat Ini'**
  String get investmentDetailCurrentValue;

  /// No description provided for @investmentDetailProfitLoss.
  ///
  /// In id, this message translates to:
  /// **'Keuntungan/Kerugian'**
  String get investmentDetailProfitLoss;

  /// No description provided for @investmentDetailTotalFee.
  ///
  /// In id, this message translates to:
  /// **'Total Biaya'**
  String get investmentDetailTotalFee;

  /// No description provided for @investmentPriceLastUpdated.
  ///
  /// In id, this message translates to:
  /// **'Terakhir diperbarui'**
  String get investmentPriceLastUpdated;

  /// No description provided for @investmentDetailTransactions.
  ///
  /// In id, this message translates to:
  /// **'Riwayat Transaksi'**
  String get investmentDetailTransactions;

  /// No description provided for @investmentDetailBuyHistory.
  ///
  /// In id, this message translates to:
  /// **'Riwayat Beli'**
  String get investmentDetailBuyHistory;

  /// No description provided for @investmentDetailSellHistory.
  ///
  /// In id, this message translates to:
  /// **'Riwayat Jual'**
  String get investmentDetailSellHistory;

  /// No description provided for @investmentDetailNoTransactions.
  ///
  /// In id, this message translates to:
  /// **'Belum ada transaksi'**
  String get investmentDetailNoTransactions;

  /// No description provided for @investmentDetailTopUp.
  ///
  /// In id, this message translates to:
  /// **'Top Up'**
  String get investmentDetailTopUp;

  /// No description provided for @investmentDetailSell.
  ///
  /// In id, this message translates to:
  /// **'Jual'**
  String get investmentDetailSell;

  /// No description provided for @investmentDetailSettings.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan'**
  String get investmentDetailSettings;

  /// No description provided for @investmentFormCreateTitle.
  ///
  /// In id, this message translates to:
  /// **'Investasi Baru'**
  String get investmentFormCreateTitle;

  /// No description provided for @investmentFormTopUpTitle.
  ///
  /// In id, this message translates to:
  /// **'Top Up Investasi'**
  String get investmentFormTopUpTitle;

  /// No description provided for @investmentFormEditTitle.
  ///
  /// In id, this message translates to:
  /// **'Edit Transaksi'**
  String get investmentFormEditTitle;

  /// No description provided for @investmentFormAssetName.
  ///
  /// In id, this message translates to:
  /// **'Nama Aset'**
  String get investmentFormAssetName;

  /// No description provided for @investmentFormAssetNameHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: Emas Antam, Bitcoin, Saham BBCA'**
  String get investmentFormAssetNameHint;

  /// No description provided for @investmentFormAssetNameRequired.
  ///
  /// In id, this message translates to:
  /// **'Nama aset tidak boleh kosong'**
  String get investmentFormAssetNameRequired;

  /// No description provided for @investmentFormType.
  ///
  /// In id, this message translates to:
  /// **'Jenis Aset'**
  String get investmentFormType;

  /// No description provided for @investmentFormGoldType.
  ///
  /// In id, this message translates to:
  /// **'Jenis Emas'**
  String get investmentFormGoldType;

  /// No description provided for @investmentFormGoldTypeHint.
  ///
  /// In id, this message translates to:
  /// **'Pilih jenis emas'**
  String get investmentFormGoldTypeHint;

  /// No description provided for @investmentFormCustomCategory.
  ///
  /// In id, this message translates to:
  /// **'Kategori Aset'**
  String get investmentFormCustomCategory;

  /// No description provided for @investmentFormCustomCategoryHint.
  ///
  /// In id, this message translates to:
  /// **'Pilih kategori'**
  String get investmentFormCustomCategoryHint;

  /// No description provided for @investmentFormUnits.
  ///
  /// In id, this message translates to:
  /// **'Jumlah Unit'**
  String get investmentFormUnits;

  /// No description provided for @investmentFormUnitsHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: 1.5'**
  String get investmentFormUnitsHint;

  /// No description provided for @investmentFormUnitsRequired.
  ///
  /// In id, this message translates to:
  /// **'Jumlah unit tidak boleh kosong'**
  String get investmentFormUnitsRequired;

  /// No description provided for @investmentFormPricePerUnit.
  ///
  /// In id, this message translates to:
  /// **'Harga per Unit'**
  String get investmentFormPricePerUnit;

  /// No description provided for @investmentFormPricePerUnitRequired.
  ///
  /// In id, this message translates to:
  /// **'Harga per unit tidak boleh kosong'**
  String get investmentFormPricePerUnitRequired;

  /// No description provided for @investmentFormFee.
  ///
  /// In id, this message translates to:
  /// **'Biaya (opsional)'**
  String get investmentFormFee;

  /// No description provided for @investmentFormFeeHint.
  ///
  /// In id, this message translates to:
  /// **'Biaya admin/spread'**
  String get investmentFormFeeHint;

  /// No description provided for @investmentFormDate.
  ///
  /// In id, this message translates to:
  /// **'Tanggal Transaksi'**
  String get investmentFormDate;

  /// No description provided for @investmentFormNote.
  ///
  /// In id, this message translates to:
  /// **'Catatan (opsional)'**
  String get investmentFormNote;

  /// No description provided for @investmentFormDeductWallet.
  ///
  /// In id, this message translates to:
  /// **'Potong Saldo Dompet'**
  String get investmentFormDeductWallet;

  /// No description provided for @investmentFormDeductWalletHint.
  ///
  /// In id, this message translates to:
  /// **'Kurangi saldo dompet sesuai total pembelian'**
  String get investmentFormDeductWalletHint;

  /// No description provided for @investmentFormSelectWallet.
  ///
  /// In id, this message translates to:
  /// **'Pilih Dompet'**
  String get investmentFormSelectWallet;

  /// No description provided for @investmentFormWalletRequired.
  ///
  /// In id, this message translates to:
  /// **'Pilih dompet terlebih dahulu'**
  String get investmentFormWalletRequired;

  /// No description provided for @investmentFormSave.
  ///
  /// In id, this message translates to:
  /// **'Simpan'**
  String get investmentFormSave;

  /// No description provided for @investmentFormTotalCost.
  ///
  /// In id, this message translates to:
  /// **'Total Biaya Pembelian'**
  String get investmentFormTotalCost;

  /// No description provided for @investmentFormCurrentPrice.
  ///
  /// In id, this message translates to:
  /// **'Harga Saat Ini (opsional)'**
  String get investmentFormCurrentPrice;

  /// No description provided for @investmentSellTitle.
  ///
  /// In id, this message translates to:
  /// **'Jual Investasi'**
  String get investmentSellTitle;

  /// No description provided for @investmentSellUnits.
  ///
  /// In id, this message translates to:
  /// **'Jumlah Unit Dijual'**
  String get investmentSellUnits;

  /// No description provided for @investmentSellUnitsHint.
  ///
  /// In id, this message translates to:
  /// **'Maks: {maxUnits}'**
  String investmentSellUnitsHint(String maxUnits);

  /// No description provided for @investmentSellUnitsRequired.
  ///
  /// In id, this message translates to:
  /// **'Jumlah unit dijual tidak boleh kosong'**
  String get investmentSellUnitsRequired;

  /// No description provided for @investmentSellUnitsExceed.
  ///
  /// In id, this message translates to:
  /// **'Unit dijual melebihi unit tersedia ({available})'**
  String investmentSellUnitsExceed(String available);

  /// No description provided for @investmentSellPricePerUnit.
  ///
  /// In id, this message translates to:
  /// **'Harga Jual per Unit'**
  String get investmentSellPricePerUnit;

  /// No description provided for @investmentSellPriceRequired.
  ///
  /// In id, this message translates to:
  /// **'Harga jual tidak boleh kosong'**
  String get investmentSellPriceRequired;

  /// No description provided for @investmentSellFee.
  ///
  /// In id, this message translates to:
  /// **'Biaya Jual (opsional)'**
  String get investmentSellFee;

  /// No description provided for @investmentSellCreditWallet.
  ///
  /// In id, this message translates to:
  /// **'Tambah ke Saldo Dompet'**
  String get investmentSellCreditWallet;

  /// No description provided for @investmentSellCreditWalletHint.
  ///
  /// In id, this message translates to:
  /// **'Tambahkan hasil penjualan ke saldo dompet'**
  String get investmentSellCreditWalletHint;

  /// No description provided for @investmentSellTotal.
  ///
  /// In id, this message translates to:
  /// **'Total Hasil Penjualan'**
  String get investmentSellTotal;

  /// No description provided for @investmentSellConfirm.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi Jual'**
  String get investmentSellConfirm;

  /// No description provided for @investmentSellAll.
  ///
  /// In id, this message translates to:
  /// **'Jual Semua'**
  String get investmentSellAll;

  /// No description provided for @investmentSettingsTitle.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan Aset'**
  String get investmentSettingsTitle;

  /// No description provided for @investmentSettingsName.
  ///
  /// In id, this message translates to:
  /// **'Nama Aset'**
  String get investmentSettingsName;

  /// No description provided for @investmentSettingsCurrentPrice.
  ///
  /// In id, this message translates to:
  /// **'Harga Saat Ini'**
  String get investmentSettingsCurrentPrice;

  /// No description provided for @investmentSettingsCategory.
  ///
  /// In id, this message translates to:
  /// **'Kategori Aset'**
  String get investmentSettingsCategory;

  /// No description provided for @investmentSettingsCategoryHint.
  ///
  /// In id, this message translates to:
  /// **'Pilih kategori untuk menentukan satuan'**
  String get investmentSettingsCategoryHint;

  /// No description provided for @investmentSettingsStatus.
  ///
  /// In id, this message translates to:
  /// **'Status'**
  String get investmentSettingsStatus;

  /// No description provided for @investmentSettingsActive.
  ///
  /// In id, this message translates to:
  /// **'Aktif'**
  String get investmentSettingsActive;

  /// No description provided for @investmentSettingsInactive.
  ///
  /// In id, this message translates to:
  /// **'Tidak Aktif'**
  String get investmentSettingsInactive;

  /// No description provided for @investmentSettingsSave.
  ///
  /// In id, this message translates to:
  /// **'Simpan Perubahan'**
  String get investmentSettingsSave;

  /// No description provided for @investmentSettingsDelete.
  ///
  /// In id, this message translates to:
  /// **'Hapus Investasi'**
  String get investmentSettingsDelete;

  /// No description provided for @investmentSettingsDeleteConfirm.
  ///
  /// In id, this message translates to:
  /// **'Yakin ingin menghapus \"{name}\"? Semua transaksi investasi ini juga akan terhapus.'**
  String investmentSettingsDeleteConfirm(String name);

  /// No description provided for @investmentSettingsDeleteWalletRevert.
  ///
  /// In id, this message translates to:
  /// **'Saldo dompet terkait akan dikembalikan.'**
  String get investmentSettingsDeleteWalletRevert;

  /// No description provided for @investmentGoldTypeTitle.
  ///
  /// In id, this message translates to:
  /// **'Jenis Emas Kustom'**
  String get investmentGoldTypeTitle;

  /// No description provided for @investmentGoldTypeAdd.
  ///
  /// In id, this message translates to:
  /// **'Tambah Jenis Emas'**
  String get investmentGoldTypeAdd;

  /// No description provided for @investmentGoldTypeEdit.
  ///
  /// In id, this message translates to:
  /// **'Edit Jenis Emas'**
  String get investmentGoldTypeEdit;

  /// No description provided for @investmentGoldTypeName.
  ///
  /// In id, this message translates to:
  /// **'Nama Jenis Emas'**
  String get investmentGoldTypeName;

  /// No description provided for @investmentGoldTypeNameHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: UBS, Galeri 24'**
  String get investmentGoldTypeNameHint;

  /// No description provided for @investmentGoldTypeNameRequired.
  ///
  /// In id, this message translates to:
  /// **'Nama jenis emas tidak boleh kosong'**
  String get investmentGoldTypeNameRequired;

  /// No description provided for @investmentGoldTypeMax.
  ///
  /// In id, this message translates to:
  /// **'Maksimal {max} jenis emas kustom'**
  String investmentGoldTypeMax(int max);

  /// No description provided for @investmentGoldTypeDeleteConfirm.
  ///
  /// In id, this message translates to:
  /// **'Yakin hapus jenis emas \"{name}\"?'**
  String investmentGoldTypeDeleteConfirm(String name);

  /// No description provided for @investmentCategoryTitle.
  ///
  /// In id, this message translates to:
  /// **'Kategori Aset Kustom'**
  String get investmentCategoryTitle;

  /// No description provided for @investmentCategoryAdd.
  ///
  /// In id, this message translates to:
  /// **'Tambah Kategori'**
  String get investmentCategoryAdd;

  /// No description provided for @investmentCategoryEdit.
  ///
  /// In id, this message translates to:
  /// **'Edit Kategori'**
  String get investmentCategoryEdit;

  /// No description provided for @investmentCategoryName.
  ///
  /// In id, this message translates to:
  /// **'Nama Kategori'**
  String get investmentCategoryName;

  /// No description provided for @investmentCategoryNameHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: Saham, Reksadana'**
  String get investmentCategoryNameHint;

  /// No description provided for @investmentCategoryNameRequired.
  ///
  /// In id, this message translates to:
  /// **'Nama kategori tidak boleh kosong'**
  String get investmentCategoryNameRequired;

  /// No description provided for @investmentCategoryUnitLabel.
  ///
  /// In id, this message translates to:
  /// **'Satuan'**
  String get investmentCategoryUnitLabel;

  /// No description provided for @investmentCategoryUnitLabelHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: lot, unit, lembar'**
  String get investmentCategoryUnitLabelHint;

  /// No description provided for @investmentCategoryUnitLabelRequired.
  ///
  /// In id, this message translates to:
  /// **'Satuan tidak boleh kosong'**
  String get investmentCategoryUnitLabelRequired;

  /// No description provided for @investmentCategoryMax.
  ///
  /// In id, this message translates to:
  /// **'Maksimal {max} kategori kustom'**
  String investmentCategoryMax(int max);

  /// No description provided for @investmentCategoryDeleteConfirm.
  ///
  /// In id, this message translates to:
  /// **'Yakin hapus kategori \"{name}\"?'**
  String investmentCategoryDeleteConfirm(String name);

  /// No description provided for @investmentCategoryManage.
  ///
  /// In id, this message translates to:
  /// **'Kelola Kategori'**
  String get investmentCategoryManage;

  /// No description provided for @investmentInactiveTitle.
  ///
  /// In id, this message translates to:
  /// **'Aset Tidak Aktif'**
  String get investmentInactiveTitle;

  /// No description provided for @investmentInactiveEmpty.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada aset tidak aktif'**
  String get investmentInactiveEmpty;

  /// No description provided for @investmentInactiveHint.
  ///
  /// In id, this message translates to:
  /// **'Aset yang telah dijual sepenuhnya akan muncul di sini'**
  String get investmentInactiveHint;

  /// No description provided for @investmentInactiveReactivate.
  ///
  /// In id, this message translates to:
  /// **'Aktifkan Kembali'**
  String get investmentInactiveReactivate;

  /// No description provided for @investmentSuccessCreate.
  ///
  /// In id, this message translates to:
  /// **'Investasi \"{name}\" berhasil ditambahkan'**
  String investmentSuccessCreate(String name);

  /// No description provided for @investmentSuccessTopUp.
  ///
  /// In id, this message translates to:
  /// **'Top up berhasil'**
  String get investmentSuccessTopUp;

  /// No description provided for @investmentSuccessSell.
  ///
  /// In id, this message translates to:
  /// **'Penjualan berhasil'**
  String get investmentSuccessSell;

  /// No description provided for @investmentSuccessEdit.
  ///
  /// In id, this message translates to:
  /// **'Transaksi berhasil diperbarui'**
  String get investmentSuccessEdit;

  /// No description provided for @investmentSuccessDelete.
  ///
  /// In id, this message translates to:
  /// **'Investasi berhasil dihapus'**
  String get investmentSuccessDelete;

  /// No description provided for @investmentSuccessUpdate.
  ///
  /// In id, this message translates to:
  /// **'Investasi berhasil diperbarui'**
  String get investmentSuccessUpdate;

  /// No description provided for @investmentSuccessDeleteTransaction.
  ///
  /// In id, this message translates to:
  /// **'Transaksi berhasil dihapus'**
  String get investmentSuccessDeleteTransaction;

  /// No description provided for @investmentErrorGeneric.
  ///
  /// In id, this message translates to:
  /// **'Gagal memproses. Coba lagi.'**
  String get investmentErrorGeneric;

  /// No description provided for @investmentErrorLoad.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat data investasi'**
  String get investmentErrorLoad;

  /// No description provided for @investmentErrorCreate.
  ///
  /// In id, this message translates to:
  /// **'Gagal menambah investasi'**
  String get investmentErrorCreate;

  /// No description provided for @investmentErrorTopUp.
  ///
  /// In id, this message translates to:
  /// **'Gagal top up investasi'**
  String get investmentErrorTopUp;

  /// No description provided for @investmentErrorSell.
  ///
  /// In id, this message translates to:
  /// **'Gagal menjual investasi'**
  String get investmentErrorSell;

  /// No description provided for @investmentErrorEdit.
  ///
  /// In id, this message translates to:
  /// **'Gagal memperbarui transaksi'**
  String get investmentErrorEdit;

  /// No description provided for @investmentErrorDelete.
  ///
  /// In id, this message translates to:
  /// **'Gagal menghapus investasi'**
  String get investmentErrorDelete;

  /// No description provided for @investmentErrorDeleteTransaction.
  ///
  /// In id, this message translates to:
  /// **'Gagal menghapus transaksi'**
  String get investmentErrorDeleteTransaction;

  /// No description provided for @investmentUnitGram.
  ///
  /// In id, this message translates to:
  /// **'gram'**
  String get investmentUnitGram;

  /// No description provided for @investmentUnitBtc.
  ///
  /// In id, this message translates to:
  /// **'BTC'**
  String get investmentUnitBtc;

  /// No description provided for @investmentGoldAntam.
  ///
  /// In id, this message translates to:
  /// **'Antam'**
  String get investmentGoldAntam;

  /// No description provided for @investmentGoldPerhiasan.
  ///
  /// In id, this message translates to:
  /// **'Perhiasan'**
  String get investmentGoldPerhiasan;

  /// No description provided for @investmentPriceSource.
  ///
  /// In id, this message translates to:
  /// **'Sumber: {source}'**
  String investmentPriceSource(String source);

  /// No description provided for @investmentLastUpdated.
  ///
  /// In id, this message translates to:
  /// **'Diperbarui: {time}'**
  String investmentLastUpdated(String time);

  /// No description provided for @investmentBuyPrice.
  ///
  /// In id, this message translates to:
  /// **'Harga Beli'**
  String get investmentBuyPrice;

  /// No description provided for @investmentSellPrice.
  ///
  /// In id, this message translates to:
  /// **'Harga Jual'**
  String get investmentSellPrice;

  /// No description provided for @investmentDirection.
  ///
  /// In id, this message translates to:
  /// **'Tipe'**
  String get investmentDirection;

  /// No description provided for @investmentDirectionBuy.
  ///
  /// In id, this message translates to:
  /// **'Beli'**
  String get investmentDirectionBuy;

  /// No description provided for @investmentDirectionSell.
  ///
  /// In id, this message translates to:
  /// **'Jual'**
  String get investmentDirectionSell;

  /// No description provided for @investmentTransactionCount.
  ///
  /// In id, this message translates to:
  /// **'{count} transaksi'**
  String investmentTransactionCount(int count);

  /// No description provided for @investmentFormPriceSource.
  ///
  /// In id, this message translates to:
  /// **'Sumber Harga'**
  String get investmentFormPriceSource;

  /// No description provided for @investmentFormPriceSourceHint.
  ///
  /// In id, this message translates to:
  /// **'Pilih sumber harga'**
  String get investmentFormPriceSourceHint;

  /// No description provided for @investmentPriceSourceAntaremas.
  ///
  /// In id, this message translates to:
  /// **'antaremas.com'**
  String get investmentPriceSourceAntaremas;

  /// No description provided for @investmentPriceSourceLogammulia.
  ///
  /// In id, this message translates to:
  /// **'logammulia.com'**
  String get investmentPriceSourceLogammulia;

  /// No description provided for @investmentPriceSourceManual.
  ///
  /// In id, this message translates to:
  /// **'Input Manual'**
  String get investmentPriceSourceManual;

  /// No description provided for @investmentPriceSourceIndodax.
  ///
  /// In id, this message translates to:
  /// **'Indodax'**
  String get investmentPriceSourceIndodax;

  /// No description provided for @investmentPriceSourceCoingecko.
  ///
  /// In id, this message translates to:
  /// **'CoinGecko'**
  String get investmentPriceSourceCoingecko;

  /// No description provided for @investmentPriceSourceLocked.
  ///
  /// In id, this message translates to:
  /// **'Terkunci ke Manual untuk jenis emas ini'**
  String get investmentPriceSourceLocked;

  /// No description provided for @investmentManageGoldTypes.
  ///
  /// In id, this message translates to:
  /// **'Kelola Jenis Emas'**
  String get investmentManageGoldTypes;

  /// No description provided for @investmentDeleteTransaction.
  ///
  /// In id, this message translates to:
  /// **'Hapus Transaksi'**
  String get investmentDeleteTransaction;

  /// No description provided for @investmentDeleteTransactionConfirm.
  ///
  /// In id, this message translates to:
  /// **'Yakin ingin menghapus transaksi ini? Saldo dompet akan dikembalikan jika terkait.'**
  String get investmentDeleteTransactionConfirm;

  /// No description provided for @investmentSettingsRevertWallet.
  ///
  /// In id, this message translates to:
  /// **'Kembalikan saldo dompet terkait'**
  String get investmentSettingsRevertWallet;

  /// No description provided for @investmentEditCurrentPrice.
  ///
  /// In id, this message translates to:
  /// **'Perbarui Harga Pasar'**
  String get investmentEditCurrentPrice;

  /// No description provided for @investmentEditCurrentPriceHint.
  ///
  /// In id, this message translates to:
  /// **'Masukkan harga pasar saat ini'**
  String get investmentEditCurrentPriceHint;

  /// No description provided for @investmentSettingsGoldType.
  ///
  /// In id, this message translates to:
  /// **'Jenis Emas'**
  String get investmentSettingsGoldType;

  /// No description provided for @investmentSettingsPriceSource.
  ///
  /// In id, this message translates to:
  /// **'Sumber Harga'**
  String get investmentSettingsPriceSource;

  /// No description provided for @investmentWalletRequired.
  ///
  /// In id, this message translates to:
  /// **'Silakan pilih dompet terlebih dahulu'**
  String get investmentWalletRequired;

  /// No description provided for @aiQuotaRemaining.
  ///
  /// In id, this message translates to:
  /// **'Sisa {remaining} dari {limit} kali hari ini'**
  String aiQuotaRemaining(int remaining, int limit);

  /// No description provided for @aiQuotaExhausted.
  ///
  /// In id, this message translates to:
  /// **'Batas harian tercapai. Coba lagi besok.'**
  String get aiQuotaExhausted;

  /// No description provided for @aiQuotaText.
  ///
  /// In id, this message translates to:
  /// **'Input Teks'**
  String get aiQuotaText;

  /// No description provided for @aiQuotaVoice.
  ///
  /// In id, this message translates to:
  /// **'Input Suara'**
  String get aiQuotaVoice;

  /// No description provided for @aiQuotaOcr.
  ///
  /// In id, this message translates to:
  /// **'Scan Struk'**
  String get aiQuotaOcr;

  /// No description provided for @aiQuotaLabel.
  ///
  /// In id, this message translates to:
  /// **'Kuota AI'**
  String get aiQuotaLabel;

  /// No description provided for @settingsSendReport.
  ///
  /// In id, this message translates to:
  /// **'Kirim Laporan'**
  String get settingsSendReport;

  /// No description provided for @sendReportTitle.
  ///
  /// In id, this message translates to:
  /// **'Kirim Laporan'**
  String get sendReportTitle;

  /// No description provided for @sendReportCategory.
  ///
  /// In id, this message translates to:
  /// **'Kategori'**
  String get sendReportCategory;

  /// No description provided for @sendReportCategoryHint.
  ///
  /// In id, this message translates to:
  /// **'Pilih kategori laporan'**
  String get sendReportCategoryHint;

  /// No description provided for @sendReportFormTitle.
  ///
  /// In id, this message translates to:
  /// **'Judul'**
  String get sendReportFormTitle;

  /// No description provided for @sendReportFormTitleHint.
  ///
  /// In id, this message translates to:
  /// **'Tuliskan judul laporan singkat'**
  String get sendReportFormTitleHint;

  /// No description provided for @sendReportDescription.
  ///
  /// In id, this message translates to:
  /// **'Deskripsi'**
  String get sendReportDescription;

  /// No description provided for @sendReportDescriptionHint.
  ///
  /// In id, this message translates to:
  /// **'Jelaskan masalah atau permintaanmu secara detail'**
  String get sendReportDescriptionHint;

  /// No description provided for @sendReportPhoto.
  ///
  /// In id, this message translates to:
  /// **'Foto Lampiran'**
  String get sendReportPhoto;

  /// No description provided for @sendReportAddPhoto.
  ///
  /// In id, this message translates to:
  /// **'Tambah Foto (Opsional)'**
  String get sendReportAddPhoto;

  /// No description provided for @sendReportChangePhoto.
  ///
  /// In id, this message translates to:
  /// **'Ganti Foto'**
  String get sendReportChangePhoto;

  /// No description provided for @sendReportRemovePhoto.
  ///
  /// In id, this message translates to:
  /// **'Hapus Foto'**
  String get sendReportRemovePhoto;

  /// No description provided for @sendReportSubmit.
  ///
  /// In id, this message translates to:
  /// **'Kirim Laporan'**
  String get sendReportSubmit;

  /// No description provided for @sendReportSuccessTitle.
  ///
  /// In id, this message translates to:
  /// **'Laporan Terkirim'**
  String get sendReportSuccessTitle;

  /// No description provided for @sendReportSuccessMessage.
  ///
  /// In id, this message translates to:
  /// **'Terima kasih! Laporan kamu sudah kami terima.'**
  String get sendReportSuccessMessage;

  /// No description provided for @sendReportValidateCategory.
  ///
  /// In id, this message translates to:
  /// **'Pilih kategori laporan'**
  String get sendReportValidateCategory;

  /// No description provided for @sendReportValidateTitle.
  ///
  /// In id, this message translates to:
  /// **'Judul minimal 5 karakter'**
  String get sendReportValidateTitle;

  /// No description provided for @sendReportValidateDescription.
  ///
  /// In id, this message translates to:
  /// **'Deskripsi minimal 10 karakter'**
  String get sendReportValidateDescription;

  /// No description provided for @sendReportCategoryBugReport.
  ///
  /// In id, this message translates to:
  /// **'Laporan Bug'**
  String get sendReportCategoryBugReport;

  /// No description provided for @sendReportCategoryFeatureRequest.
  ///
  /// In id, this message translates to:
  /// **'Permintaan Fitur'**
  String get sendReportCategoryFeatureRequest;

  /// No description provided for @sendReportCategoryAccountIssue.
  ///
  /// In id, this message translates to:
  /// **'Masalah Akun'**
  String get sendReportCategoryAccountIssue;

  /// No description provided for @sendReportCategoryPaymentIssue.
  ///
  /// In id, this message translates to:
  /// **'Masalah Pembayaran'**
  String get sendReportCategoryPaymentIssue;

  /// No description provided for @sendReportCategoryOther.
  ///
  /// In id, this message translates to:
  /// **'Lainnya'**
  String get sendReportCategoryOther;

  /// No description provided for @reportInsightRatioHealthy.
  ///
  /// In id, this message translates to:
  /// **'Kamu membelanjakan {percent}% dari pemasukanmu. Sisanya bisa ditabung atau diinvestasikan. Lanjutkan! 👏'**
  String reportInsightRatioHealthy(String percent);

  /// No description provided for @reportInsightRatioWarning.
  ///
  /// In id, this message translates to:
  /// **'Kamu membelanjakan {percent}% dari pemasukanmu. Idealnya di bawah 50% supaya ada ruang menabung.'**
  String reportInsightRatioWarning(String percent);

  /// No description provided for @reportInsightRatioDanger.
  ///
  /// In id, this message translates to:
  /// **'Kamu membelanjakan {percent}% dari pemasukanmu — hampir tidak ada sisa. Coba kurangi pengeluaran yang tidak mendesak.'**
  String reportInsightRatioDanger(String percent);

  /// No description provided for @reportInsightRatioCritical.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaranmu melebihi pemasukan sebesar {amount}. Kamu sedang memakai tabungan. Perlu segera dievaluasi.'**
  String reportInsightRatioCritical(String amount);

  /// No description provided for @reportInsightRatioNoIncome.
  ///
  /// In id, this message translates to:
  /// **'Belum ada pemasukan tercatat. Catat pemasukan agar bisa menganalisis kesehatan keuanganmu.'**
  String get reportInsightRatioNoIncome;

  /// No description provided for @reportInsightTrendDownBig.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaranmu turun {amount} ({percent}%) dari periode lalu. Kerja bagus — pertahankan pola ini! 👍'**
  String reportInsightTrendDownBig(String amount, String percent);

  /// No description provided for @reportInsightTrendDownSmall.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaranmu turun sedikit ({percent}%). Sudah di jalur yang baik!'**
  String reportInsightTrendDownSmall(String percent);

  /// No description provided for @reportInsightTrendStable.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaranmu stabil — total {amount} periode ini.'**
  String reportInsightTrendStable(String amount);

  /// No description provided for @reportInsightTrendUpSmall.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaranmu naik sedikit ({percent}%). Cek apakah ada kebutuhan dadakan atau bisa dikurangi.'**
  String reportInsightTrendUpSmall(String percent);

  /// No description provided for @reportInsightTrendUpBig.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaranmu naik {amount} ({percent}%). Penyebab terbesar: {category}. Coba batasi di kategori ini.'**
  String reportInsightTrendUpBig(
    String amount,
    String percent,
    String category,
  );

  /// No description provided for @reportInsightTrendUpBigNoCategory.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaranmu naik {amount} ({percent}%) dari periode lalu. Coba evaluasi pengeluaran yang bisa dikurangi.'**
  String reportInsightTrendUpBigNoCategory(String amount, String percent);

  /// No description provided for @reportInsightCategoryDominant.
  ///
  /// In id, this message translates to:
  /// **'Kategori {category} mendominasi {percent}% pengeluaranmu ({amount}). Cek apakah bisa dikurangi.'**
  String reportInsightCategoryDominant(
    String category,
    String percent,
    String amount,
  );

  /// No description provided for @reportInsightPeakDay.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran terbesar di tanggal {date} ({amount}), yaitu {percent}% dari total pengeluaran.'**
  String reportInsightPeakDay(String date, String amount, String percent);

  /// No description provided for @iconPickerTitle.
  ///
  /// In id, this message translates to:
  /// **'Pilih Ikon'**
  String get iconPickerTitle;

  /// No description provided for @iconPickerSearch.
  ///
  /// In id, this message translates to:
  /// **'Cari ikon...'**
  String get iconPickerSearch;

  /// No description provided for @iconSearchEmpty.
  ///
  /// In id, this message translates to:
  /// **'Ikon tidak ditemukan'**
  String get iconSearchEmpty;

  /// No description provided for @iconSectionFinance.
  ///
  /// In id, this message translates to:
  /// **'Keuangan'**
  String get iconSectionFinance;

  /// No description provided for @iconSectionShopping.
  ///
  /// In id, this message translates to:
  /// **'Belanja & Gaya Hidup'**
  String get iconSectionShopping;

  /// No description provided for @iconSectionFoodDrink.
  ///
  /// In id, this message translates to:
  /// **'Makanan & Minuman'**
  String get iconSectionFoodDrink;

  /// No description provided for @iconSectionHousehold.
  ///
  /// In id, this message translates to:
  /// **'Rumah Tangga'**
  String get iconSectionHousehold;

  /// No description provided for @iconSectionTransport.
  ///
  /// In id, this message translates to:
  /// **'Transportasi'**
  String get iconSectionTransport;

  /// No description provided for @iconSectionHealth.
  ///
  /// In id, this message translates to:
  /// **'Kesehatan & Kebugaran'**
  String get iconSectionHealth;

  /// No description provided for @iconSectionBills.
  ///
  /// In id, this message translates to:
  /// **'Tagihan & Utilitas'**
  String get iconSectionBills;

  /// No description provided for @iconSectionTech.
  ///
  /// In id, this message translates to:
  /// **'Teknologi'**
  String get iconSectionTech;

  /// No description provided for @iconSectionEducation.
  ///
  /// In id, this message translates to:
  /// **'Pendidikan & Karier'**
  String get iconSectionEducation;

  /// No description provided for @iconSectionEntertainment.
  ///
  /// In id, this message translates to:
  /// **'Hiburan'**
  String get iconSectionEntertainment;

  /// No description provided for @iconSectionNature.
  ///
  /// In id, this message translates to:
  /// **'Alam & Hewan'**
  String get iconSectionNature;

  /// No description provided for @iconSectionSocial.
  ///
  /// In id, this message translates to:
  /// **'Sosial & Keluarga'**
  String get iconSectionSocial;

  /// No description provided for @iconSectionOther.
  ///
  /// In id, this message translates to:
  /// **'Lainnya'**
  String get iconSectionOther;

  /// No description provided for @noMoreData.
  ///
  /// In id, this message translates to:
  /// **'Data kamu cukup sampai sini nih..'**
  String get noMoreData;
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
