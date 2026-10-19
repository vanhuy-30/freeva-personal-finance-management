import 'package:injectable/injectable.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../settings/domain/settings_use_cases.dart';
import '../domain/auth_use_cases.dart';
import '../domain/session_alert_notifier.dart';
import 'viewmodels/auth_view_model.dart';

@module
abstract class AuthPresentationModule {
  @lazySingleton
  AuthViewModel authViewModel(
    AuthUseCases useCases,
    SettingsUseCases settings,
    SessionAlertNotifier alerts,
    AnalyticsService analytics,
  ) => DefaultAuthViewModel(
    useCases,
    settings: settings,
    alerts: alerts,
    analytics: analytics,
  );
}
