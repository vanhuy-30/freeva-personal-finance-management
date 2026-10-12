import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/analytics/analytics_event.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../settings/domain/app_preferences.dart';
import '../../../settings/domain/settings_use_cases.dart';
import '../../domain/auth_repository.dart';
import '../../domain/auth_use_cases.dart';
import '../../domain/session_alert_notifier.dart';

enum AuthStep {
  email,
  password,
  register,
  verification,
  forgotPassword,
  resetPassword,
}

enum AuthNotice { emailSent, verified, passwordChanged }

abstract class AuthViewModel extends ChangeNotifier {
  AuthStage get stage;
  AuthStep get step;
  String get email;
  AuthNotice? get notice;
  Future<void> continueEmail(String value);
  Future<void> submitStep({
    String password = '',
    String confirmation = '',
    String token = '',
  });
  Future<void> resendVerification();
  void back();
  void forgotPassword();
  bool get loading;
  bool get ready;
  bool get biometricAvailable;
  bool get biometricPrompt;
  AuthFailure? get failure;
  bool get succeeded;
  bool get newSessionAlert;
  List<AuthSession> get sessions;
  Future<void> initialize();
  Future<void> submit(AuthAction action, Map<String, String> fields);
  Future<void> setupPin(
    String pin,
    String confirmation,
    bool biometric,
    String reason,
  );
  Future<void> unlockPin(String pin);
  Future<void> unlockBiometric(String reason);
  Future<void> loadSessions();
  Future<void> deliverSessionNotification(String title, String body);
  Future<void> openSessionAlert();
  Future<void> revoke(AuthSession? session);
  Future<void> logout();
  Future<void> forgetDevice();
  void lock();
  void sessionExpired();
  void clearMessage();
}

class DefaultAuthViewModel extends AuthViewModel {
  DefaultAuthViewModel(
    this._useCases, {
    this.settings,
    this.alerts,
    this.analytics,
  });
  final AuthUseCases _useCases;
  final SettingsUseCases? settings;
  final SessionAlertNotifier? alerts;
  final AnalyticsService? analytics;
  @override
  AuthStep step = AuthStep.email;
  @override
  String email = '';
  @override
  AuthNotice? notice;

  @override
  Future<void> continueEmail(String value) =>
      _run(() => _useCases.accountExists(value), (exists) {
        email = value.trim().toLowerCase();
        step = exists ? AuthStep.password : AuthStep.register;
      });

  @override
  Future<void> submitStep({
    String password = '',
    String confirmation = '',
    String token = '',
  }) async {
    if (loading) return;
    if ((step == AuthStep.register || step == AuthStep.resetPassword) &&
        password != confirmation) {
      failure = const AuthFailure(AuthError.passwordMismatch);
      succeeded = false;
      notifyListeners();
      return;
    }
    switch (step) {
      case AuthStep.email:
        return;
      case AuthStep.password:
        await submit(AuthAction.login, {'email': email, 'password': password});
      case AuthStep.register:
        await submit(AuthAction.register, {
          'email': email,
          'password': password,
        });
      case AuthStep.verification:
        await submit(AuthAction.verifyEmail, {'token': token.trim()});
      case AuthStep.forgotPassword:
        await submit(AuthAction.requestReset, {'email': email});
      case AuthStep.resetPassword:
        await submit(AuthAction.resetPassword, {
          'token': token.trim(),
          'password': password,
        });
    }
  }

  @override
  Future<void> resendVerification() =>
      submit(AuthAction.requestVerification, {'email': email});

  @override
  void back() {
    if (loading) return;
    step = switch (step) {
      AuthStep.verification ||
      AuthStep.forgotPassword ||
      AuthStep.resetPassword => AuthStep.password,
      _ => AuthStep.email,
    };
    clearMessage();
  }

  @override
  void forgotPassword() {
    if (loading) return;
    step = AuthStep.forgotPassword;
    clearMessage();
  }

  void _resetFlow() {
    step = AuthStep.email;
    email = '';
    notice = null;
    newSessionAlert = false;
    _delivered = false;
  }

  @override
  AuthStage stage = AuthStage.signedOut;
  @override
  bool loading = false;
  @override
  bool ready = false;
  @override
  bool biometricAvailable = false;
  @override
  bool biometricPrompt = false;
  @override
  AuthFailure? failure;
  @override
  bool succeeded = false;
  @override
  bool newSessionAlert = false;
  bool _delivered = false;
  @override
  List<AuthSession> sessions = [];
  int _epoch = 0;

  Future<void> _run<T>(
    Future<Either<AuthFailure, T>> Function() operation,
    void Function(T) success,
  ) async {
    if (loading) return;
    loading = true;
    failure = null;
    succeeded = false;
    notice = null;
    final epoch = _epoch;
    notifyListeners();
    final result = await operation();
    if (epoch != _epoch && stage == AuthStage.signedOut) {
      loading = false;
      notifyListeners();
      return;
    }
    result.fold(
      (error) {
        failure = error;
        if (error.code == AuthError.expired) {
          stage = AuthStage.signedOut;
          _resetFlow();
          sessions = [];
        }
      },
      (value) {
        success(value);
        if (epoch != _epoch && stage == AuthStage.unlocked) {
          stage = AuthStage.locked;
        }
      },
    );
    loading = false;
    notifyListeners();
  }

  @override
  Future<void> initialize() async {
    if (ready || loading) return;
    await _run(_useCases.restore, (value) => stage = value);
    final available = await _useCases.biometricAvailable();
    biometricAvailable = available.getOrElse(() => false);
    ready = true;
    notifyListeners();
  }

  @override
  Future<void> submit(AuthAction action, Map<String, String> fields) async {
    await _run(() => _useCases.submit(action, fields), (_) {
      succeeded = true;
      if (action == AuthAction.login) stage = AuthStage.setupPin;
      switch (action) {
        case AuthAction.register:
          step = AuthStep.verification;
          succeeded = false;
        case AuthAction.verifyEmail:
          step = AuthStep.password;
          notice = AuthNotice.verified;
        case AuthAction.requestReset:
          step = AuthStep.resetPassword;
          succeeded = false;
        case AuthAction.resetPassword:
          stage = AuthStage.signedOut;
          step = AuthStep.password;
          notice = AuthNotice.passwordChanged;
        case AuthAction.requestVerification:
          notice = AuthNotice.emailSent;
        case AuthAction.login:
          break;
      }
    });
    if (action == AuthAction.login && stage == AuthStage.setupPin) {
      biometricAvailable = (await _useCases.biometricAvailable()).getOrElse(
        () => false,
      );
      notifyListeners();
    }
  }

  @override
  Future<void> setupPin(
    String pin,
    String confirmation,
    bool biometric,
    String reason,
  ) async {
    biometricPrompt = biometric;
    await _run(() => _useCases.setupPin(pin, confirmation, biometric, reason), (
      _,
    ) {
      stage = AuthStage.unlocked;
      biometricAvailable = biometric;
    });
    biometricPrompt = false;
    await _noticeSessions();
  }

  @override
  Future<void> unlockPin(String pin) async {
    await _run(
      () => _useCases.unlockPin(pin),
      (_) => stage = AuthStage.unlocked,
    );
    await _noticeSessions();
  }

  @override
  Future<void> unlockBiometric(String reason) async {
    biometricPrompt = true;
    await _run(
      () => _useCases.unlockBiometric(reason),
      (_) => stage = AuthStage.unlocked,
    );
    biometricPrompt = false;
    await _noticeSessions();
  }

  Future<void> _noticeSessions() async {
    final cases = settings;
    if (cases == null || stage != AuthStage.unlocked) return;
    final loaded = await cases.load();
    final enabled = loaded.fold<bool?>(
      (_) => null,
      (value) => value.sessionAlertsEnabled,
    );
    if (enabled == null || stage != AuthStage.unlocked) return;
    final result = await _useCases.observeSessions();
    if (stage == AuthStage.signedOut) return;
    result.fold((_) {}, (notice) {
      if (enabled && notice.alert) {
        newSessionAlert = true;
        _delivered = false;
      }
    });
    notifyListeners();
  }

  @override
  Future<void> deliverSessionNotification(String title, String body) async {
    if (_delivered || !newSessionAlert) return;
    final cases = settings;
    final notifier = alerts;
    if (cases == null || notifier == null) return;
    _delivered = true;
    final loaded = await cases.load();
    final prefs = loaded.fold<AppPreferences?>((_) => null, (value) => value);
    if (prefs == null || !prefs.sessionAlertsEnabled || !newSessionAlert) {
      return;
    }
    var access = await notifier.access();
    var current = prefs;
    var grantedNow = false;
    if (access != NotificationAccess.granted && !current.notificationPrompted) {
      access = await notifier.requestAccess();
      grantedNow = access == NotificationAccess.granted;
      final saved = await cases.save(
        current.copyWith(notificationPrompted: true),
      );
      saved.fold((_) {}, (value) => current = value);
    }
    if (access == NotificationAccess.granted) {
      await notifier.show(title: title, body: body);
    }
    if (grantedNow && !current.notificationsOptInTracked) {
      analytics?.track(AnalyticsEvent.notificationsOptIn);
      await cases.save(current.copyWith(notificationsOptInTracked: true));
    }
  }

  @override
  Future<void> openSessionAlert() async {
    newSessionAlert = false;
    notifyListeners();
    if (stage == AuthStage.unlocked) await loadSessions();
  }

  @override
  Future<void> loadSessions() => _run(_useCases.sessions, (value) {
    if (stage == AuthStage.unlocked) sessions = value;
  });
  @override
  Future<void> revoke(AuthSession? session) async {
    await _run(() => _useCases.revoke(session?.id), (_) {
      if (session == null || session.current) {
        stage = AuthStage.signedOut;
        _resetFlow();
        sessions = [];
      } else {
        sessions = sessions.where((s) => s.id != session.id).toList();
      }
    });
  }

  @override
  Future<void> logout() => _run(_useCases.logout, (_) {
    stage = AuthStage.signedOut;
    _resetFlow();
    sessions = [];
  });
  @override
  Future<void> forgetDevice() => _run(_useCases.forgetDevice, (_) {
    stage = AuthStage.signedOut;
    _resetFlow();
    sessions = [];
  });
  @override
  void sessionExpired() {
    _epoch++;
    stage = AuthStage.signedOut;
    sessions = [];
    _resetFlow();
    failure = const AuthFailure(AuthError.expired);
    succeeded = false;
    notifyListeners();
  }

  @override
  void lock() {
    _epoch++;
    sessions = [];
    if (stage == AuthStage.unlocked) stage = AuthStage.locked;
    clearMessage();
  }

  @override
  void clearMessage() {
    failure = null;
    succeeded = false;
    notice = null;
    notifyListeners();
  }
}
