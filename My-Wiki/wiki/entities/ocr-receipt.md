---
title: "OCR Receipt"
type: entity
tags: [ocr, receipt, ai-parse, gemini, groq, ml-kit, edge-function, camera]
sources: [raw/docs/prd/18_OCR_RECEIPT.md, raw/docs/prd/19_PARSING_DICTIONARY.md]
created: 2026-04-10
updated: 2026-04-10
---

# OCR Receipt

## Deskripsi

Fitur OCR Receipt memungkinkan pengguna memfoto struk belanja dan secara otomatis mengekstrak data transaksi. Gambar diproses melalui pipeline berlapis: AI cloud parsing (Gemini/Groq), ML Kit on-device, dan local parser sebagai fallback terakhir.

---

## Fitur & Aturan Utama

- Sumber gambar: **Camera** atau **Gallery**
- Gambar di-crop menggunakan package **croppy**, lalu dikompresi ≤ **500 KB**
- Response AI menyertakan **items array** dengan detail per item
- **Auto-balance**: jika `itemsSum ≠ grandTotal`, sistem otomatis menambah item penyeimbang
- Foto struk otomatis di-set sebagai **attachment** transaksi via `pendingOcrImageFile`

### Item Fields

| Field | Keterangan |
|-------|------------|
| `name` | Nama item |
| `qty` | Jumlah unit |
| `unitPrice` | Harga per unit |
| `subtotal` | `qty × unitPrice` |
| `categoryId` | Saran kategori |

---

## Cara Kerja

### Pipeline

```
Camera/Gallery → Crop (croppy) → Compress ≤500KB → Base64
    → Edge Function ai-parse mode='ocr'
        → Gemini (primary)
        → Groq (failover)
    → ML Kit on-device (fallback)
    → OcrLocalParser (fallback terakhir)
```

### Auto-Balance Logic

Ketika total item tidak sesuai dengan grand total struk:

| Kondisi | Aksi |
|---------|------|
| `itemsSum < grandTotal` | Tambah item **"Item lainnya"** dengan selisih sebagai subtotal |
| `itemsSum > grandTotal` | Tambah item **"Diskon/potongan"** dengan selisih negatif |

### Error States

| Error Code | Keterangan |
|------------|------------|
| `NO_TEXT` | Tidak ada teks terdeteksi di gambar |
| `NOT_TRANSACTION` | Teks terdeteksi tapi bukan struk transaksi |
| `PARSE_FAILED` | Parsing gagal setelah semua fallback |

### OcrLocalParser (Fallback Lokal)

Parser on-device yang mengekstrak data dari raw text ML Kit:

- **Merchant**: Diambil dari **3 baris pertama** teks
- **Grand total**: Dicari dari **bawah ke atas** (angka terbesar di bagian bawah struk)
- **Items**: Pola regex untuk mendeteksi baris dengan nama, quantity, dan harga
- **Date**: Parsing tanggal dari berbagai format Indonesia

### Attachment Otomatis

File gambar yang sudah di-crop disimpan di `pendingOcrImageFile` dan secara otomatis dijadikan attachment transaksi saat form di-submit.

---

## Halaman Terkait

- [[wiki/entities/voice-input|Voice Input]]
- [[wiki/entities/text-input|Text Input]]
- [[wiki/entities/history|History]]
- [[wiki/concepts/aturan-keuangan|Aturan Keuangan]]
- [[wiki/sources/prd-sakurapi-v7|PRD SakuRapi v7.0]]
