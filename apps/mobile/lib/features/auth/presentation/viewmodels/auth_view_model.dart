import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/analytics/analytics_event.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../settings/domain/app_preferences.dart';
import '../../../settings/domain/settings_use_cases.dart';
import '../../domain/auth_repository.dart';
import '../../domain/auth_use_cases.dart';
import '../../domain/session_alert_notifier.dart';

/// Screens of the signed-out flow. [reset] opens from the link in the email.
enum AuthStep { login, register, forgot, reset }

enum AuthNotice { verificationSent, resetSent, passwordChanged }

abstract class AuthViewModel extends ChangeNotifier {
  AuthStage get stage;
  AuthStep get step;

  /// Email last typed on sign-in, sign-up or "Quên mật khẩu".
  String get email;
  AuthNotice? get notice;
  Future<void> login(String email, String password);
  Future<void> register(
    String email,
    String password,
    String confirmation, {
    required bool termsAccepted,
  });
  Future<void> requestReset(String email);
  Future<void> resetPassword(
    String token,
    String password,
    String confirmation,
  );
  Future<void> resendVerification();
  void goTo(AuthStep step);

  /// Opens the new-password screen for the token from the reset email.
  void startReset(String token);

  /// Ends the first-run setup (verify email, PIN) and opens the app.
  void finishSetup();

  /// Whether this device has a PIN; without one the app never locks.
  bool get hasPin;
  bool get loading;
  bool get ready;
  bool get biometricAvailable;
  bool get biometricPrompt;
  AuthFailure? get failure;
  bool get succeeded;
  bool get newSessionAlert;
  List<AuthSession> get sessions;
  Future<void> initialize();
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
  AuthStep step = AuthStep.login;
  @override
  String email = '';
  @override
  AuthNotice? notice;
  @override
  bool hasPin = false;
  String _resetToken = '';

  @override
  Future<void> login(String value, String password) async {
    email = value.trim().toLowerCase();
    await _signIn(password);
    await _noticeSessions();
  }

  /// Signs in with [email]; a new account lands in [AuthStage.setup].
  Future<void> _signIn(String password, {bool firstRun = false}) => _run(
    () => _useCases.submit(AuthAction.login, {
      'email': email,
      'password': password,
    }),
    (_) {
      succeeded = true;
      stage = firstRun ? AuthStage.setup : AuthStage.unlocked;
      hasPin = false;
    },
  );

  @override
  Future<void> register(
    String value,
    String password,
    String confirmation, {
    required bool termsAccepted,
  }) async {
    if (loading) return;
    if (password != confirmation) {
      _fail(const AuthFailure(AuthError.passwordMismatch));
      return;
    }
    email = value.trim().toLowerCase();
    await _run(
      () => _useCases.submit(AuthAction.register, {
        'email': email,
        'password': password,
        'termsAccepted': '$termsAccepted',
      }),
      (_) {},
    );
    // The server answers 202 whether or not the email is new, so the next
    // step is always a sign-in: a taken email fails there with the usual
    // "email or password is wrong".
    if (failure == null) await _signIn(password, firstRun: true);
  }

  @override
  Future<void> requestReset(String value) async {
    email = value.trim().toLowerCase();
    await _run(
      () => _useCases.submit(AuthAction.requestReset, {'email': email}),
      (_) => notice = AuthNotice.resetSent,
    );
  }

  @override
  void startReset(String token) {
    _resetToken = token;
    step = AuthStep.reset;
    clearMessage();
  }

  @override
  Future<void> resetPassword(
    String token,
    String password,
    String confirmation,
  ) async {
    if (loading) return;
    if (password != confirmation) {
      _fail(const AuthFailure(AuthError.passwordMismatch));
      return;
    }
    await _run(
      () => _useCases.submit(AuthAction.resetPassword, {
        'token': token.isEmpty ? _resetToken : token,
        'password': password,
      }),
      (_) {
        stage = AuthStage.signedOut;
        step = AuthStep.login;
        notice = AuthNotice.passwordChanged;
      },
    );
  }

  void _fail(AuthFailure error) {
    failure = error;
    succeeded = false;
    notifyListeners();
  }

  @override
  Future<void> resendVerification() => _run(
    () => _useCases.submit(AuthAction.requestVerification, {'email': email}),
    (_) => notice = AuthNotice.verificationSent,
  );

  @override
  void goTo(AuthStep next) {
    if (loading) return;
    step = next;
    clearMessage();
  }

  @override
  void finishSetup() {
    if (stage != AuthStage.setup) return;
    stage = AuthStage.unlocked;
    notifyListeners();
    _noticeSessions();
  }

  void _resetFlow() {
    step = AuthStep.login;
    email = '';
    notice = null;
    newSessionAlert = false;
    _delivered = false;
    hasPin = false;
    _resetToken = '';
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
    if (stage != AuthStage.signedOut) {
      hasPin = (await _useCases.pinSet()).getOrElse(() => false);
    }
    final available = await _useCases.biometricAvailable();
    biometricAvailable = available.getOrElse(() => false);
    ready = true;
    notifyListeners();
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
      hasPin = true;
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
    if (stage == AuthStage.unlocked && hasPin) stage = AuthStage.locked;
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
