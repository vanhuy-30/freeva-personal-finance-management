import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/settings/data/settings_repository_impl.dart';
import 'package:mobile/features/settings/domain/settings_use_cases.dart';

import '../settings/fakes.dart';
import 'fakes.dart';

void main() {
  late FakeApi api;
  late MemoryVault vault;
  late DefaultAuthViewModel model;
  const password = 'correct horse battery 7';
  setUp(() {
    api = FakeApi();
    vault = MemoryVault();
    model = DefaultAuthViewModel(
      DefaultAuthUseCases(AuthRepositoryImpl(api, vault, FakeBiometrics())),
    );
  });
  tearDown(() => model.dispose());

  test(
    'sign in normalizes the email and opens the app without a PIN',
    () async {
      await model.login(' User@Example.com ', password);
      expect(api.lastPath, 'auth/login');
      expect(api.lastBody, {'email': 'user@example.com', 'password': password});
      expect(model.stage, AuthStage.unlocked);
      expect(model.hasPin, false);
    },
  );

  test(
    'sign up registers with the terms flag, signs in, and lands in setup',
    () async {
      await model.register(
        'new@example.com',
        password,
        password,
        termsAccepted: true,
      );
      expect(api.calls, 2);
      expect(api.lastPath, 'auth/login');
      expect(model.stage, AuthStage.setup);
      expect(model.email, 'new@example.com');
      await model.resendVerification();
      expect(api.lastPath, 'auth/email-verifications');
      expect(model.notice, AuthNotice.verificationSent);
    },
  );

  test(
    'sign up sends nothing without terms, a digit, or a matching repeat',
    () async {
      await model.register(
        'a@example.com',
        password,
        password,
        termsAccepted: false,
      );
      expect(model.failure?.code, AuthError.invalidInput);
      await model.register(
        'a@example.com',
        'correct horse battery',
        'correct horse battery',
        termsAccepted: true,
      );
      expect(model.failure?.code, AuthError.invalidInput);
      await model.register(
        'a@example.com',
        password,
        'other',
        termsAccepted: true,
      );
      expect(model.failure?.code, AuthError.passwordMismatch);
      expect(api.calls, 0);
      expect(model.stage, AuthStage.signedOut);
    },
  );

  test('a failed registration never signs in', () async {
    api.failure = const AuthFailure(AuthError.rateLimited, retryAfter: 60);
    await model.register(
      'a@example.com',
      password,
      password,
      termsAccepted: true,
    );
    expect(api.calls, 1);
    expect(model.stage, AuthStage.signedOut);
  });

  test('setup can be skipped, leaving no PIN, or finished with one', () async {
    await model.register(
      'a@example.com',
      password,
      password,
      termsAccepted: true,
    );
    model.finishSetup();
    expect(model.stage, AuthStage.unlocked);
    expect(model.hasPin, false);
    await model.setupPin('123456', '123456', false, 'unlock');
    expect(model.hasPin, true);
    model.lock();
    expect(model.stage, AuthStage.locked);
  });

  test(
    'forgot password says "sent" and the reset link signs back in',
    () async {
      model.goTo(AuthStep.forgot);
      await model.requestReset('User@Example.com');
      expect(api.lastPath, 'auth/password-resets');
      expect(model.notice, AuthNotice.resetSent);
      model.startReset('a' * 64);
      expect(model.step, AuthStep.reset);
      await model.resetPassword('', password, password);
      expect(api.lastPath, 'auth/reset-password');
      expect(api.lastBody?['token'], 'a' * 64);
      expect(model.step, AuthStep.login);
      expect(model.notice, AuthNotice.passwordChanged);
    },
  );

  test(
    'Welcome shows on a fresh install, once, and never after sign-out',
    () async {
      final cases = DefaultSettingsUseCases(
        SettingsRepositoryImpl(MemoryPreferences()),
      );
      DefaultAuthViewModel fresh() => DefaultAuthViewModel(
        DefaultAuthUseCases(AuthRepositoryImpl(api, vault, FakeBiometrics())),
        settings: cases,
      );
      final first = fresh();
      addTearDown(first.dispose);
      await first.initialize();
      expect(first.step, AuthStep.welcome);
      await first.leaveWelcome(AuthStep.signUp);
      expect(first.step, AuthStep.signUp);
      final second = fresh();
      addTearDown(second.dispose);
      await second.initialize();
      expect(second.step, AuthStep.login);
    },
  );
}
