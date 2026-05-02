import 'package:app_saku_rapi/features/category/models/category_ownership.dart';
import 'package:app_saku_rapi/l10n/app_localizations.dart';

/// Nama kategori untuk UI: katalog global pakai terjemahan; milik user / tidak pasti → [rawName].
String resolvedCategoryDisplayName({
  required AppLocalizations l10n,
  required String rawName,
  required CategoryOwnership ownership,
}) {
  if (ownership != CategoryOwnership.global) return rawName;
  return localizedCatalogCategoryName(l10n, rawName);
}

/// Nama tampilan untuk baris katalog global berdasarkan string nama di DB (Indonesia).
///
/// String yang tidak dikenal dikembalikan apa adanya ([dbName]).
String localizedCatalogCategoryName(AppLocalizations l10n, String dbName) {
  switch (dbName) {
    case 'Penyesuaian Saldo':
      return l10n.catalogAdjustmentBalance;
    case 'Transfer ke Aset':
      return l10n.catalogTransferToAsset;
    case 'Makanan & Minuman':
      return l10n.catalogFoodDrinks;
    case 'Kopi & Minuman':
      return l10n.catalogCoffeeBeverages;
    case 'Delivery / Pesan Antar':
      return l10n.catalogDeliveryTakeout;
    case 'Restoran & Kafe':
      return l10n.catalogRestaurantCafe;
    case 'Jajan & Camilan':
      return l10n.catalogSnacksTreats;
    case 'Kebutuhan Rumah Tangga':
      return l10n.catalogHouseholdNeeds;
    case 'Belanja Dapur / Bahan Makanan':
      return l10n.catalogGroceriesPantry;
    case 'Perlengkapan Rumah':
      return l10n.catalogHomeSupplies;
    case 'Makan di Luar / Jajan':
      return l10n.catalogDiningOutCasual;
    case 'Kesehatan & Kebugaran':
      return l10n.catalogHealthFitness;
    case 'Olahraga / Gym':
      return l10n.catalogSportsGym;
    case 'Suplemen & Nutrisi':
      return l10n.catalogSupplementsNutrition;
    case 'Medis / Dokter / Obat':
      return l10n.catalogMedicalDoctorMeds;
    case 'Kesehatan Mental / Terapi':
      return l10n.catalogMentalHealthTherapy;
    case 'Transportasi':
      return l10n.catalogTransportation;
    case 'Bensin':
      return l10n.catalogFuel;
    case 'Tol':
      return l10n.catalogTolls;
    case 'Parkir':
      return l10n.catalogParking;
    case 'Transportasi Umum':
      return l10n.catalogPublicTransit;
    case 'Ojol':
      return l10n.catalogRideHailing;
    case 'Servis Kendaraan':
      return l10n.catalogVehicleService;
    case 'Tagihan & Kewajiban':
      return l10n.catalogBillsObligations;
    case 'Listrik & Air':
      return l10n.catalogElectricityWater;
    case 'Internet & Pulsa':
      return l10n.catalogInternetMobile;
    case 'Cicilan / Asuransi':
      return l10n.catalogInstallmentsInsurance;
    case 'Sewa Rumah':
      return l10n.catalogHomeRent;
    case 'KPR':
      return l10n.catalogMortgage;
    case 'Teknologi & Edukasi':
      return l10n.catalogTechEducation;
    case 'Langganan Digital':
      return l10n.catalogDigitalSubscriptions;
    case 'Kursus':
      return l10n.catalogCourses;
    case 'Buku':
      return l10n.catalogBooks;
    case 'Server & Hosting':
      return l10n.catalogServersHosting;
    case 'Keluarga & Sosial':
      return l10n.catalogFamilySocial;
    case 'Kebutuhan Pasangan':
      return l10n.catalogPartnerHouseholdNeeds;
    case 'Kondangan / Donasi':
      return l10n.catalogEventsDonations;
    case 'Nongkrong & Sosial':
      return l10n.catalogHangoutsSocial;
    case 'Hewan Peliharaan':
      return l10n.catalogPets;
    case 'Lain-lain':
      return l10n.catalogMiscOthers;
    case 'Biaya Admin / Pajak / Selisih':
      return l10n.catalogFeesTaxRounding;
    case 'Pengeluaran Tak Terduga':
      return l10n.catalogUnexpectedExpense;
    case 'Tidak Diketahui':
      return l10n.catalogUnknown;
    case 'Belanja & Fashion':
      return l10n.catalogShoppingFashion;
    case 'Pakaian & Aksesori':
      return l10n.catalogClothingAccessories;
    case 'Sepatu & Tas':
      return l10n.catalogShoesBags;
    case 'Kosmetik & Skincare':
      return l10n.catalogCosmeticsSkincare;
    case 'Salon & Perawatan Diri':
      return l10n.catalogSalonPersonalCare;
    case 'Hiburan & Hobi':
      return l10n.catalogEntertainmentHobbies;
    case 'Bioskop & Konser':
      return l10n.catalogMoviesConcerts;
    case 'Game & Gaming':
      return l10n.catalogGamesGaming;
    case 'Hobi & Koleksi':
      return l10n.catalogHobbiesCollecting;
    case 'Liburan & Wisata':
      return l10n.catalogTravelLeisure;
    case 'Gaji & Pendapatan Utama':
      return l10n.catalogSalaryPrimaryIncome;
    case 'Gaji Bulanan':
      return l10n.catalogMonthlySalary;
    case 'Bonus / THR':
      return l10n.catalogBonusHolidayPay;
    case 'Pendapatan Tambahan':
      return l10n.catalogAdditionalIncome;
    case 'Pekerjaan Sampingan / Freelance':
      return l10n.catalogFreelanceSideJobs;
    case 'Hasil Investasi / Dividen':
      return l10n.catalogInvestmentDividends;
    case 'Pencairan Dana':
      return l10n.catalogWithdrawalsRedemptions;
    case 'Cashback & Reward':
      return l10n.catalogCashbackRewards;
    case 'Penjualan Barang / Aset':
      return l10n.catalogSalesGoodsAssets;
    case 'Hadiah / Pemberian':
      return l10n.catalogGiftsReceived;
    default:
      return dbName;
  }
}
