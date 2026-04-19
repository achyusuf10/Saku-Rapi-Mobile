---
title: "Plan: Integrasi Google AdMob"
type: source
tags: [ads, admob, monetisasi, banner, native, interstitial]
sources: [raw/ads-integration-plan.md]
created: 2026-04-19
updated: 2026-04-19
---

# Plan: Integrasi Google AdMob

**Status:** Planning (April 2026)
**Sumber:** `raw/ads-integration-plan.md`

## Ringkasan

Integrasi iklan Google AdMob ke SakuRapi sebagai sumber pendapatan. Iklan hanya ditampilkan kepada user yang `show_ads = true` pada tabel `profiles`. User bisa membeli fitur "no-ads" secara one-time purchase yang mengubah flag ini ke `false`.

## Keputusan Kunci

- **3 tipe iklan**: Banner, Native, Interstitial
- **Gating**: Riverpod provider `AdsEligibilityProvider` cek Hive-cached `showAds` — tidak ada API call per tampilan
- **One-time purchase** → admin set `show_ads = false` di Supabase dashboard → user tidak pernah lihat iklan lagi
- **AdUnit IDs** flavor-based: dev memakai test ID, prod memakai ID produksi

## Penempatan Iklan

| Tipe | Halaman | Frekuensi |
|------|---------|-----------|
| **Banner** | Dashboard (bawah) + History (atas) | Selalu tampil (jika eligible) |
| **Native** | History list (di antara item) | Setiap 10 item nyata → 1 native ad (`index % 11 == 10`) |
| **Interstitial** | Setelah simpan transaksi | 1x per 5 simpan (counter di Hive, persist across sessions) |

## Arsitektur

```
lib/core/ads/
├── ads_config.dart               ← konstanta: unit IDs, frekuensi, toggle
├── ads_service.dart              ← Singleton: load/show/dispose semua ad type
└── ads_eligibility_provider.dart ← Riverpod provider: cek eligibility

lib/global/widgets/
├── saku_banner_ad_widget.dart    ← reusable banner widget
└── saku_native_ad_card.dart      ← native ad card untuk list
```

## Perubahan Database

```sql
-- profiles
ALTER TABLE profiles ADD COLUMN show_ads BOOLEAN NOT NULL DEFAULT TRUE;
```

## Perubahan Model

`UserModel` tambah field `showAds` (baca dari `map['show_ads']`, default `true`). **Tidak di-include di `toMap()`** — user tidak bisa update sendiri.

## Scope File

- **BARU**: `ads_config.dart`, `ads_service.dart`, `ads_eligibility_provider.dart`
- **BARU**: `saku_banner_ad_widget.dart`, `saku_native_ad_card.dart`
- **UBAH**: `user_model.dart` (field `showAds`), `dashboard_page.dart`, `history_page.dart`, `transaction_form_page.dart`
- **UBAH**: Supabase migration — kolom `profiles.show_ads`

## Halaman Terkait

- [[wiki/entities/dashboard|Dashboard]]
- [[wiki/entities/history|History]]
- [[wiki/entities/transaksi|Transaksi]]
