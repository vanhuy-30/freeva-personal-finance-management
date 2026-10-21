import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

import 'app_logger.dart';

bool get _consoleLoggingEnabled {
  if (!kDebugMode) return false;
  // `flutter test` sets FLUTTER_TEST; keep suite output quiet.
  return Platform.environment['FLUTTER_TEST'] != 'true';
}

@LazySingleton(as: AppLogger)
class AppLoggerImpl implements AppLogger {
  AppLoggerImpl()
    : _logger = Logger(
        level: _consoleLoggingEnabled ? Level.debug : Level.off,
        printer: PrettyPrinter(
          methodCount: 0,
          errorMethodCount: 4,
          lineLength: 100,
          colors: true,
          printEmojis: false,
        ),
      );

  final Logger _logger;

  @override
  void debug(String message) => _logger.d(message);

  @override
  void info(String message) => _logger.i(message);

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  @override
  void op(String message) => _logger.i('op $message');

  @override
  void http(String message) => _logger.d('http $message');
}
