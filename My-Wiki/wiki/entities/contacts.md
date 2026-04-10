---
title: "Contacts"
type: entity
tags: [kontak, hutang, piutang, phonebook, upsert]
sources: [raw/docs/02_DATABASE.md]
created: 2026-04-10
updated: 2026-04-10
---

# Contacts

> Halaman ini mendokumentasikan entitas **Contacts** di SakuRapi — kontak yang digunakan sebagai referensi dalam transaksi hutang dan piutang.

---

## Schema: Tabel `contacts`

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | default gen_random_uuid() |
| user_id | uuid FK | owner |
| name | text not null | nama kontak |
| phone | text nullable | nomor telepon (opsional) |
| created_at | timestamptz | default now() |
| updated_at | timestamptz | auto update via trigger `set_updated_at()` |

**Constraint:**
- `name` wajib tidak kosong
- RLS: user hanya bisa mengakses data miliknya sendiri

**Index:** `contacts(user_id, name)` — untuk pencarian kontak per user.

---

## Tujuan

Tabel `contacts` berfungsi sebagai **referensi kontak** untuk transaksi hutang (`debt`) dan piutang (`loan`). Ketika user membuat transaksi hutang/piutang, kontak yang dipilih disimpan melalui kolom `transactions.contact_id` (FK ke `contacts.id`).

Selain itu, field `transactions.with_person` (text) tetap menyimpan nama orang sebagai string — memastikan data transaksi tetap utuh meskipun kontak diedit atau dihapus di kemudian hari.

---

## Mekanisme Upsert dari Phonebook

Kontak di-upsert ke database dari phonebook device user melalui RPC:

```
upsert_contact(p_name, p_phone?) → uuid
```

### Alur Kerja

1. User membuka form transaksi hutang/piutang
2. User memilih kontak via **contact picker** (dari phonebook device)
3. Aplikasi memanggil RPC `upsert_contact` dengan nama dan nomor telepon
4. RPC melakukan INSERT atau UPDATE (berdasarkan kecocokan nama + user_id)
5. UUID kontak dikembalikan dan disimpan di `transactions.contact_id`

### Keamanan Data

- Data kontak **aman** meskipun kontak diedit setelah transaksi dibuat
- Field `transactions.with_person` menyimpan snapshot nama pada saat transaksi, independen dari tabel `contacts`
- `contact_id` digunakan untuk **grouping dan query** (misal: ringkasan hutang/piutang per orang)

---

## Penggunaan di Fitur Lain

### Hutang/Piutang
- Kontak digunakan sebagai referensi di transaksi `debt` dan `loan`
- RPC query hutang/piutang di-group berdasarkan `contact_id`:
  - `get_debt_loan_summary` — ringkasan per orang
  - `get_debt_loan_transactions_by_person` — detail per orang
- Lihat: [[wiki/entities/hutang-piutang|Hutang Piutang]]

### Form Transaksi
- **Contact picker** tersedia di form transaksi saat tipe adalah `debt` atau `loan`
- User bisa memilih dari kontak yang sudah tersimpan atau menambah baru dari phonebook

---

## Halaman Terkait

- [[wiki/entities/database-schema|Database Schema]]
- [[wiki/entities/hutang-piutang|Hutang Piutang]]
- [[wiki/entities/transaksi|Transaksi]]
