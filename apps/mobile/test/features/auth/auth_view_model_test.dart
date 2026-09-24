import 'dart:async';
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
  Future<void> login() => model.submit(AuthAction.login,
      {'email': 'test@example.com', 'password': 'long password here'});
  test(
      'login requires PIN setup before protected content and lock clears sessions',
      () async {
    await model.initialize();
    expect(model.stage, AuthStage.signedOut);
    await login();
    expect(model.stage, AuthStage.setupPin);
    await model.setupPin('123456', '123456', true, 'unlock');
    expect(model.stage, AuthStage.unlocked);
    await model.loadSessions();
    expect(model.sessions, hasLength(1));
    model.lock();
    expect(model.stage, AuthStage.locked);
    expect(model.sessions, isEmpty);
    await model.unlockBiometric('unlock');
    expect(model.stage, AuthStage.unlocked);
    await model.logout();
    expect(model.stage, AuthStage.signedOut);
  });
  test('late unlock response after backgrounding never opens protected content',
      () async {
    await login();
    await model.setupPin('123456', '123456', true, 'unlock');
    model.lock();
    final completer = Completer<void>();
    api.pending = completer.future;
    final operation = model.unlockBiometric('unlock');
    await Future<void>.delayed(Duration.zero);
    model.lock();
    completer.complete();
    await operation;
    expect(model.stage, AuthStage.locked);
  });
  test('duplicate submissions are ignored and failure exits loading state',
      () async {
    final completer = Completer<void>();
    api.pending = completer.future;
    final operation = login();
    await login();
    expect(api.calls, 1);
    api.failure = const AuthFailure(AuthError.rateLimited, retryAfter: 60);
    completer.complete();
    await operation;
    expect(model.loading, false);
    expect(model.failure?.retryAfter, 60);
    expect(model.stage, AuthStage.signedOut);
  });
  test('profile session expiry wins over an auth request already in flight', () async {
    final pending = Completer<void>();
    api.pending = pending.future;
    final operation = login();
    model.sessionExpired();
    pending.complete();
    await operation;
    expect(model.stage, AuthStage.signedOut);
    expect(model.failure?.code, AuthError.expired);
    expect(model.loading, false);
  });
  test('revoke current session returns to login', () async {
    await login();
    await model.setupPin('123456', '123456', false, 'unlock');
    await model.loadSessions();
    await model.revoke(model.sessions.single);
    expect(model.stage, AuthStage.signedOut);
    expect(model.sessions, isEmpty);
  });
}
