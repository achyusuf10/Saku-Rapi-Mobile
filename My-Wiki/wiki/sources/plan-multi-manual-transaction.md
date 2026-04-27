---
title: "Plan: Multi Transaksi Manual (Expense & Income)"
type: source
tags: [transaksi, form, batch, rpc, multi-item, flutter, supabase]
sources: [raw/docs/MULTI_MANUAL_TRANSACTION_PLAN.md]
created: 2026-04-27
updated: 2026-04-27
---

# Plan: Multi Transaksi Manual

Ringkasan untuk wiki. **Dokumen lengkap + checklist:** [[raw/docs/MULTI_MANUAL_TRANSACTION_PLAN|MULTI_MANUAL_TRANSACTION_PLAN.md]].

## Apa itu

Pada form **buat** transaksi, tab **Pengeluaran** dan **Pemasukan**: mode **Satu transaksi** (existing) atau **Multi transaksi** — beberapa transaksi sekaligus, satu RPC batch atomik (`create_transactions_batch`).

## Aturan utama

| Item | Keputusan |
|------|-----------|
| Tab | Hanya expense & income |
| Edit | Multi transaksi hanya **create** |
| Batch max | **10** transaksi (RPC + client + repo) |
| Sukses | Pesan menyertakan **jumlah** transaksi tersimpan (dari response RPC) |
| Multi-item | Per entry: **satu item** default = `TransactionAmountSection`; tap **Tambah item** = sama seperti form tunggal → UI multi-item |

## UX per entry (selaras form tunggal)

1. Jika `items.length == 1`: tampil **`TransactionAmountSection`** + di bawahnya **`TransactionMultiItemSection`** yang hanya menampilkan chip **Tambah item**.
2. Setelah `addManualMultiItem`: `items.length > 1` → section multi-item penuh (grand total, reorder, `TransactionItemRow`, dll.).
3. Nominal satu item: `setManualMultiEntryTotalAmount` menyamakan `totalAmount` dan `items[0].amount` (mirror `setTotalAmount`).

## Implementasi singkat

- **Supabase:** `public.create_transactions_batch(p_transactions jsonb)` → `transaction_ids` + `count`; validasi cap 10 elemen.
- **Flutter:** `TransactionFormMultiManualCoordinator`, `ManualTransactionEntryModel`, `TransactionManualMultiEntryCard`, `TransactionMultiItemSection(manualMultiEntryIndex: i)`.
- **Tes:** `transaction_form_controller_test` (batch, total amount, add item); `transaction_multi_item_section_test` (satu item = chip saja).

## Tautan

- [[wiki/entities/transaksi|Entitas Transaksi]] — form & multi-item
- [[raw/docs/MULTI_MANUAL_TRANSACTION_PLAN|Rencana lengkap (raw)]]
