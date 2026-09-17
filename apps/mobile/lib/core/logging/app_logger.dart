abstract class AppLogger {
  void debug(String message);

  void info(String message);

  void error(String message, [Object? error, StackTrace? stackTrace]);
}
