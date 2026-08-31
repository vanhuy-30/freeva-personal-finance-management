abstract class AppLogger {
  void info(String message);
  void error(String message, [Object? error, StackTrace? stackTrace]);
}
