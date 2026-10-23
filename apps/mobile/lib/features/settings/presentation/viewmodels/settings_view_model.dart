import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics_event.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../auth/domain/auth_use_cases.dart';
import '../../domain/app_preferences.dart';
import '../../domain/settings_use_cases.dart';

abstract class SettingsViewModel extends ChangeNotifier {
  AppThemePreference get theme;
  bool get onboardingCompleted;
  bool get balancesHidden;
  bool get sessionAlertsEnabled;
  bool get loading;
  SettingsFailure? get failure;
  bool get biometricHardware;
  bool get biometricEnabled;
  bool get biometricBusy;
  AuthFailure? get biometricFailure;

  /// Email this device signed in with (shown masked); null when unknown.
  String? get email;
  Future<void> load();
  Future<void> refreshAccount();
  Future<void> setTheme(AppThemePreference value);
  Future<void> setBalancesHidden(bool value);
  Future<void> setSessionAlertsEnabled(bool value);
  void beginOnboarding();
  Future<bool> completeOnboarding();
  Future<void> refreshBiometrics();
  Future<void> setBiometricEnabled(bool enabled, String reason);
}

@LazySingleton(as: SettingsViewModel)
class DefaultSettingsViewModel extends SettingsViewModel {
  DefaultSettingsViewModel(this._cases, this._auth, this._analytics);

  final SettingsUseCases _cases;
  final AuthUseCases _auth;
  final AnalyticsService _analytics;
  AppPreferences _preferences = const AppPreferences();
  bool _started = false;
  bool _completedTracked = false;

  @override
  AppThemePreference get theme => _preferences.theme;
  @override
  bool get onboardingCompleted => _preferences.onboardingCompleted;
  @override
  bool get balancesHidden => _preferences.balancesHidden;
  @override
  bool get sessionAlertsEnabled => _preferences.sessionAlertsEnabled;
  @override
  bool loading = false;
  @override
  SettingsFailure? failure;
  @override
  bool biometricHardware = false;
  @override
  bool biometricEnabled = false;
  @override
  bool biometricBusy = false;
  @override
  AuthFailure? biometricFailure;
  @override
  String? email;

  @override
  Future<void> load() async {
    loading = true;
    notifyListeners();
    final result = await _cases.load();
    result.fold((error) => failure = error, (value) {
      _preferences = value;
      failure = null;
    });
    loading = false;
    notifyListeners();
  }

  @override
  Future<void> setTheme(AppThemePreference value) async {
    if (theme == value) return;
    await _save(_preferences.copyWith(theme: value));
  }

  @override
  Future<void> setBalancesHidden(bool value) async {
    if (balancesHidden == value) return;
    await _save(_preferences.copyWith(balancesHidden: value));
  }

  @override
  Future<void> setSessionAlertsEnabled(bool value) async {
    if (sessionAlertsEnabled == value) return;
    await _save(_preferences.copyWith(sessionAlertsEnabled: value));
  }

  Future<void> _save(AppPreferences next) async {
    final result = await _cases.save(next);
    result.fold((error) => failure = error, (saved) {
      _preferences = saved;
      failure = null;
    });
    notifyListeners();
  }

  @override
  void beginOnboarding() {
    if (_started || onboardingCompleted) return;
    _started = true;
    _analytics.track(AnalyticsEvent.onboardingStarted);
  }

  @override
  Future<bool> completeOnboarding() async {
    if (onboardingCompleted || loading) return onboardingCompleted;
    loading = true;
    notifyListeners();
    final result = await _cases.save(
      _preferences.copyWith(onboardingCompleted: true),
    );
    var savedOk = false;
    result.fold((error) => failure = error, (saved) {
      _preferences = saved;
      failure = null;
      savedOk = true;
      if (!_completedTracked) {
        _completedTracked = true;
        _analytics.track(AnalyticsEvent.onboardingCompleted);
      }
    });
    loading = false;
    notifyListeners();
    return savedOk;
  }

  @override
  Future<void> refreshAccount() async {
    final result = await _auth.accountEmail();
    email = result.getOrElse(() => null);
    notifyListeners();
  }

  @override
  Future<void> refreshBiometrics() async {
    final hardware = await _auth.biometricHardware();
    final enabled = await _auth.biometricEnabled();
    biometricHardware = hardware.getOrElse(() => false);
    biometricEnabled = enabled.getOrElse(() => false);
    notifyListeners();
  }

  @override
  Future<void> setBiometricEnabled(bool enabled, String reason) async {
    if (biometricBusy) return;
    biometricBusy = true;
    biometricFailure = null;
    notifyListeners();
    final result = await _auth.setBiometricEnabled(enabled, reason);
    result.fold(
      (error) => biometricFailure = error,
      (_) => biometricEnabled = enabled,
    );
    biometricBusy = false;
    notifyListeners();
  }
}
