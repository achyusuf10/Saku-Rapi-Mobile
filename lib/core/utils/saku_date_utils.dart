/// Central helper untuk semua operasi parse, serialize, dan query-range tanggal di SakuRapi.
///
/// Dua jenis field yang dibedakan secara tegas:
/// - **Timestamp UTC** — titik waktu spesifik, disimpan sebagai UTC ISO 8601 penuh
///   (contoh: `transactions.date`, `investment_transactions.date`, `created_at`, `updated_at`, `fetched_at`)
/// - **Calendar date** — tanggal kalender murni tanpa jam, disimpan sebagai `YYYY-MM-DD`
///   (contoh: `transactions.due_date`, `budgets.start_date`, `budgets.end_date`)
///
/// **Aturan penting:**
/// - Seluruh parsing/serialization domain date di model, datasource, RPC payload, dan filter query
///   wajib melewati class ini.
/// - Extension tanggal (`date_time_ext.dart`, `string_ext.dart`) hanya untuk formatting UI.
/// - Jangan menambah `DateTime.parse()` mentah, `.toIso8601String()` mentah, offset timezone manual,
///   atau `substring(0, 10)` untuk logic domain tanggal di luar class ini.
class SakuDateUtils {
  const SakuDateUtils._();

  static final RegExp _dateOnlyPattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  /// Memparsing nilai timestamp wajib dari Supabase menjadi [DateTime] local.
  ///
  /// Melempar [FormatException] jika [value] null, kosong, atau bukan format tanggal/datetime valid.
  ///
  /// Digunakan untuk field **point-in-time UTC** seperti `transactions.date`,
  /// `investment_transactions.date`, `created_at`, `updated_at`, `fetched_at`.
  ///
  /// Contoh:
  /// ```dart
  /// final date = SakuDateUtils.parseRequiredTimestamp(map['date'], fieldName: 'date');
  /// ```
  static DateTime parseRequiredTimestamp(
    Object? value, {
    String fieldName = 'timestamp',
  }) {
    final parsed = parseOptionalTimestamp(value);
    if (parsed == null) {
      throw FormatException('Invalid $fieldName: $value');
    }
    return parsed;
  }

  /// Memparsing nilai timestamp opsional dari Supabase menjadi [DateTime] local.
  ///
  /// Mengembalikan `null` jika [value] null atau string kosong.
  /// Jika [value] sudah bertipe [DateTime], langsung dikonversi ke local.
  /// Untuk string, di-parse lalu dikonversi ke local timezone device user.
  ///
  /// Digunakan untuk field **point-in-time UTC** opsional.
  ///
  /// Contoh:
  /// ```dart
  /// final date = SakuDateUtils.parseOptionalTimestamp(map['updated_at']);
  /// ```
  static DateTime? parseOptionalTimestamp(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value.toLocal();

    final raw = value.toString();
    if (raw.isEmpty) return null;

    return DateTime.parse(raw).toLocal();
  }

  /// Memparsing nilai calendar date wajib dari Supabase menjadi [DateTime] lokal tanpa jam.
  ///
  /// Melempar [FormatException] jika [value] null, kosong, atau bukan format valid.
  ///
  /// Digunakan untuk field **calendar-only** seperti `transactions.due_date`,
  /// `budgets.start_date`, `budgets.end_date`.
  ///
  /// Contoh:
  /// ```dart
  /// final dueDate = SakuDateUtils.parseRequiredDate(map['due_date'], fieldName: 'due_date');
  /// ```
  static DateTime parseRequiredDate(
    Object? value, {
    String fieldName = 'date',
  }) {
    final parsed = parseOptionalDate(value);
    if (parsed == null) {
      throw FormatException('Invalid $fieldName: $value');
    }
    return parsed;
  }

  /// Memparsing nilai calendar date opsional dari Supabase menjadi [DateTime] lokal tanpa jam.
  ///
  /// Mengembalikan `null` jika [value] null atau string kosong.
  /// - Untuk format `YYYY-MM-DD`: di-parse langsung tanpa konversi timezone sehingga tidak ada drift.
  /// - Untuk format lain (termasuk `timestamptz`): ambil tanggal lokal-nya dengan [normalizeLocalDate].
  ///
  /// Digunakan untuk field **calendar-only** opsional.
  ///
  /// Contoh:
  /// ```dart
  /// final dueDate = SakuDateUtils.parseOptionalDate(map['due_date']);
  /// ```
  static DateTime? parseOptionalDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return normalizeLocalDate(value);

    final raw = value.toString();
    if (raw.isEmpty) return null;

    if (_dateOnlyPattern.hasMatch(raw)) {
      final parts = raw.split('-');
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    }

    return normalizeLocalDate(DateTime.parse(raw));
  }

  /// Memparsing nilai datetime fleksibel wajib dari hasil AI menjadi [DateTime] lokal.
  ///
  /// Melempar [FormatException] jika [value] null, kosong, atau bukan format valid.
  ///
  /// Lihat [parseOptionalFlexibleLocalDateTime] untuk detail format yang didukung.
  ///
  /// Contoh:
  /// ```dart
  /// final date = SakuDateUtils.parseFlexibleLocalDateTime(aiResult['date']);
  /// ```
  static DateTime parseFlexibleLocalDateTime(
    Object? value, {
    String fieldName = 'datetime',
  }) {
    final parsed = parseOptionalFlexibleLocalDateTime(value);
    if (parsed == null) {
      throw FormatException('Invalid $fieldName: $value');
    }
    return parsed;
  }

  /// Memparsing nilai datetime fleksibel opsional dari hasil AI/voice/OCR menjadi [DateTime] lokal.
  ///
  /// Format yang didukung:
  /// - `YYYY-MM-DD` — hanya tanggal, dikembalikan tanpa jam (midnight lokal)
  /// - `YYYY-MM-DDTHH:mm:ss` — tanggal dan jam lokal eksplisit dari AI (tanpa timezone suffix)
  /// - `YYYY-MM-DDTHH:mm:ssZ` atau format ISO lain — di-parse lalu di-convert ke lokal
  ///
  /// Mengembalikan `null` jika [value] null atau string kosong.
  ///
  /// Digunakan **khusus untuk field prefill AI** di [VoiceParseResultModel] dan [OcrParseResultModel].
  /// Jangan dipakai untuk field biasa dari Supabase — gunakan [parseOptionalTimestamp] atau
  /// [parseOptionalDate] sesuai jenis field-nya.
  ///
  /// Contoh:
  /// ```dart
  /// final date = SakuDateUtils.parseOptionalFlexibleLocalDateTime(aiResult['date']);
  /// // '2026-04-12'              → DateTime(2026, 4, 12)
  /// // '2026-04-12T19:30:00'     → DateTime(2026, 4, 12, 19, 30) di local timezone
  /// // null atau ''              → null
  /// ```
  static DateTime? parseOptionalFlexibleLocalDateTime(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value.toLocal();
    }

    final raw = value.toString();
    if (raw.isEmpty) {
      return null;
    }

    if (_dateOnlyPattern.hasMatch(raw)) {
      final parts = raw.split('-');
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    }

    return DateTime.parse(raw).toLocal();
  }

  /// Mengserialize [DateTime] menjadi UTC ISO 8601 string untuk dikirim ke Supabase.
  ///
  /// Digunakan untuk field **point-in-time timestamp** seperti `p_date` di RPC transaksi,
  /// investasi, settlement, dan adjustment.
  ///
  /// Contoh:
  /// ```dart
  /// final iso = SakuDateUtils.formatTimestamp(transaction.date);
  /// // → '2026-04-12T12:30:00.000Z'
  /// ```
  static String formatTimestamp(DateTime value) {
    return value.toUtc().toIso8601String();
  }

  /// Mengserialize [DateTime]? opsional menjadi UTC ISO 8601 string, atau `null` jika input null.
  ///
  /// Contoh:
  /// ```dart
  /// final iso = SakuDateUtils.formatOptionalTimestamp(transaction.dueDate); // bisa null
  /// ```
  static String? formatOptionalTimestamp(DateTime? value) {
    if (value == null) return null;
    return formatTimestamp(value);
  }

  /// Mengserialize [DateTime] menjadi string `YYYY-MM-DD` untuk field calendar-only di Supabase.
  ///
  /// Selalu mengambil tanggal dalam local timezone agar tidak terjadi timezone drift
  /// (misalnya UTC `2026-04-11T23:00:00Z` → lokal `2026-04-12` di WIB).
  ///
  /// Digunakan untuk field **calendar-only** seperti `p_due_date`, `start_date`, `end_date`.
  ///
  /// Contoh:
  /// ```dart
  /// final dateStr = SakuDateUtils.formatDate(transaction.dueDate!);
  /// // → '2026-04-12'
  /// ```
  static String formatDate(DateTime value) {
    final local = normalizeLocalDate(value);
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  /// Mengserialize [DateTime]? opsional menjadi `YYYY-MM-DD` string, atau `null` jika input null.
  ///
  /// Contoh:
  /// ```dart
  /// final dateStr = SakuDateUtils.formatOptionalDate(transaction.dueDate);
  /// ```
  static String? formatOptionalDate(DateTime? value) {
    if (value == null) return null;
    return formatDate(value);
  }

  /// Menormalisasi [DateTime] ke tanggal lokal tanpa komponen jam (midnight lokal).
  ///
  /// Berguna untuk grouping harian, perbandingan tanggal, dan memastikan tanggal kalender
  /// tidak membawa jam dari timezone yang berbeda.
  ///
  /// Contoh:
  /// ```dart
  /// final today = SakuDateUtils.normalizeLocalDate(DateTime.now());
  /// // → DateTime(2026, 4, 12, 0, 0, 0) di local timezone
  /// ```
  static DateTime normalizeLocalDate(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  /// Mengembalikan tanggal hari ini di local timezone user, tanpa komponen jam.
  ///
  /// Contoh:
  /// ```dart
  /// final today = SakuDateUtils.todayLocal();
  /// // → DateTime(2026, 4, 12) di local timezone
  /// ```
  static DateTime todayLocal() {
    return normalizeLocalDate(DateTime.now());
  }

  /// Mengkonversi rentang tanggal lokal user menjadi pasangan UTC boundary string
  /// yang aman dipakai untuk filter kolom `timestamptz` di Supabase.
  ///
  /// Menggunakan pola `gte(startUtc)` + `lt(endUtcExclusive)` agar transaksi pada hari
  /// terakhir tidak terpotong oleh offset timezone.
  ///
  /// - [startDate] — tanggal awal rentang (local user)
  /// - [endDate] — tanggal akhir rentang inklusif (local user)
  ///
  /// Digunakan di datasource untuk filter harian/bulanan/rentang custom pada
  /// `transactions.date`, `investment_transactions.date`, dll.
  ///
  /// Contoh:
  /// ```dart
  /// final range = SakuDateUtils.localDayRangeUtc(
  ///   startDate: DateTime(2026, 4, 1),
  ///   endDate: DateTime(2026, 4, 30),
  /// );
  /// query
  ///   .gte('date', range.startUtc)
  ///   .lt('date', range.endUtcExclusive);
  /// ```
  static ({String startUtc, String endUtcExclusive}) localDayRangeUtc({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final localStart = normalizeLocalDate(startDate);
    final localEndExclusive = normalizeLocalDate(
      endDate,
    ).add(const Duration(days: 1));

    return (
      startUtc: formatTimestamp(localStart),
      endUtcExclusive: formatTimestamp(localEndExclusive),
    );
  }
}
