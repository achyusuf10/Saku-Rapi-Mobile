# Fastlane Setup - SakuRapi Android

## Prerequisites
- Ruby (>= 2.7) — macOS sudah built-in
- Bundler: `gem install bundler`
- Firebase CLI: `npm install -g firebase-tools`

---

## Initial Setup

```bash
# 1. Masuk ke folder android
cd android

# 2. Install Fastlane & plugins
bundle install
bundle exec fastlane install_plugins
```

---

## Setup Firebase CLI Token

```bash
# Login dan dapatkan CI token
firebase login:ci
```

Browser akan terbuka → login → token muncul di terminal. Lalu:

```bash
# Buat file android/fastlane/.env
echo "FIREBASE_CLI_TOKEN=token_kamu_disini" > fastlane/.env
```

> ⚠️ File `.env` sudah di-.gitignore. JANGAN commit ke repo.

---

## Daftar Lanes

Semua command dijalankan dari folder `android/`:
```bash
cd android
bundle exec fastlane <lane_name>
```

### [1] Build APK — untuk Firebase App Distribution

| Lane | Deskripsi |
|------|-----------|
| `build_apk_dev` | Build release APK flavor **dev** |
| `build_apk_prod` | Build release APK flavor **prod** |

```bash
bundle exec fastlane build_apk_dev
bundle exec fastlane build_apk_prod
```

Output: `build/app/outputs/flutter-apk/app-{flavor}-release.apk`

---

### [2] Build AAB — untuk Play Store

| Lane | Deskripsi |
|------|-----------|
| `build_aab_dev` | Build release AAB flavor **dev** |
| `build_aab_prod` | Build release AAB flavor **prod** |

```bash
bundle exec fastlane build_aab_dev
bundle exec fastlane build_aab_prod
```

Output: `build/app/outputs/bundle/{flavor}Release/app-{flavor}-release.aab`

---

### [3] Upload ke Firebase — tanpa build ulang

Gunakan ini jika APK sudah ter-build sebelumnya dan hanya ingin re-upload.

| Lane | Deskripsi |
|------|-----------|
| `upload_firebase_dev` | Upload APK **dev** yang sudah ada ke Firebase |
| `upload_firebase_prod` | Upload APK **prod** yang sudah ada ke Firebase |

```bash
bundle exec fastlane upload_firebase_dev
bundle exec fastlane upload_firebase_prod
```

---

### [4] Full Deploy — build APK + upload (paling sering dipakai)

| Lane | Deskripsi |
|------|-----------|
| `deploy_firebase_dev` | Build APK **dev** lalu upload ke Firebase |
| `deploy_firebase_prod` | Build APK **prod** lalu upload ke Firebase |

```bash
bundle exec fastlane deploy_firebase_dev
bundle exec fastlane deploy_firebase_prod
```

---

## Release Notes

Edit file `release_notes.txt` di root project **sebelum** distribute:

```
release_notes.txt
─────────────────
Isi dengan changelog, contoh:
- Tambah fitur pembayaran cicilan
- Fix bug saldo tidak update
```

---

## Menambah Destinasi Distribusi Baru (misal: Play Store)

1. Buka [android/fastlane/Fastfile](../android/fastlane/Fastfile)
2. Uncomment `private_lane :upload_play_store`
3. Uncomment public lane `deploy_play_store_prod`
4. Buat service account Play Store dan simpan di `fastlane/play-store-service-account.json`
5. Jalankan `bundle exec fastlane install_plugins` jika ada plugin baru

---

## Struktur File

```
android/
└── fastlane/
    ├── .env              # 🔒 FIREBASE_CLI_TOKEN (git-ignored)
    ├── Appfile           # App identifier
    ├── Fastfile          # Semua lane definitions
    └── Pluginfile        # Fastlane plugins

release_notes.txt         # Release notes (di root project)
```
