---
title: "Ads — Sistem Iklan Google AdMob"
type: entity
tags: [ads, admob, monetisasi, banner, native, interstitial, eligibility]
sources: [raw/ads-integration-plan.md]
created: 2026-04-19
updated: 2026-04-19
---

# Ads — Sistem Iklan Google AdMob

## Ringkasan

SakuRapi mengintegrasikan Google AdMob sebagai sumber pendapatan. Iklan ditampilkan hanya untuk user yang `show_ads = true`. User dapat membeli fitur "no-ads" (one-time purchase) yang mengubah flag ini ke `false` secara permanen.

**Status implementasi:** Planning (belum diimplementasi, April 2026)

---

## Tipe Iklan

| Tipe | Penempatan | Frekuensi |
|------|-----------|-----------|
| **Banner** | Dashboard (bawah) + History (atas) | Selalu tampil (jika eligible) |
| **Native** | History list (di antara item) | Setiap 10 item nyata → 1 native card (`index % 11 == 10`) |
| **Interstitial** | Setelah simpan transaksi | 1x per 5 simpan (counter di Hive) |

---

## Eligibility Gate

Sebelum menampilkan iklan apapun, cek `AdsEligibilityProvider`:

```dart
// Riverpod provider, membaca dari Hive-cached UserModel.showAds
final adsEligibilityProvider = Provider<bool>((ref) {
  return ref.watch(userProvider)?.showAds ?? true;
});
```

- **Tidak ada API call per tampilan** — dibaca dari Hive cache
- User dengan `showAds = false` tidak pernah melihat iklan

---

## Database

```sql
-- Kolom di tabel profiles
ALTER TABLE profiles ADD COLUMN show_ads BOOLEAN NOT NULL DEFAULT TRUE;
```

Admin toggle via Supabase dashboard (bukan dari Flutter — user tidak bisa update sendiri).

---

## Arsitektur Flutter

```
lib/core/ads/
├── ads_config.dart               ← konstanta: unit IDs, frekuensi, toggle
├── ads_service.dart              ← Singleton load/show/dispose
└── ads_eligibility_provider.dart ← Riverpod provider

lib/global/widgets/
├── saku_banner_ad_widget.dart    ← reusable banner
└── saku_native_ad_card.dart      ← native card untuk list
```

---

## AdUnit IDs — Flavor Based

| Flavor | Banner | Native | Interstitial |
|--------|--------|--------|-------------|
| `dev` | Test ID Google | Test ID Google | Test ID Google |
| `prod` | ID AdMob produksi | ID AdMob produksi | ID AdMob produksi |

---

## UserModel — Field `showAds`

```dart
class UserModel {
  final bool showAds; // default: true

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    showAds: map['show_ads'] as bool? ?? true,
    // ...
  );

  // TIDAK di-include di toMap() — user tidak boleh update sendiri
}
```

---

## Halaman Terkait

- [[wiki/sources/plan-ads-integration|Plan: Integrasi Google AdMob]]
- [[wiki/entities/dashboard|Dashboard]]
- [[wiki/entities/history|History]]
- [[wiki/entities/transaksi|Transaksi]]
