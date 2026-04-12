class SakuDateUtils {
  const SakuDateUtils._();

  static final RegExp _dateOnlyPattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

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

  static DateTime? parseOptionalTimestamp(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value.toLocal();

    final raw = value.toString();
    if (raw.isEmpty) return null;

    return DateTime.parse(raw).toLocal();
  }

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

  static String formatTimestamp(DateTime value) {
    return value.toUtc().toIso8601String();
  }

  static String? formatOptionalTimestamp(DateTime? value) {
    if (value == null) return null;
    return formatTimestamp(value);
  }

  static String formatDate(DateTime value) {
    final local = normalizeLocalDate(value);
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  static String? formatOptionalDate(DateTime? value) {
    if (value == null) return null;
    return formatDate(value);
  }

  static DateTime normalizeLocalDate(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static DateTime todayLocal() {
    return normalizeLocalDate(DateTime.now());
  }

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
