import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:intl/intl.dart';

extension DateTimeNullExtension on DateTime? {
  /// Default format 'yyyy-MM-dd'
  /// Converts the [DateTime] object to a formatted string.
  ///
  /// The [outputDateFormat] parameter specifies the format of the output string.
  /// The default format is 'yyyy-MM-dd'.
  ///
  /// Returns the formatted string representation of the [DateTime] object.
  /// If the [DateTime] object is null, it returns '-'.
  String extToFormattedString({
    String outputDateFormat = 'yyyy-MM-dd',
    String? outputLocale,
  }) {
    if (this == null) return '-';
    return DateFormat(
      outputDateFormat,
      outputLocale ?? appContext?.locale.languageCode,
    ).format(this ?? DateTime(1900, 1, 1, 1, 1));
  }

  /// Converts a [DateTime] object to a formatted time string.
  ///
  /// The [formatToTime] parameter specifies the desired format of the time string.
  /// The default format is "HH:mm".
  ///
  /// Returns the formatted time string.
  /// If the [DateTime] object is null, returns a dash ("-").
  String extToTimeString({String formatToTime = 'HH:mm'}) {
    if (this == null) return '-';
    return DateFormat(
      formatToTime,
      appContext?.locale.languageCode,
    ).format(this ?? DateTime.now());
  }

  /// Converts the [DateTime] object to a formatted string in the format "dd MMMM yyyy".
  /// If the [DateTime] object is null, it returns a dash ("-").
  /// The format is based on the current language set in [LocalizationService].
  String extToDateStringDDMMMMYYYY() {
    if (this == null) return '-';
    return DateFormat(
      'dd MMMM yyyy',
      appContext?.locale.languageCode,
    ).format(this ?? DateTime.now());
  }

  /// * Start From Sunday to Saturday
  List<DateTime> extGetDaysInWeek() {
    if (this == null) return [];
    final now = this;
    final startFrom = now!.subtract(Duration(days: now.weekday));
    final list = List.generate(8, (i) => startFrom.add(Duration(days: i)));
    list.removeLast();
    return list;
  }

  /// Checks if the current date is the same day, month, and year as the given [date].
  /// Returns `true` if they are the same, `false` otherwise.
  bool extIsSameDayMonthYear(DateTime date) {
    if (this == null) return false;
    return date.year == this?.year &&
        date.month == this?.month &&
        date.day == this?.day;
  }

  bool extIsSameDayMonthYearHoursMinute(DateTime date) {
    if (this == null) return false;
    return extToFormattedString(outputDateFormat: 'yyyy-MM-dd HH:mm') ==
        date.extToFormattedString(outputDateFormat: 'yyyy-MM-dd HH:mm');
  }

  /// Checks if the current DateTime object is in the same year as the given [date].
  /// Returns true if they are in the same year, false otherwise.
  bool extIsSameYear(DateTime date) {
    if (this == null) return false;
    return this?.year == date.year;
  }

  /// Checks if the current DateTime object is in the same month and year as the given [date].
  /// Returns true if the month and year are the same, otherwise returns false.
  bool extIsSameMonthYear(DateTime date) {
    if (this == null) return false;
    return this?.month == date.month && this?.year == date.year;
  }

  /// Returns a string representation of the time difference between the current DateTime object and the DateTime object it is called on.
  /// The returned string represents the time difference in a human-readable format, such as "2 years ago", "3 months ago", "1 week ago", etc.
  /// If the DateTime object it is called on is null, the current DateTime object is used as a fallback.
  String extTimeAgo() {
    final Duration diff = DateTime.now().difference(this ?? DateTime.now());
    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()} ${(diff.inDays / 365).floor() == 1 ? appContext?.l10n.yearSuffix : appContext?.l10n.yearSuffix} ${appContext?.l10n.agoSuffix}';
    }
    if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()} ${(diff.inDays / 30).floor() == 1 ? appContext?.l10n.monthSuffix : appContext?.l10n.monthSuffix} ${appContext?.l10n.agoSuffix}';
    }
    if (diff.inDays > 7) {
      return '${(diff.inDays / 7).floor()} ${(diff.inDays / 7).floor() == 1 ? appContext?.l10n.weekSuffix : appContext?.l10n.weekSuffix} ${appContext?.l10n.agoSuffix}';
    }
    if (diff.inDays > 0) {
      return '${diff.inDays} ${diff.inDays == 1 ? appContext?.l10n.daySuffix : appContext?.l10n.daySuffix} ${appContext?.l10n.agoSuffix}';
    }
    if (diff.inHours > 0) {
      return '${diff.inHours} ${diff.inHours == 1 ? appContext?.l10n.hourSuffix : appContext?.l10n.hourSuffix} ${appContext?.l10n.agoSuffix}';
    }
    if (diff.inMinutes > 0) {
      return '${diff.inMinutes} ${diff.inMinutes == 1 ? appContext?.l10n.minuteSuffix : appContext?.l10n.minuteSuffix} ${appContext?.l10n.agoSuffix}';
    }
    return appContext?.l10n.justNow ?? 'Baru saja';
  }

  /// Returns a new [DateTime] object with only the date part, discarding the time.
  ///
  /// Throws an exception if the current [DateTime] object is null or if any of its components (year, month, day) is null.
  DateTime extGetDate() {
    try {
      return DateTime(this!.year, this!.month, this!.day);
    } catch (e) {
      rethrow;
    }
  }

  DateTime extGetFirstDateInMonth() {
    if (this == null) {
      return DateTime(DateTime.now().year, DateTime.now().month, 1);
    }
    return DateTime(this!.year, this!.month, 1);
  }

  DateTime extGetLastDateInMonth() {
    if (this == null) {
      return DateTime(
        DateTime.now().year,
        DateTime.now().month + 1,
        1,
      ).subtract(const Duration(days: 1));
    }
    return DateTime(
      this!.year,
      this!.month + 1,
      1,
    ).subtract(const Duration(days: 1));
  }

  // int extGenerateIDForNotif() {
  //   int tempId = DateTime.now().microsecond;
  //   if (tempId < 800) {
  //     tempId += Random().nextInt(100);
  //   }
  //   if (Get.isRegistered<UploadFileController>()) {
  //     final int index = UploadFileController.to.listTaskUpload
  //         .indexWhere((element) => element.id == tempId);
  //     if (index == -1) return tempId;
  //     return extGenerateIDForNotif();
  //   }
  //   return tempId;
  //   // if (this == null) {
  //   // }
  //   // final String temp = extToFormattedString(outputDateFormat: 'mmss');
  //   // return int.tryParse('$temp${DateTime.now().microsecond}') ??
  //   //     DateTime.now().microsecond;
  // }

  // List<int> extGetWeekNumbers() {
  //   try {
  //     final int year = this?.year ?? DateTime.now().year;
  //     final int month = this?.month ?? DateTime.now().month;
  //     // Validasi input
  //     if (year < 0 || month < 1 || month > 12) {
  //       throw ArgumentError('Invalid year or month');
  //     }

  //     final List<int> listWeek = [];

  //     // Dapatkan hari pertama dan terakhir bulan
  //     final DateTime firstDayOfMonth = DateTime(year, month, 1);
  //     final DateTime lastDayOfMonth = DateTime(year, month + 1, 0);

  //     for (var i = firstDayOfMonth.day; i <= lastDayOfMonth.day; i++) {
  //       final int weekOnYear = DTU.getWeekNumber(DateTime(year, month, i));
  //       int resultWeek = 0;

  //       if (month == 12) {
  //         if (i > 1) {
  //           final int prevWeek = DTU.getWeekNumber(
  //             DateTime(year, month, i - 1),
  //           );

  //           if (prevWeek > weekOnYear) {
  //             resultWeek = prevWeek + 1;
  //           } else if (prevWeek == weekOnYear) {
  //           } else {
  //             resultWeek = weekOnYear;
  //           }
  //         } else {
  //           resultWeek = weekOnYear;
  //         }
  //       } else {
  //         resultWeek = weekOnYear;
  //       }
  //       if (!listWeek.contains(resultWeek)) {
  //         listWeek.add(resultWeek);
  //       }
  //     }
  //     return listWeek;
  //   } catch (e) {
  //     return [];
  //   }
  // }

  /// Check if the date is today
  bool get extIsToday {
    if (this == null) return false;
    final now = DateTime.now();
    return this!.year == now.year &&
        this!.month == now.month &&
        this!.day == now.day;
  }

  /// Check if the date is yesterday
  bool get extIsYesterday {
    if (this == null) return false;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return this!.year == yesterday.year &&
        this!.month == yesterday.month &&
        this!.day == yesterday.day;
  }

  /// Check if the date is within this week (starting from Monday)
  bool get extIsThisWeek {
    if (this == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Calculate the start of this week (Monday)
    final daysFromStartOfWeek = now.weekday - 1; // 0 = Monday, 6 = Sunday
    final startOfWeek = today.subtract(Duration(days: daysFromStartOfWeek));

    // Calculate the end of this week (Sunday)
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    // Check if the date is within this week
    final date = DateTime(this!.year, this!.month, this!.day);
    return date.isAtSameMomentAs(startOfWeek) ||
        date.isAtSameMomentAs(endOfWeek) ||
        (date.isAfter(startOfWeek) &&
            date.isBefore(endOfWeek.add(const Duration(days: 1))));
  }

  /// Check if the date is within last week
  bool get extIsLastWeek {
    if (this == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Calculate the start of this week (Monday)
    final daysFromStartOfWeek = now.weekday - 1;
    final startOfThisWeek = today.subtract(Duration(days: daysFromStartOfWeek));

    // Calculate the start of last week (previous Monday)
    final startOfLastWeek = startOfThisWeek.subtract(const Duration(days: 7));

    // Calculate the end of last week (previous Sunday)
    final endOfLastWeek = startOfThisWeek.subtract(const Duration(days: 1));

    // Check if the date is within last week
    final date = DateTime(this!.year, this!.month, this!.day);
    return date.isAtSameMomentAs(startOfLastWeek) ||
        date.isAtSameMomentAs(endOfLastWeek) ||
        (date.isAfter(startOfLastWeek) &&
            date.isBefore(endOfLastWeek.add(const Duration(days: 1))));
  }
}
