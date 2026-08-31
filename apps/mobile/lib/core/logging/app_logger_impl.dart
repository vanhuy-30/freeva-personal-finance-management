import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

import 'app_logger.dart';

@LazySingleton(as: AppLogger)
class AppLoggerImpl implements AppLogger {
  AppLoggerImpl() : _logger = Logger();

  final Logger _logger;

  @override
  void info(String message) => _logger.i(message);

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
