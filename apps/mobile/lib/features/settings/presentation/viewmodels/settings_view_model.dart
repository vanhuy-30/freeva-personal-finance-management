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
  bool get loading;
  SettingsFailure? get failure;
  bool get biometricHardware;
  bool get biometricEnabled;
  bool get biometricBusy;
  AuthFailure? get biometricFailure;
  Future<void> load();
  Future<void> setTheme(AppThemePreference value);
  void beginOnboarding();
  Future<bool> completeOnboarding();
  String? prepareFeedback(FeedbackKind kind, String message);
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
    final result = await _cases.save(_preferences.copyWith(theme: value));
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
  String? prepareFeedback(FeedbackKind kind, String message) {
    final result = _cases.feedbackText(kind, message);
    return result.fold(
      (error) {
        failure = error;
        notifyListeners();
        return null;
      },
      (text) {
        failure = null;
        notifyListeners();
        return text;
      },
    );
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
