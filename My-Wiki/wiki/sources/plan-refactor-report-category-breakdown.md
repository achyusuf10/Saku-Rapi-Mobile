---
title: "Plan: Refactor Breakdown Kategori Reports"
type: source
tags: [reports, breakdown, pie-chart, progress-bar, ui, refactor]
source_file: raw/docs/plan-refactor-report-category-breakdown-combined-chart.md
created: 2026-04-13
updated: 2026-04-13
---

# Plan: Refactor Breakdown Kategori Reports — Ringkasan

> Sumber: `raw/docs/plan-refactor-report-category-breakdown-combined-chart.md`  
> Status: **Selesai diimplementasi** (April 2026)

---

## Apa yang Berubah

Section **Breakdown Kategori** di halaman report disederhanakan dari dua mode terpisah menjadi satu alur tetap:

1. **Pie chart**
2. **List linear progress kategori**

User tidak lagi memilih mode tampilan chart.

---

## Keputusan UI

| Area | Keputusan |
|---|---|
| Mode chart | Toggle pie/list **dihapus** |
| Dataset chart | **Top 5 kategori + bucket `Lainnya`** |
| Pie chart | Selalu tampil di atas |
| List kategori | Selalu tampil di bawah pie chart |
| Item `Lainnya` | Tetap **expand / collapse** |
| Navigasi | Klik kategori biasa → `report_category_transactions_page` |
| Navigasi `Lainnya` | **Tidak navigate**, hanya expand/collapse |

---

## Cleanup Code

- Hapus Hive persistence untuk preferensi chart mode
- Hapus enum `_CategoryViewMode`
- Hapus private widget `_ViewModeToggle`
- Hapus legend pie chart terpisah karena sudah digantikan list linear di bawahnya
- Rapikan `ReportCategoryChart` dengan menghapus parameter `rank` yang tidak dipakai

---

## Files Diubah

| File | Perubahan |
|---|---|
| `lib/features/reports/view/ui/report_page.dart` | Gabungkan pie chart + linear list dalam satu section, hapus mode toggle |
| `lib/features/reports/view/widgets/report_category_pie_chart.dart` | Sederhanakan pie chart, hapus legend dan callback tap |
| `lib/features/reports/view/widgets/report_category_chart.dart` | Cleanup parameter/komentar yang tidak dibutuhkan |
| `test/features/reports/report_test.dart` | Tambah assertion untuk contract top-5 + `Lainnya` |

---

## Hasil Akhir

Breakdown kategori sekarang lebih sederhana dan konsisten:

- visual overview tetap ada lewat pie chart
- detail kategori tetap terbaca lewat progress list
- kategori minor tetap diringkas sebagai **Lainnya**
- drill-down transaksi kategori tetap tersedia tanpa membawa kompleksitas mode selector

---

## Lihat Juga

- [[wiki/entities/reports|Reports]] — halaman entitas yang sudah diperbarui
- [[wiki/sources/redesign-ui-ux|Redesign UI/UX (Sumber)]]
