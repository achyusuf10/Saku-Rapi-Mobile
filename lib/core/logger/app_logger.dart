import 'dart:developer';

// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class AppLogger {
  static void print(Object? message, {String name = 'LOG'}) {
    if (kDebugMode == false) return;
    AppLogger.print('[$name] $message');
  }

  static void call(Object message, {String name = 'LOG', ColorLog? colorLog}) {
    if (kDebugMode == false) return;
    switch (colorLog) {
      case ColorLog.red:
        _redColor(message.toString(), name: name);
        break;
      case ColorLog.blue:
        _blueColor(message.toString(), name: name);
        break;
      case ColorLog.yellow:
        _yellowColor(message.toString(), name: name);
        break;
      case ColorLog.green:
        _greenColor(message.toString(), name: name);
        break;
      default:
        log(message.toString(), name: name);
    }
  }

  /// Logs a success message with the provided [message] and [runtimeType].
  ///
  /// This method is used to log success messages in the application.
  /// It prints the [runtimeType] of the class and the [message] in a formatted manner.
  /// The log will only be printed in debug mode.
  ///
  /// Example usage:
  /// ```dart
  /// logSuccess('Data saved successfully', runtimeType: MyClass);
  /// ```
  static void logSuccess(String message, {Type? runtimeType}) {
    if (kDebugMode == false) return;
    _greenColor('''
------------------------------------------------
Nama Class --> $runtimeType
Success --> $message
------------------------------------------------
      ''', name: 'LOG SUCCESS');
  }

  /// Logs an error message with optional stack trace and sends it to Firebase Crashlytics if [sendLogError] is true.
  ///
  /// - The [message] parameter represents the error message to be logged.
  /// - The [runtimeType] parameter represents the type of the class where the error occurred.
  /// - The [sendLogError] parameter determines whether to send the error to Firebase Crashlytics.
  /// - The [stackTrace] parameter represents the stack trace of the error. Only on release mode
  ///
  /// This method only logs the error if the app is in debug mode.
  /// It formats the error message with additional information such as the class name.
  static void logError(
    dynamic message, {
    Type? runtimeType,
    String? nameLog,
    bool sendLogError = false,
    // bool sendToSentry = false,
    StackTrace? stackTrace,
  }) {
    // if (sendLogError) {
    //   if (!kDebugMode) {
    //     FirebaseCrashlytics.instance.recordError(
    //       message.toString(),
    //       stackTrace,
    //     );
    //   }
    // }
    // if (sendToSentry) {
    //   SentryServices.send(
    //     payload: message,
    //     stackTrace: stackTrace,
    //   );
    // }
    if (kDebugMode == false) return;

    if (runtimeType == null) {
      _redColor(
        '''
------------------------------------------------
Error --> $message
------------------------------------------------
      ''',
        name: nameLog ?? 'LOG ERROR',
        stackTrace: stackTrace,
      );
    } else {
      _redColor(
        '''
------------------------------------------------
Nama Class --> $runtimeType
Error --> $message
------------------------------------------------
      ''',
        name: 'LOG ERROR',
        stackTrace: stackTrace,
      );
    }
  }

  /// Logs a warning message with the specified [message] and [runtimeType].
  ///
  /// This method is used to log warning messages in the application. It will only log the message if the application is running in debug mode.
  ///
  /// The [message] parameter represents the warning message to be logged.
  ///
  /// The [runtimeType] parameter represents the type of the class where the warning occurred.
  ///
  /// Example usage:
  /// ```dart
  /// AppLogger.logWarning('Invalid input', runtimeType: MyClass);
  /// ```
  static void logWarning(String message, {required Type runtimeType}) {
    if (kDebugMode == false) return;
    _yellowColor('''
------------------------------------------------
Nama Class --> $runtimeType
Warning --> $message
------------------------------------------------
      ''', name: 'LOG WARNING');
  }

  /// Logs an informational message with the provided [message] and [runtimeType].
  ///
  /// This method is used to log information about a specific class and the associated message.
  /// It will only log the message if the app is running in debug mode.
  ///
  /// Example usage:
  /// ```dart
  /// AppLogger.logInfo(
  ///   'This is an informational message',
  ///   runtimeType: MyClass,
  /// );
  /// ```
  static void logInfo(String message, {Type? runtimeType}) {
    if (kDebugMode == false) return;
    _blueColor('''
------------------------------------------------
Nama Class --> $runtimeType
Info --> $message
------------------------------------------------
      ''', name: 'LOG INFO');
  }

  static void _redColor(
    String msg, {
    String name = 'LOG',
    StackTrace? stackTrace,
  }) {
    log('\x1B[31m$msg\x1B[0m', name: name, stackTrace: stackTrace);
  }

  static void _greenColor(
    String msg, {
    String name = 'LOG',
    StackTrace? stackTrace,
  }) {
    log('\x1B[32m$msg\x1B[0m', name: name, stackTrace: stackTrace);
  }

  static void _yellowColor(
    String msg, {
    String name = 'LOG',
    StackTrace? stackTrace,
  }) {
    log('\x1B[33m$msg\x1B[0m', name: name, stackTrace: stackTrace);
  }

  static void _blueColor(
    String msg, {
    String name = 'LOG',
    StackTrace? stackTrace,
  }) {
    log('\x1B[34m$msg\x1B[0m', name: name, stackTrace: stackTrace);
  }
}

enum ColorLog { red, green, yellow, blue }
