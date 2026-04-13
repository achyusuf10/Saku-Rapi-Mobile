# Plan: Refactor Breakdown Kategori Reports

## Date
2026-04-13

## Problem

Section/card **Breakdown Kategori** di halaman report saat ini masih punya 2 mode tampilan terpisah:

1. **Pie chart mode**
2. **Linear progress mode**

User ingin mode selector dihapus dan kedua representasi digabung dalam satu struktur tetap:

1. **Pie Chart**
2. **List Linear Progress Kategori**

Dengan aturan:

- hanya **5 kategori teratas** yang tampil eksplisit
- sisanya digabung sebagai **Lainnya**
- aturan ini berlaku **baik untuk pie chart maupun linear list**
- klik item kategori di linear list tetap menuju halaman transaksi kategori seperti sekarang
- item **Lainnya** tetap memakai pola **expand / collapse** seperti sekarang
- hapus seluruh kode mode toggle dan state yang tidak lagi dibutuhkan

---

## Analisa Kondisi Saat Ini

### File yang benar-benar relevan

Walau file yang ditag adalah `lib/features/reports/models/report_page_argument.dart`, refactor ini sebenarnya berada di:

- `lib/features/reports/view/ui/report_page.dart`
- `lib/features/reports/view/widgets/report_category_chart.dart`
- `lib/features/reports/view/widgets/report_category_pie_chart.dart`
- `lib/features/reports/controllers/report_controller.dart`
- `lib/features/reports/repositories/report_repository.dart`

`report_page_argument.dart` hanya berisi argument navigasi awal ke halaman report, dan **tidak mengontrol UI breakdown kategori**.

### Struktur saat ini

Di `report_page.dart`:

- ada Hive key `_kCategoryViewModeKey`
- ada enum `_CategoryViewMode { pieChart, progressBar }`
- `_ReportCategorySectionState` menyimpan `_viewMode`
- `initState()` membaca preferensi mode dari Hive
- `_setViewMode()` menyimpan pilihan user ke Hive
- UI bercabang:
  - `ReportCategoryPieChart(categories: allCategories, ...)`
  - atau `ReportCategoryChart(categories: categories, ...)`

### Temuan penting yang bisa direuse

Refactor ini **tidak perlu ubah contract data** karena:

1. `reportTopCategoriesProvider` sudah menghasilkan **top 5 + bucket `__others__`**
2. `ReportRepository.topNCategories()` sudah menggabungkan kategori sisa ke item **Lainnya**
3. `ReportCategoryChart` sudah mendukung pola klik item biasa vs expand/collapse untuk `__others__`
4. `othersEntry.otherItems` sudah tersedia untuk render sub-list kategori lain

Jadi pekerjaan utamanya fokus ke:

- komposisi ulang UI
- menyederhanakan state
- membuang persistence/toggle yang tidak terpakai lagi

---

## Target UI Baru

Urutan widget di dalam card **Breakdown Kategori**:

1. Header section
2. Toggle **Pengeluaran / Pemasukan**
3. Pie chart
4. List linear progress kategori
5. Expanded sub-list untuk **Lainnya** jika dibuka

### Aturan data yang dipakai

- **Pie chart** memakai `reportTopCategoriesProvider`
- **Linear list** juga memakai `reportTopCategoriesProvider`
- Jika jumlah kategori `<= 5`, maka:
  - tidak ada bucket `Lainnya`
  - tidak ada expanded sub-list
- Jika jumlah kategori `> 5`, maka:
  - item ke-6 dst digabung jadi `Lainnya`
  - `Lainnya` ikut tampil di pie chart
  - `Lainnya` tetap expandable di linear list

### Interaksi

- klik kategori biasa di linear list → navigasi ke `reportCategoryTransactions`
- klik `Lainnya` → expand/collapse
- pie chart menjadi representasi visual statis; interaksi utama tetap di linear list

---

## Rencana Refactor

### 1. Sederhanakan `_ReportCategorySection`

Di `report_page.dart`:

- hapus `_kCategoryViewModeKey`
- hapus enum `_CategoryViewMode`
- hapus field `_viewMode`
- hapus `initState()` yang membaca Hive
- hapus `_setViewMode()`
- hapus percabangan `isPieChart`
- pertahankan `_isOthersExpanded` karena masih dibutuhkan

Setelah refactor, `_ReportCategorySectionState` cukup menyimpan:

- state expand/collapse `Lainnya`

### 2. Ubah komposisi rendering section

Masih di `report_page.dart`:

- gunakan `categories = ref.watch(reportTopCategoriesProvider)`
- gunakan `total = ref.watch(reportCategoryTotalProvider)`
- cari `othersEntry` dari `categories`
- render **pie chart lebih dulu**
- render **linear progress list** tepat di bawah pie chart
- render expanded sub-list untuk `othersEntry.otherItems` jika `_isOthersExpanded == true`

### 3. Batasi pie chart ke top 5 + lainnya

Di `report_category_pie_chart.dart`:

- ubah agar chart menerima list kategori yang sudah dipangkas (`top 5 + others`)
- hapus legend wrap di bawah chart karena fungsi list linear di bawah sekarang sudah menggantikannya
- jika ada callback tap yang tidak lagi dipakai, hapus dari API widget

Ini akan membuat pie chart lebih ringkas dan konsisten dengan list.

### 4. Rapikan linear list

Di `report_category_chart.dart`:

- pertahankan pola row + progress bar + persen
- pertahankan behaviour item `__others__`
- cek parameter yang sudah tidak dipakai setelah refactor
- hapus parameter/logic mati jika ada

Catatan: `rank` saat ini diteruskan ke `_CategoryRow` tapi tidak dipakai untuk render. Jika setelah cek final memang tetap tidak dipakai, parameter ini sebaiknya dihapus.

### 5. Cleanup kode tidak terpakai

Target cleanup:

- import Hive yang tidak lagi dibutuhkan di `report_page.dart`
- private widget `_ViewModeToggle`
- semua comment/docstring yang menyebut dual-mode view bila sudah tidak sesuai
- callback pie chart navigation bila tidak lagi dipakai
- field / helper / branch UI yang tersisa dari mode selector lama

---

## File yang Kemungkinan Berubah

### Wajib

- `lib/features/reports/view/ui/report_page.dart`
- `lib/features/reports/view/widgets/report_category_chart.dart`
- `lib/features/reports/view/widgets/report_category_pie_chart.dart`

### Kemungkinan minor / tidak wajib

- `lib/features/reports/repositories/report_repository.dart`
  - hanya jika perlu penyesuaian helper atau docstring, bukan perubahan logic utama
- `lib/features/reports/controllers/report_controller.dart`
  - kemungkinan hanya doc/comment cleanup bila perlu

### Tidak perlu diubah untuk task ini

- `lib/features/reports/models/report_page_argument.dart`

---

## Risiko / Hal yang Harus Dicek

1. **Total pie chart tetap benar**
   - walau data chart hanya top 5 + lainnya, total persen tetap harus mengacu ke `reportCategoryTotalProvider`

2. **Kategori `Lainnya` tidak boleh navigate**
   - item ini tetap hanya expand/collapse

3. **Nested list `otherItems` tetap pakai amount asli**
   - sub-list kategori lain harus menampilkan jumlah dan persen yang konsisten

4. **State expand tidak bocor antar reload**
   - saat user ganti `expense/income` atau periode, perlu dipastikan state `Lainnya` tidak bikin UI membingungkan

5. **Tidak ada sisa dependency Hive**
   - karena mode selector dihapus, persistence mode chart juga harus ikut hilang total

---

## Implementasi yang Direkomendasikan

Urutan kerja:

1. Refactor `_ReportCategorySection` di `report_page.dart`
2. Sederhanakan `ReportCategoryPieChart`
3. Rapikan `ReportCategoryChart`
4. Hapus widget/helper dead code
5. Jalankan `fvm flutter analyze`
6. Jalankan test terkait reports bila tersedia

---

## Expected Result

Setelah refactor:

- user tidak lagi melihat toggle pie vs linear
- breakdown kategori selalu tampil sebagai:
  - pie chart
  - lalu list linear progress
- pie chart dan list memakai dataset yang sama: **top 5 + lainnya**
- kategori lain tetap bisa dibuka lewat bucket **Lainnya**
- codebase lebih simpel karena seluruh state/persistence mode view dihapus
