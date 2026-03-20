import 'package:app_saku_rapi/core/extensions/date_time_ext.dart';
import 'package:app_saku_rapi/core/extensions/localization_context_ext.dart';
import 'package:app_saku_rapi/core/router/app_router.dart';
import 'package:intl/intl.dart';

extension StringExtension on String {
  String extLimitChar(int maxLength, {int lengthDot = 3}) {
    try {
      if (length > maxLength) {
        final res =
            '${substring(0, maxLength)}${List.generate(lengthDot, (index) => '.').join()}';
        return res;
      }
      return this;
    } catch (e) {
      return this;
    }
  }

  /// Converts the given phone number string to the +62 format.
  ///
  /// If the length of the string is less than 3, it returns the original string.
  ///
  /// If the string starts with '+62', it removes the '+' sign.
  ///
  /// If the string starts with '0', it replaces the '0' with '62'.
  ///
  /// If the string starts with '62', it returns the original string.
  ///
  /// Otherwise, it prepends '62' to the original string.
  String extTo62Format({String? costume}) {
    if (length < 3) return this;
    if (substring(0, 3) == '+${costume ?? '62'}') return substring(1);
    if (this[0] == '0') return '${costume ?? '62'}${substring(1)}';
    if (substring(0, 2) == (costume ?? '62')) return this;
    return '${costume ?? '62'}$this';
  }

  String extToCapitalize() {
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  String extToDeleteBlank() {
    return replaceAll('.', '');
  }

  /// Converts the string to title case.
  ///
  /// If the string is empty, it returns an empty string.
  /// If the string length is less than or equal to 1, it returns the string in uppercase.
  /// Otherwise, it splits the string into multiple words, capitalizes the first letter of each word,
  /// and joins all the words back into one string.
  ///
  /// Example:
  /// ```dart
  /// String input = 'hello world';
  /// String result = input.extToTitleCase();
  /// AppLogger.call(result); // Output: 'Hello World'
  /// ```
  String extToTitleCase() {
    if (isEmpty) return '';
    if (length <= 1) return toUpperCase();

    // Split string into multiple words
    final List<String> words = toLowerCase().split(' ');

    // Capitalize first letter of each words
    final capitalizedWords = words.map((word) {
      if (word.trim().isNotEmpty) {
        final String firstLetter = word.trim().substring(0, 1).toUpperCase();
        final String remainingLetters = word.trim().substring(1);
        return '$firstLetter$remainingLetters';
      }
      return '';
    });

    // Join/Merge all words back to one String
    return capitalizedWords.join(' ');
  }

  String extCapitalizeFirstLetter() {
    if (isEmpty) return this;
    if (length <= 1) return toUpperCase();
    // Split string into multiple words
    final List<String> words = toLowerCase().split(' ');
    if (words.isEmpty) return this;
    if (words[0].isNotEmpty) {
      words[0] = words[0].extToCapitalize();
    }
    return words.join(' ');
  }

  /// Converts a string to a DateTime object.
  ///
  /// The [originFormatDate] parameter specifies the format of the string representation of the date.
  /// The default value is 'yyyy-MM-dd HH:mm:ss'.
  ///
  /// The [locale] parameter specifies the locale to be used for parsing the date.
  /// The default value is 'ID' (Indonesian locale).
  ///
  /// Returns the parsed DateTime object.
  /// If the string cannot be parsed, returns the current DateTime.
  DateTime extToDateTime({
    String originFormatDate = 'yyyy-MM-dd HH:mm:ss',
    String? locale,
  }) {
    try {
      final res = DateFormat(
        originFormatDate,
        locale ?? appContext?.locale.languageCode,
      ).parse(this);
      return res;
    } catch (e) {
      final res = DateTime.tryParse(this);
      if (res == null) throw e.toString();
      return res;
    }
  }

  /// Converts a string date time to a custom formatted date.
  ///
  /// The [outputDateFormat] parameter specifies the desired format of the final output. The default value is 'dd-MM-yyyy'.
  ///
  /// The [originFormatDate] parameter specifies the original format of the date string that will be converted. The default value is 'yyyy-MM-dd'.
  ///
  /// The [originLocale] parameter specifies the locale of the original date string. The default value is 'ID'.
  ///
  /// Example usage: "09-01-2000".extToCustomFormattedDate(formatDateString: 'dd-MM-yyyy')
  String extToCustomFormattedDate({
    String outputDateFormat = 'dd-MM-yyyy',
    String originFormatDate = 'yyyy-MM-dd',
    String originLocale = 'ID',
  }) {
    final DateTime temp = extToDateTime(
      originFormatDate: originFormatDate,
      locale: originLocale,
    );
    return temp.extToFormattedString(outputDateFormat: outputDateFormat);
  }

  String extGetInitialWord() {
    if (isEmpty) return '';
    final List<String> temp = split(' ');

    final List<String> res = [];

    for (final element in temp) {
      if (res.length < 2) {
        res.add(element[0].toUpperCase());
      }
    }
    return res.join('');
  }

  String extToConvertToLocal() {
    try {
      final tempString = '$this.000+0700';
      return DateTime.parse(
        tempString,
      ).toLocal().extToFormattedString(outputDateFormat: 'dd-MM-yyyy - HH:mm');
    } catch (e) {
      return this;
    }
  }

  /// Capitalizes the first letter of each word in a string.
  ///
  /// If the string is empty, an empty string is returned.
  /// Each word in the string is separated by a space.
  /// If a word is empty or consists of only one character, it is capitalized.
  /// Otherwise, the first letter of the word is capitalized and the rest of the word remains unchanged.
  /// The capitalized words are then concatenated with spaces and returned as a single string.
  String extCapitalizeWord() {
    if (isEmpty) return '';
    // Each sentence becomes an array element
    final List<String> words = split(' ');
    if (words.isEmpty) return this;
    // Initialize string as empty string
    String output = '';
    // Loop through each sentence
    for (final word in words) {
      String capitalized = '';
      if (word.isEmpty) {
        capitalized = '';
      } else if (word.length > 1) {
        capitalized = word[0].toUpperCase() + word.substring(1);
      } else {
        capitalized = word[0].toUpperCase();
      }
      // Add current sentence to output with a period
      output += '$capitalized ';
    }
    return output;
  }

  String extGetOnlyRouteName() {
    final List<String> temp = split('?');
    if (temp.isEmpty) return '';
    return temp.first;
  }

  String extGet150Char() {
    if (isEmpty) return '';
    if (length <= 150) return this;
    return '${substring(0, 150)}...';
  }

  /// Converts a string representation of a date to a local DateTime object.
  /// The string should be in a format that can be parsed by DateTime.parse().
  /// Returns the converted DateTime object in the local time zone.
  DateTime extToDateLocal() {
    return DateTime.parse(this).toLocal();
  }

  /// Converts a string representation of a date to a UTC [DateTime] object.
  ///
  /// The string should be in a format that can be parsed by [DateTime.parse].
  /// Returns the converted [DateTime] object in UTC.
  DateTime extToDateUtc() {
    return DateTime.parse(this).toUtc();
  }

  /// Returns the file name without the file extension.
  String extGetFileNameOnly({bool replaceSpace = false}) {
    final String urlOnly = split('/').last;
    final String tempExtension = urlOnly.extGetFileExtension(
      convertLowerCase: false,
    );
    final String fileNameOnly = urlOnly
        .replaceAll('.$tempExtension', '')
        .replaceAll(' ', replaceSpace ? '_' : ' ');
    return fileNameOnly;
  }

  /// Returns the file name with extension from a given path.
  ///
  /// The [isReplaceSpace] parameter determines whether spaces in the file name should be replaced with underscores.
  /// By default, it is set to `false`.
  ///
  /// Example usage:
  /// ```dart
  /// final filePath = '/path/to/my file.txt';
  /// final fileName = filePath.extGetFileNameWithExtension();
  /// print(fileName); // Output: 'my_file.txt'
  /// ```
  String extGetFileNameWithExtension({bool isReplaceSpace = false}) {
    final String fileName = split('/').last;
    final String resultFileName = isReplaceSpace
        ? fileName.replaceAll(' ', '_')
        : fileName;
    return resultFileName;
  }

  String extGetFileExtension({bool convertLowerCase = true}) {
    final String urlOnly = split('/').last;
    final List<String> temp = urlOnly.split('.');
    if (temp.isEmpty) return '';
    if (convertLowerCase) {
      return temp.last.toLowerCase();
    }
    return temp.last;
  }

  bool extIsAudioFile() {
    final String tempExtension = extGetFileExtension();
    return [
      'mp3',
      'wav',
      'aac',
      'flac',
      'm4a',
      'ogg',
      'opus',
      'wma',
      'webm',
      'm2a',
    ].contains(tempExtension);
  }

  String extAddIndexToFileName(int index) {
    final String temp = extGetFileNameOnly();
    final String tempExtension = extGetFileExtension();
    return '$temp-($index).$tempExtension';
  }

  String extGetRouteWithoutQuery() {
    final List<String> temp = split('?');
    if (temp.isEmpty) return this;
    return temp.first;
  }
}

extension StringNullExtension on String? {
  /// Replaces an empty or null string with a specified replacement string.
  ///
  /// If the string is null or empty, it will be replaced with the [replacement] string.
  /// If the string is not null or empty, it will be returned as is.
  ///
  /// Example:
  /// ```dart
  /// String name = '';
  /// String result = name.extEmptyNullReplacement(replacement: 'John Doe');
  /// AppLogger.call(result); // Output: 'John Doe'
  /// ```
  String extEmptyNullReplacement({String replacement = '-'}) {
    if (this == null) return replacement;
    if ((this ?? '').isEmpty) return replacement;
    return this ?? replacement;
  }

  /// Checks if the string is empty or null.
  /// Returns true if the string is empty or null, otherwise returns false.
  bool extIsEmptyOrNull() {
    if (this == null) return true;
    if ((this ?? '').isEmpty) return true;
    return false;
  }

  String? extToDateDDMMMMYYYY() {
    if (this == null) return null;
    if (this == '') return null;
    final DateTime? temp = DateTime.tryParse(this ?? '');
    if (temp == null) return null;
    return temp.toLocal().extToDateStringDDMMMMYYYY();
  }

  String extDecodeUrlAndGetNameFile() {
    String result = '';
    try {
      result = Uri.decodeComponent(this ?? '').extGetFileNameWithExtension();
    } catch (e) {
      result = (this ?? '').extGetFileNameWithExtension();
    }
    return result;
  }
}
