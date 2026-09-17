import 'analytics_event.dart';

abstract class AnalyticsService {
  void track(AnalyticsEvent event);
}
