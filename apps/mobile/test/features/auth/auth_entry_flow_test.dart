import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'fakes.dart';

void main() {
  late FakeApi api;
  late DefaultAuthViewModel model;
  setUp(() {
    api = FakeApi();
    model = DefaultAuthViewModel(DefaultAuthUseCases(
        AuthRepositoryImpl(api, MemoryVault(), FakeBiometrics())));
  });
  tearDown(() => model.dispose());
  test('email-first routes existing and new accounts, normalizes email',
      () async {
    await model.continueEmail(' Existing@Example.com ');
    expect(model.step, AuthStep.password);
    expect(model.email, 'existing@example.com');
    expect(api.lastBody, {'email': 'existing@example.com'});
    model.back();
    api.nextStep = 'register';
    await model.continueEmail('new@example.com');
    expect(model.step, AuthStep.register);
  });
  test(
      'invalid email, network failure and malformed response never guess account state',
      () async {
    await model.continueEmail('invalid');
    expect(model.failure?.code, AuthError.invalidEmail);
    expect(api.calls, 0);
    api.failure = const AuthFailure(AuthError.network);
    await model.continueEmail('new@example.com');
    expect(model.step, AuthStep.email);
    api.failure = null;
    api.nextStep = 'unexpected';
    await model.continueEmail('new@example.com');
    expect(model.step, AuthStep.email);
    expect(model.failure?.code, AuthError.unavailable);
  });
  test(
      'registration transitions straight to verification; resend is contextual',
      () async {
    api.nextStep = 'register';
    await model.continueEmail('new@example.com');
    await model.submitStep(
        password: 'correct horse battery',
        confirmation: 'correct horse battery');
    expect(api.lastPath, 'auth/register');
    expect(model.step, AuthStep.verification);
    // Registration sends the first challenge; mobile does not issue a second one.
    expect(api.calls, 2);
    await model.resendVerification();
    expect(api.lastPath, 'auth/email-verifications');
    await model.submitStep(token: 'a' * 64);
    expect(api.lastPath, 'auth/verify-email');
    expect(model.step, AuthStep.password);
    expect(model.notice, AuthNotice.verified);
  });
  test('mismatched confirmation sends no registration request', () async {
    api.nextStep = 'register';
    await model.continueEmail('new@example.com');
    await model.submitStep(
        password: 'correct horse battery', confirmation: 'different password');
    expect(api.calls, 1);
    expect(model.failure?.code, AuthError.passwordMismatch);
    expect(model.step, AuthStep.register);
  });
  test('forgot password is a guided reset flow and returns to sign in',
      () async {
    await model.continueEmail('existing@example.com');
    model.forgotPassword();
    expect(model.step, AuthStep.forgotPassword);
    await model.submitStep();
    expect(api.lastPath, 'auth/password-resets');
    expect(model.step, AuthStep.resetPassword);
    await model.submitStep(
        token: 'a' * 64,
        password: 'new password long enough',
        confirmation: 'new password long enough');
    expect(api.lastPath, 'auth/reset-password');
    expect(model.step, AuthStep.password);
    expect(model.notice, AuthNotice.passwordChanged);
    await model.submitStep(password: 'new password long enough');
    expect(model.stage, AuthStage.setupPin);
  });
}
