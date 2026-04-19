# Plan: Recalculate Budget Usage on Create/Update

> **Status:** Draft
> **Tanggal:** 2026-04-19
> **Scope:** Supabase migration (trigger baru di tabel `budgets`)

---

## Problem

Saat user **membuat** atau **mengubah** budget, transaksi yang sudah ada sebelumnya **tidak dihitung** ke dalam `used_amount` budget tersebut.

### Contoh Reproduksi

1. User punya 10 transaksi "Belanja" dari wallet "Cash" bulan ini
2. User buat budget baru: kategori "Belanja", wallet "Cash", periode bulanan
3. Budget menampilkan `used_amount = 0` → ❌ seharusnya sudah terisi dari 10 transaksi tadi
4. Baru setelah user menambah transaksi baru ke-11, trigger `update_budget_usage` fire → semua 11 transaksi baru terhitung

Hal yang sama terjadi saat update budget:

1. Budget "Belanja" di wallet "Cash" sudah ada → `used_amount = 50.000`
2. User ubah wallet ke "Semua Dompet" → `used_amount` tetap `50.000`
3. Padahal seharusnya `used_amount` harus di-recalculate ulang karena scope wallet berubah (sekarang termasuk transaksi dari Bank Jago, GoPay, dll.)

---

## Root Cause

### Trigger yang ada: `update_budget_usage()`

Trigger ini di-fire **AFTER INSERT/UPDATE/DELETE** pada tabel `transaction_items`, bukan pada tabel `budgets`.

```
transaction_items berubah → trigger fire → recalc SUM → update budgets.used_amount ✅
budgets berubah          → TIDAK ada trigger → used_amount tetap stale ❌
```

Logic recalculation di trigger ini sendiri **sudah benar dan lengkap** — dia melakukan full `SUM()` dari semua `transaction_items` yang match:
- category (termasuk child categories)
- wallet (null = semua dompet)
- date range (`start_date` s/d `end_date`)
- hanya expense (`t.type = 'expense'`)
- bukan settlement (`t.settlement_kind IS NULL`)

Masalahnya bukan di logic perhitungan, tapi **trigger-nya tidak pernah fire** saat budget baru dibuat atau diubah.

### Alur yang Terdampak

| Operasi | Apa yang terjadi | Masalah |
|---------|-----------------|---------|
| **Create budget** (Flutter `INSERT`) | `used_amount` default `0` | Tidak ada trigger, transaksi lama tidak dihitung |
| **Update budget** (Flutter `UPDATE`) | `used_amount` tidak diubah | Jika category/wallet/date berubah, scope baru tidak dihitung |
| **Replace budget** (RPC `replace_budget`) | DELETE lama + INSERT baru, `used_amount = 0` | Sama seperti create — transaksi lama tidak dihitung |
| **Auto-renew** (pg_cron `auto_renew_budgets`) | Clone budget ke periode baru, `used_amount = 0` | Transaksi yang sudah ada di periode baru tidak dihitung |

---

## Solution: Trigger Baru di Tabel `budgets`

Tambah trigger `AFTER INSERT OR UPDATE` pada tabel `budgets` yang melakukan recalculation `used_amount` berdasarkan transaksi yang sudah ada.

### Kenapa Trigger (bukan RPC / Flutter-side)?

| Approach | Pro | Kontra |
|----------|-----|--------|
| **Trigger di `budgets`** ✅ | Atomic, otomatis untuk semua jalur (INSERT, UPDATE, RPC, pg_cron) — zero Flutter change | Harus hati-hati agar tidak infinite loop dengan trigger lain |
| RPC explicit | Bisa dipanggil selektif | Harus dipanggil dari setiap jalur (create, update, replace, auto_renew) — rawan terlewat |
| Flutter-side recalc | Fleksibel | Tidak atomic, race condition jika 2 client, tidak cover pg_cron auto_renew |

### Migration SQL

```sql
-- Migration: recalc_budget_usage_on_upsert

CREATE OR REPLACE FUNCTION public.recalc_budget_usage_on_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.budgets
  SET used_amount = coalesce((
    SELECT sum(ti.amount)
    FROM public.transaction_items ti
    JOIN public.transactions t ON t.id = ti.transaction_id
    WHERE (
      ti.category_id = NEW.category_id
      OR ti.category_id IN (
        SELECT c.id FROM public.categories c
        WHERE c.parent_id = NEW.category_id
      )
    )
      AND t.type = 'expense'
      AND t.settlement_kind IS NULL
      AND (t.date AT TIME ZONE 'Asia/Jakarta')::date
          BETWEEN NEW.start_date AND NEW.end_date
      AND (NEW.wallet_id IS NULL OR t.wallet_id = NEW.wallet_id)
  ), 0)
  WHERE id = NEW.id;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_recalc_budget_on_upsert
  AFTER INSERT OR UPDATE OF category_id, wallet_id, start_date, end_date
  ON public.budgets
  FOR EACH ROW
  EXECUTE FUNCTION recalc_budget_usage_on_change();
```

### Penjelasan Detail

1. **Trigger fires on:**
   - `AFTER INSERT` — budget baru dibuat (dari Flutter, RPC `replace_budget`, atau pg_cron `auto_renew_budgets`)
   - `AFTER UPDATE OF category_id, wallet_id, start_date, end_date` — hanya fire jika kolom yang mempengaruhi scope budget berubah. **Tidak fire** jika hanya `amount`, `carry_forward`, atau `is_recurring` yang berubah (karena itu tidak mempengaruhi scope transaksi).

2. **Logic recalculation identik** dengan yang sudah ada di `update_budget_usage()`:
   - Join `transaction_items` ↔ `transactions`
   - Filter: `category_id` (termasuk child), `expense` only, bukan settlement, date range, wallet filter
   - Full `SUM()` — bukan increment

3. **Tidak ada infinite loop** karena:
   - Trigger ini fire pada `budgets` INSERT/UPDATE
   - Dia melakukan `UPDATE budgets SET used_amount = ...`
   - Tapi `UPDATE OF category_id, wallet_id, start_date, end_date` tidak termasuk `used_amount`, jadi trigger tidak fire ulang
   - Untuk INSERT, trigger fire sekali dan selesai

4. **Cakupan otomatis:**
   - ✅ `createBudget()` → Flutter INSERT → trigger fire → recalc
   - ✅ `updateBudget()` → Flutter UPDATE (jika scope berubah) → trigger fire → recalc
   - ✅ `replaceBudget()` → RPC DELETE + INSERT → trigger fire pada INSERT → recalc
   - ✅ `auto_renew_budgets()` → pg_cron INSERT budget baru → trigger fire → recalc

### Perlu Diperiksa: Loop Trigger Safety

`update_budget_usage()` (trigger di `transaction_items`) melakukan `UPDATE budgets SET used_amount = ...`. Ini akan **meng-update kolom `used_amount`**, yang BUKAN di dalam daftar `UPDATE OF category_id, wallet_id, start_date, end_date`. Jadi trigger baru **TIDAK akan fire** dari update tersebut. ✅ Aman.

Sebaliknya, `recalc_budget_usage_on_change()` melakukan `UPDATE budgets SET used_amount = ...`, yang juga bukan kolom yang di-watch. Jadi **TIDAK ada siklus**. ✅ Aman.

---

## Scope Perubahan

### Supabase

| File | Perubahan |
|------|-----------|
| Migration SQL baru | Tambah function `recalc_budget_usage_on_change()` + trigger `trg_recalc_budget_on_upsert` |

### Flutter

**Tidak ada perubahan Flutter yang diperlukan.** Trigger berjalan di database level — semua jalur (INSERT, UPDATE, RPC, pg_cron) otomatis ter-cover tanpa modifikasi kode client.

---

## Testing Scenario

| # | Skenario | Expected Result |
|---|----------|-----------------|
| 1 | Buat budget baru (Belanja, Cash, bulan ini) — sudah ada 5 transaksi matching | `used_amount` langsung terisi dengan sum 5 transaksi |
| 2 | Ubah wallet dari "Cash" ke "Semua Dompet" | `used_amount` di-recalc termasuk transaksi dari semua dompet |
| 3 | Ubah wallet dari "Semua Dompet" ke "Bank Jago" | `used_amount` di-recalc hanya untuk transaksi Bank Jago |
| 4 | Ubah kategori dari "Belanja" ke "Makan" | `used_amount` di-recalc untuk kategori Makan (+ child-nya) |
| 5 | Ubah date range (start/end) | `used_amount` di-recalc untuk range baru |
| 6 | Replace budget via RPC | Budget baru langsung punya `used_amount` yang benar |
| 7 | Auto-renew (pg_cron) clone budget ke periode baru | Budget baru di periode baru langsung punya `used_amount` dari transaksi yang ada di periode tersebut |
| 8 | Ubah `amount` saja (bukan scope) | Trigger TIDAK fire — `used_amount` tetap (benar, karena scope tidak berubah) |
| 9 | Tambah transaksi baru setelah budget ada | Trigger lama `update_budget_usage` tetap bekerja normal |
