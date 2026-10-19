import 'package:mobile/core/analytics/analytics_event.dart';
import 'package:mobile/core/analytics/analytics_service.dart';
import 'package:mobile/core/logging/app_logger.dart';
import 'package:mobile/features/settings/data/preference_vault.dart';

class MemoryPreferences implements PreferenceVault {
  String? value;
  bool fail = false;

  @override
  Future<String?> read() async {
    if (fail) throw StateError('storage');
    return value;
  }

  @override
  Future<void> write(String value) async {
    if (fail) throw StateError('storage');
    this.value = value;
  }
}

class RecordingAnalytics implements AnalyticsService {
  final events = <AnalyticsEvent>[];

  @override
  void track(AnalyticsEvent event) => events.add(event);
}

class RecordingLogger implements AppLogger {
  final messages = <String>[];

  @override
  void debug(String message) => messages.add(message);

  @override
  void info(String message) => messages.add(message);

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      messages.add(message);
}
