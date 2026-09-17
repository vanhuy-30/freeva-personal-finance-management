import 'dart:convert';

import 'package:injectable/injectable.dart';

import '../logging/app_logger.dart';
import 'analytics_event.dart';
import 'analytics_service.dart';

@LazySingleton(as: AnalyticsService)
class DebugAnalyticsService implements AnalyticsService {
  const DebugAnalyticsService(this._logger);

  final AppLogger _logger;

  @override
  void track(AnalyticsEvent event) {
    _logger.debug('analytics ${jsonEncode(event.toPayload())}');
  }
}
