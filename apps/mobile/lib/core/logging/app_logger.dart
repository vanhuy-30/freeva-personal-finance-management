abstract class AppLogger {
  void debug(String message);

  void info(String message);

  void error(String message, [Object? error, StackTrace? stackTrace]);

  /// High-level UI / domain action (navigation, unlock, sync, …).
  void op(String message);

  /// Outbound / inbound HTTP (already scrubbed by caller).
  void http(String message);
}
