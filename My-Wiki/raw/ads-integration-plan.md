# Plan: Ads Integration — SakuRapi (Google AdMob)

**Tanggal**: 2026-04-15  
**Status**: Planning  
**Scope**: Banner Ads, Native In-List Ads, Interstitial Ad post-save  
**Target awal**: Dev environment dulu

---

## 1. Latar Belakang & Tujuan

SakuRapi belum punya monetisasi. Model yang dipilih: **sekali beli, iklan hilang selamanya** (bukan langganan, tidak ada expired). Ads adalah pendapatan default untuk user gratis. Syarat utama:

1. **Tidak mengganggu flow inti** — CRUD transaksi harus bebas iklan sepenuhnya
2. **Scalable** — admin bisa matikan ads per-user dari Supabase dashboard
3. **Config terpusat** — satu tempat untuk atur semua parameter ads
4. **Siap untuk in-app purchase** — saat fitur beli hadir, cukup update satu kolom DB

> **Catatan**: `profiles.tier` dan `profiles.tier_expires_at` adalah untuk fitur AI (bukan ads).  
> Ads menggunakan kolom terpisah: `profiles.show_ads`.

---

## 2. Keputusan Desain

| Keputusan | Pilihan | Alasan |
|---|---|---|
| SDK | `google_mobile_ads` (official) | Support Banner, Native, Interstitial sekaligus |
| Gate utama | `profiles.show_ads` (boolean) | Kolom baru terpisah — tidak campur dengan AI tier |
| Model pembelian | One-time purchase, no expiry | `show_ads = false` → selamanya tidak lihat iklan |
| Admin control | Update `show_ads` langsung di Supabase dashboard | Tidak perlu UI admin khusus untuk MVP |
| Cache di client | Field `showAds` di `UserModel` + Hive | Offline-first, tidak fetch DB tiap render |
| Dev flavor | Selalu pakai test Ad Unit IDs | Tidak memakai real traffic di dev |
| Config central | `AdsConfig` class (satu file) | Satu tempat ubah frekuensi, unit ID, toggle |
| Interstitial frekuensi | 1x per **5 transaksi disimpan** | Tidak terlalu sering, tidak terlalu jarang |
| Ads di form | **Tidak ada sama sekali** | Core flow CRUD harus bebas distraksi |

---

## 3. Perubahan Database (Supabase Dev)

### Migrasi: Tambah kolom `show_ads` di `profiles`

```sql
ALTER TABLE public.profiles
  ADD COLUMN show_ads boolean NOT NULL DEFAULT true;

COMMENT ON COLUMN public.profiles.show_ads IS
  'true = tampilkan iklan (default). false = user sudah beli no-ads, iklan tidak ditampilkan.';
```

- `DEFAULT true` → semua user existing otomatis lihat ads
- Untuk matikan ads user: update langsung di Supabase Table Editor → `show_ads = false`
- Tidak perlu RLS khusus untuk kolom ini — user tidak boleh update `show_ads` sendiri (hanya bisa dibaca)

### Update RLS (jika belum ada)

```sql
-- User hanya bisa READ show_ads milik mereka sendiri, tidak bisa update
-- Biasanya sudah tercakup oleh policy SELECT existing di profiles
-- Pastikan tidak ada policy UPDATE yang expose show_ads ke user
```

---



### 3.1 Banner Ad — Dashboard (bawah konten)
- **Halaman**: `dashboard_page.dart`
- **Posisi**: Fixed di bawah seluruh konten dashboard, tepat di atas bottom nav
- **Format**: `AnchoredAdaptiveBannerAdSize` (lebar layar)
- **Load saat**: `initState` dashboard, dispose saat keluar

### 3.2 Banner Ad — History Page (bawah list)
- **Halaman**: `history_page.dart`
- **Posisi**: Fixed di bawah list transaksi (di atas bottom nav / pagination indicator)
- **Format**: `AnchoredAdaptiveBannerAdSize`
- **Catatan**: Tidak menutupi FAB tambah transaksi

### 3.3 Native Ad — Sisip di History List (setiap 10 item)
- **Halaman**: `history_page.dart` — di dalam `ListView.builder` list transaksi
- **Format**: Native Ad (custom card) — tampil seperti item transaksi biasa
- **Frekuensi**: Setiap 10 item nyata → sisip 1 native ad card
- **Logika index**: `if (index > 0 && index % 11 == 10) return NativeAdCard()`
- **Catatan**: Native ad dimuat terpisah dari banner, pre-load saat list render

### 3.4 Interstitial Ad — Setelah Simpan Transaksi
- **Trigger**: Setelah `_onSave()` di `transaction_form_page.dart` berhasil dan navigator sudah pop
- **Frekuensi**: Counter di `AdsService` — tampil hanya setiap 5 transaksi disimpan
- **Counter**: Disimpan di Hive (persist across sessions) untuk konsistensi
- **Flow**:
  1. Simpan transaksi → sukses → pop form
  2. `AdsService.incrementSaveCounter()` dipanggil
  3. Jika counter % 5 == 0 → `_interstitialAd?.show()`
  4. Pre-load iklan berikutnya setelah show

---

## 4. Arsitektur

### 4.1 File Baru / File yang Diubah

```
lib/core/ads/
├── ads_config.dart               ← Semua konstanta: unit IDs, frekuensi, toggle
├── ads_service.dart              ← Singleton: load/show/dispose semua ad type
└── ads_eligibility_provider.dart ← Riverpod provider: apakah user boleh lihat ads

lib/global/widgets/
├── saku_banner_ad_widget.dart    ← Reusable banner widget (handle load+error)
└── saku_native_ad_card.dart      ← Reusable native ad card untuk list

lib/features/auth/models/
└── user_model.dart               ← [DIUBAH] Tambah field showAds
```

### 4.2 Perubahan `UserModel` — Tambah `showAds`

```dart
// lib/features/auth/models/user_model.dart

class UserModel {
  const UserModel({
    // ... field existing ...
    this.showAds = true,  // ← BARU
  });

  // ... field existing ...
  
  /// Apakah iklan ditampilkan untuk user ini.
  /// false = user sudah beli no-ads (diset dari Supabase dashboard oleh admin).
  /// Default true untuk semua user baru.
  final bool showAds;

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      // ... field existing ...
      showAds: map['show_ads'] as bool? ?? true,  // ← BARU (null-safe, default true)
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // ... field existing ...
      // show_ads TIDAK di-include di toMap() — user tidak boleh update sendiri
    };
  }

  UserModel copyWith({
    // ... field existing ...
    bool? showAds,  // ← BARU
  }) {
    return UserModel(
      // ... field existing ...
      showAds: showAds ?? this.showAds,
    );
  }
}
```

### 4.3 `AdsConfig` — Satu Tempat Kontrol Semua

```dart
// lib/core/ads/ads_config.dart

class AdsConfig {
  AdsConfig._();

  // ── Global kill-switch ──
  // Set false untuk mematikan SEMUA ads sekaligus (misal saat debugging prod)
  static const bool adsEnabled = true;

  // ── Frekuensi ──
  static const int interstitialEveryNSaves = 5;
  static const int nativeAdEveryNItems = 10;

  // ── Ad Unit IDs (prod) ──
  // Ganti dengan ID asli dari AdMob console setelah akun siap
  static const String _bannerIdAndroidProd = 'ca-app-pub-XXXX/banner_id';
  static const String _bannerIdIosProd = 'ca-app-pub-XXXX/banner_id_ios';
  static const String _interstitialIdAndroidProd = 'ca-app-pub-XXXX/interstitial_id';
  static const String _interstitialIdIosProd = 'ca-app-pub-XXXX/interstitial_id_ios';
  static const String _nativeIdAndroidProd = 'ca-app-pub-XXXX/native_id';
  static const String _nativeIdIosProd = 'ca-app-pub-XXXX/native_id_ios';

  // ── Ad Unit IDs (dev/test — Google official test IDs) ──
  static const String _bannerIdAndroidTest = 'ca-app-pub-3940256099942544/6300978111';
  static const String _bannerIdIosTest = 'ca-app-pub-3940256099942544/2934735716';
  static const String _interstitialIdAndroidTest = 'ca-app-pub-3940256099942544/1033173712';
  static const String _interstitialIdIosTest = 'ca-app-pub-3940256099942544/4411468910';
  static const String _nativeIdAndroidTest = 'ca-app-pub-3940256099942544/2247696110';
  static const String _nativeIdIosTest = 'ca-app-pub-3940256099942544/3986624511';

  // ── Getters (pilih prod/test berdasarkan flavor) ──
  static String get bannerId {
    final isProd = AppFlavorConfig.isProd;
    if (Platform.isAndroid) return isProd ? _bannerIdAndroidProd : _bannerIdAndroidTest;
    return isProd ? _bannerIdIosProd : _bannerIdIosTest;
  }
  // interstitialId dan nativeId — pola sama
}
```

### 4.4 `AdsEligibilityProvider` — Gate Ads

```dart
// lib/core/ads/ads_eligibility_provider.dart

/// true  = user boleh lihat ads
/// false = user sudah beli no-ads (profiles.show_ads == false)
final adsEligibleProvider = Provider<bool>((ref) {
  // Kill-switch global (AdsConfig.adsEnabled = false → matikan semua)
  if (!AdsConfig.adsEnabled) return false;

  final user = ref.watch(cachedUserProvider); // UserModel? dari Hive cache
  if (user == null) return true;  // belum load → default tampilkan
  return user.showAds;            // langsung baca dari field model
});
```

**Kenapa sederhana?**
- Tidak ada expired check — pembelian sekali, `show_ads = false` selamanya
- `UserModel` sudah di-cache di Hive saat login → tidak ada network call tambahan
- Perubahan `show_ads` di Supabase akan ter-refresh saat user logout/login berikutnya
  (atau bisa ditambah periodic refresh jika dibutuhkan nanti)

### 4.5 `AdsService` — Load/Show/Dispose

```dart
// lib/core/ads/ads_service.dart
// Singleton yang di-init di bootstrap()

class AdsService {
  // Menyimpan interstitial yang sudah di-preload
  // Counter save transaksi (persist Hive box 'ads_prefs', key 'save_counter')
  // Method: init(), preloadInterstitial(),
  //         showInterstitialIfDue(context, isEligible),
  //         incrementSaveCounter(), dispose()
}
```

### 4.6 `SakuBannerAdWidget` — Reusable

```dart
// lib/global/widgets/saku_banner_ad_widget.dart

class SakuBannerAdWidget extends ConsumerStatefulWidget {
  // Baca adsEligibleProvider
  // Jika !eligible → return SizedBox.shrink() (tidak ada layout space)
  // Load banner di initState, dispose di dispose()
  // Error load → SizedBox.shrink() (silent fail, tidak crash)
}
```

### 4.7 `SakuNativeAdCard` — In-List Card

```dart
// lib/global/widgets/saku_native_ad_card.dart

class SakuNativeAdCard extends StatefulWidget {
  // Native ad dengan tampilan mirip transaction card
  // Height konsisten agar tidak membuat layout jump saat load
  // Label "Iklan" kecil di pojok kanan atas
  // Silent fail jika native ad tidak terload → SizedBox.shrink()
}
```

---

## 5. Integrasi per Halaman

### Dashboard
```dart
// Bungkus konten dengan Column:
Column(
  children: [
    Expanded(child: DashboardContent()),
    SakuBannerAdWidget(), // ← tambah ini
  ],
)
```

### History Page
```dart
// Di bawah list, sebelum bottom padding:
Column(
  children: [
    Expanded(child: HistoryListSection()),
    SakuBannerAdWidget(), // ← di bawah list
  ],
)

// Di dalam list builder (native):
builder: (ctx, index) {
  final adjustedIndex = index - (index ~/ 11); // kompensasi native ad slot
  if (index > 0 && index % 11 == 10) return SakuNativeAdCard();
  return TransactionGroupCard(groups[adjustedIndex]);
}
```

### Transaction Form — Post-Save
```dart
// Di _onSave(), setelah pop berhasil:
if (mounted) {
  AdsService.instance.incrementSaveCounter();
  await AdsService.instance.showInterstitialIfDue(context);
}
```

---

## 6. Interstitial Counter — Detail

| Komponen | Detail |
|---|---|
| Storage | Hive box `ads_prefs`, key `save_counter` |
| Type | `int`, default 0 |
| Increment | Setiap kali `_onSave()` sukses (create AND update) |
| Trigger | `if (counter % 5 == 0 && counter > 0) → show` |
| Pre-load | Setelah show → langsung `preloadInterstitial()` berikutnya |
| Gagal load | Silent fail — counter tetap jalan, tidak crash |
| Context check | Pastikan `context.mounted` sebelum show |

---

## 7. Yang TIDAK Dilakukan

| Item | Alasan |
|---|---|
| Ads di Transaction Form | Core flow — bebas distraksi |
| Ads di Settlement flow | Sensitif, user sedang bayar hutang |
| Ads di Login/Splash | Impresi pertama |
| Ads di Settings | User problem-solving |
| Rewarded Ads | Ditunda ke sprint berikutnya |
| Ads di Investment Smart Form | User lagi input angka investasi |
| Refresh banner setiap X detik | Terlalu invasif, tidak perlu |

---

## 8. Langkah Implementasi (Urutan)

1. **Migrasi Supabase Dev** — `ALTER TABLE profiles ADD COLUMN show_ads boolean NOT NULL DEFAULT true`
2. **Update `UserModel`** — tambah field `showAds`, update `fromMap()` dan `copyWith()`
3. **Tambah package** — `google_mobile_ads` ke `pubspec.yaml`, setup AndroidManifest + Info.plist
4. **Buat `AdsConfig`** — semua konstanta, unit IDs, frekuensi
5. **Buat `AdsEligibilityProvider`** — baca `user.showAds` dari cached `UserModel`
6. **Buat `AdsService`** — init AdMob, preload interstitial, counter logic (Hive)
7. **Init di `bootstrap()`** — `AdsService.instance.init()`
8. **Buat `SakuBannerAdWidget`** — reusable, silent fail
9. **Buat `SakuNativeAdCard`** — reusable, tampilan mirip transaksi
10. **Integrasi Dashboard** — pasang `SakuBannerAdWidget`
11. **Integrasi History** — pasang banner bawah + native in-list
12. **Integrasi Transaction Form** — panggil `showInterstitialIfDue()` post-save
13. **Testing** — verifikasi test Ad Unit IDs di dev, toggle `show_ads` di Supabase dashboard

---

## 9. Hal yang Harus Disiapkan Secara Manual (oleh Developer)

| Item | Keterangan |
|---|---|
| **AdMob Account** | Buat di [admob.google.com](https://admob.google.com) |
| **AdMob App ID** | Dua ID: satu Android, satu iOS — isi di `AndroidManifest.xml` dan `Info.plist` |
| **Ad Unit IDs** | Buat 3 unit: Banner, Interstitial, Native — catat di `AdsConfig._*Prod` constants |
| **Info.plist iOS** | Tambah `GADApplicationIdentifier` key |
| **AndroidManifest.xml** | Tambah `<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID">` |

> Selama belum punya AdMob account, implementasi tetap bisa jalan di dev  
> menggunakan **Google official test Ad Unit IDs** yang sudah ada di `AdsConfig`.

---

## 10. Cara Matikan Ads per User (Admin Flow)

Tidak perlu UI admin khusus. Cukup langsung di Supabase:

1. Buka **Supabase Dashboard → Table Editor → profiles**
2. Cari row user yang mau dimatikan iklannya
3. Set `show_ads = false`
4. Done — saat user restart app atau re-login, ads tidak akan tampil lagi

**Untuk fitur beli no-ads di app (future):**
1. User tap "Beli Hapus Iklan" → proses in-app purchase
2. Setelah purchase verified → panggil Supabase RPC/function untuk update `show_ads = false`
3. Refresh `UserModel` di cache → `adsEligibleProvider` otomatis return `false`
4. Semua widget ads render `SizedBox.shrink()` tanpa restart

**Tidak perlu ubah kode Flutter sama sekali saat fitur beli diimplementasikan.**

