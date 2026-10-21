import 'package:flutter/widgets.dart';

import 'app_logger.dart';

/// Logs route pushes / pops to the debug console (no PII in route names).
class LoggingNavigatorObserver extends NavigatorObserver {
  LoggingNavigatorObserver(this._logger);

  final AppLogger _logger;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _logger.op('nav push ${_name(route)} (from ${_name(previousRoute)})');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _logger.op('nav pop ${_name(route)} → ${_name(previousRoute)}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _logger.op('nav replace ${_name(oldRoute)} → ${_name(newRoute)}');
  }

  String _name(Route<dynamic>? route) =>
      route?.settings.name ?? route?.settings.arguments?.toString() ?? '?';
}
