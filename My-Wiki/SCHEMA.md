# SakuRapi Wiki — Schema & Panduan LLM

> File ini adalah panduan utama bagi LLM yang mengelola wiki ini.
> Baca file ini **selalu** di awal setiap sesi sebelum melakukan operasi apapun.

## Tentang Wiki Ini

Wiki ini adalah knowledge base proyek **SakuRapi** — aplikasi keuangan pribadi berbasis Flutter untuk pasar Indonesia. Wiki dikelola sepenuhnya oleh LLM. Manusia menyediakan sumber, mengarahkan analisis, dan mengajukan pertanyaan. LLM menulis, memperbarui, dan merawat semua halaman wiki.

**Bahasa**: Semua halaman wiki ditulis dalam **Bahasa Indonesia**. Istilah teknis boleh tetap dalam bahasa Inggris jika lebih umum digunakan (misalnya: "state management", "repository pattern", "edge function").

## Struktur Direktori

```
My-Wiki/
├── SCHEMA.md          # File ini — panduan LLM
├── index.md           # Katalog semua halaman wiki
├── log.md             # Log kronologis operasi
├── raw/               # Sumber mentah (JANGAN diubah LLM)
│   ├── docs/          # Dokumen internal (PRD, desain, meeting notes)
│   ├── articles/      # Artikel eksternal, blog post, referensi
│   ├── feedback/      # Feedback pengguna, review, hasil riset UX
│   ├── competitors/   # Analisis kompetitor, screenshot, catatan
│   └── assets/        # Gambar dan lampiran
├── wiki/              # Halaman wiki (dikelola LLM)
│   ├── entities/      # Halaman entitas (fitur, layanan, tools, orang)
│   ├── concepts/      # Halaman konsep (arsitektur, pola, domain knowledge)
│   ├── sources/       # Ringkasan sumber
│   └── analysis/      # Analisis, perbandingan, sintesis
└── .obsidian/         # Konfigurasi Obsidian
```

## Aturan Dasar

1. **raw/ adalah immutable.** LLM tidak pernah mengubah, menghapus, atau memindahkan file di `raw/`. Sumber mentah adalah ground truth.
2. **wiki/ sepenuhnya milik LLM.** LLM bebas membuat, mengubah, dan menghapus halaman di `wiki/`.
3. **index.md dan log.md** harus selalu diperbarui setiap operasi.
4. **Gunakan [[wikilinks]]** untuk cross-reference antar halaman. Format: `[[wiki/entities/nama-halaman|Nama Tampilan]]`.
5. **Satu halaman, satu topik.** Jangan gabungkan beberapa entitas/konsep dalam satu file.

## Format Halaman Wiki

Setiap halaman wiki harus memiliki YAML frontmatter:

```yaml
---
title: "Judul Halaman"
type: entity | concept | source | analysis
tags: [tag1, tag2]
sources: [raw/docs/nama-file.md]      # sumber yang dikutip
created: 2026-04-10
updated: 2026-04-10
---
```

### Tipe Halaman

| Tipe | Lokasi | Deskripsi |
|------|--------|-----------|
| **entity** | `wiki/entities/` | Fitur, layanan, tools, atau komponen spesifik. Contoh: `wallet.md`, `supabase.md`, `riverpod.md` |
| **concept** | `wiki/concepts/` | Pola arsitektur, domain knowledge, prinsip. Contoh: `3-file-pattern.md`, `financial-guardrails.md` |
| **source** | `wiki/sources/` | Ringkasan satu sumber. Satu file per sumber. Nama file = nama sumber yang di-slugify |
| **analysis** | `wiki/analysis/` | Perbandingan, evaluasi, sintesis lintas sumber. Contoh: `perbandingan-state-management.md` |

### Template Ringkasan Sumber (`wiki/sources/`)

```markdown
---
title: "Judul Sumber"
type: source
tags: []
sources: [raw/docs/nama-file.md]
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# Judul Sumber

**Jenis**: artikel / dokumen internal / feedback / catatan meeting / dll
**Tanggal sumber**: YYYY-MM-DD (jika diketahui)
**Link asli**: (jika ada)

## Ringkasan

(Ringkasan 3-5 paragraf)

## Poin Kunci

- Poin 1
- Poin 2

## Relevansi untuk SakuRapi

(Bagaimana sumber ini relevan dengan proyek)

## Halaman Terkait

- `[[wiki/entities/xxx|XXX]]`
- `[[wiki/concepts/yyy|YYY]]`
```

## Operasi

### 1. Ingest (Menelan Sumber Baru)

Ketika pengguna menambahkan sumber baru ke `raw/`:

1. **Baca** sumber mentah secara lengkap
2. **Diskusikan** temuan kunci dengan pengguna
3. **Buat** halaman ringkasan di `wiki/sources/`
4. **Perbarui** halaman entity/concept yang terkait di `wiki/`
   - Jika halaman belum ada, buat baru
   - Jika sudah ada, tambahkan/perbarui informasi, catat jika ada kontradiksi
5. **Perbarui** `index.md` — tambahkan entry baru
6. **Tambahkan** entry ke `log.md`

### 2. Query (Menjawab Pertanyaan)

1. **Baca** `index.md` untuk menemukan halaman yang relevan
2. **Baca** halaman-halaman wiki yang relevan
3. **Sintesis** jawaban dengan kutipan ke halaman wiki
4. **Jika jawaban bernilai tinggi**, tawarkan untuk menyimpannya sebagai halaman analisis baru di `wiki/analysis/`
5. **Jika ada gap**, sarankan sumber baru yang bisa dicari

### 3. Lint (Pemeliharaan)

Ketika pengguna meminta health-check:

1. Cari **kontradiksi** antar halaman
2. Cari **halaman orphan** (tidak ada inbound link)
3. Cari **konsep yang disebut** tapi belum punya halaman sendiri
4. Cari **informasi usang** yang sudah di-supersede sumber baru
5. Sarankan **cross-reference** yang hilang
6. Sarankan **pertanyaan baru** yang bisa dieksplorasi
7. Laporkan hasilnya dan perbarui `log.md`

## Konvensi Penamaan File

- Gunakan **kebab-case** untuk nama file: `wallet-management.md`, `riverpod-state.md`
- Nama file harus deskriptif dan singkat
- Tidak pakai angka prefix kecuali untuk urutan yang bermakna

## Konvensi Cross-Reference

- Gunakan Obsidian wikilinks: `[[wiki/entities/wallet|Wallet]]`
- Setiap halaman harus punya minimal 1 inbound link (kecuali halaman baru)
- Bagian "Halaman Terkait" wajib di setiap halaman

## Konteks Proyek SakuRapi

Untuk referensi arsitektur dan aturan teknis SakuRapi, lihat:
- `My-Wiki/wiki/entities/database-schema.md` — skema **terkini** (termasuk katalog kategori 2026-04)
- `My-Wiki/wiki/entities/categories.md` — kategori global, `user_category_hidden`, RPC, migrasi
- `supabase/migrations/` (root repo) — *DDL* aktual
- `My-Wiki/raw/docs/02_DATABASE.md` — *baseline* v6.4 (bisa usang di bagian kategori)
- `My-Wiki/raw/docs/prd/00_INDEX.md` — PRD
- `My-Wiki/raw/docs/03_COPILOT_RULES.md` — implementasi
- `docs/00_SakuRapi_Coding_Rules.md` — coding rules (jika dipakai di monorepo)

(Sebagian path mengacu file di dalam repo `app_saku_rapi/`, bukan hanya folder `My-Wiki/`.)
