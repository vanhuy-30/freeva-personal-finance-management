import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'fakes.dart';

void main() {
  late MemoryVault vault;
  late FakeApi api;
  late FakeBiometrics biometrics;
  late AuthRepositoryImpl repository;
  setUp(() {
    vault = MemoryVault();
    api = FakeApi();
    biometrics = FakeBiometrics();
    repository = AuthRepositoryImpl(api, vault, biometrics);
  });
  Future<void> login() async {
    expect(
        (await repository.submit(AuthAction.login, {
          'email': 'user@example.com',
          'password': 'password long enough'
        }))
            .isRight(),
        true);
  }

  Future<void> setup({bool bio = false}) async {
    await login();
    expect(
        (await repository.setupPin('123456', bio, 'unlock')).isRight(), true);
  }

  test('PIN hash is salted; cold start locks and PIN validates server session',
      () async {
    await setup();
    expect(vault.value, isNot(contains('123456')));
    expect(jsonDecode(vault.value!)['salt'], isNotEmpty);
    final restored = AuthRepositoryImpl(api, vault, biometrics);
    expect((await restored.restore()).getOrElse(() => AuthStage.signedOut),
        AuthStage.locked);
    expect((await restored.unlockPin('123456')).isRight(), true);
    expect(api.lastPath, 'sessions');
  });
  test(
      'failed PIN attempts survive restart and fifth failure removes credentials',
      () async {
    await setup();
    for (var i = 0; i < 5; i++) {
      final restarted = AuthRepositoryImpl(api, vault, biometrics);
      await restarted.restore();
      final result = await restarted.unlockPin('000000');
      expect(result.fold((f) => f.code, (_) => null),
          i == 4 ? AuthError.expired : AuthError.wrongPin);
    }
    expect(vault.value, isNull);
  });
  test('interrupted PIN setup never grants access after restart', () async {
    await login();
    expect(
        (await AuthRepositoryImpl(api, vault, biometrics).restore())
            .getOrElse(() => AuthStage.unlocked),
        AuthStage.signedOut);
    expect(vault.value, isNull);
  });
  test('biometrics require opt-in and cancellation stays locked', () async {
    await setup();
    expect((await repository.unlockBiometric('unlock')).isLeft(), true);
    expect(biometrics.calls, 0);
    await setup(bio: true);
    biometrics.accepted = false;
    expect((await repository.unlockBiometric('unlock')).isLeft(), true);
    biometrics.accepted = true;
    expect((await repository.unlockBiometric('unlock')).isRight(), true);
  });
  test('revoked session cannot unlock and clears credentials', () async {
    await setup(bio: true);
    api.failure = const AuthFailure(AuthError.expired);
    expect(
        (await repository.unlockBiometric('unlock'))
            .fold((f) => f.code, (_) => null),
        AuthError.expired);
    expect(vault.value, isNull);
  });
  test('storage errors fail closed and do not authenticate', () async {
    vault.fail = true;
    expect((await repository.restore()).isLeft(), true);
    expect((await repository.submit(AuthAction.login, {})).isLeft(), true);
  });
  test(
      'logout network failure retains credentials for retry; forget is local only',
      () async {
    await login();
    api.failure = const AuthFailure(AuthError.network);
    expect((await repository.logout()).isLeft(), true);
    expect(vault.value, isNotNull);
    final calls = api.calls;
    await repository.forgetDevice();
    expect(vault.value, isNull);
    expect(api.calls, calls);
  });
  test(
      'use cases normalize email, preserve password and reject invalid payloads',
      () async {
    final useCases = DefaultAuthUseCases(repository);
    await useCases.submit(AuthAction.login,
        {'email': ' User@Example.com ', 'password': ' password with spaces '});
    expect(api.lastBody,
        {'email': 'user@example.com', 'password': ' password with spaces '});
    final calls = api.calls;
    expect((await useCases.submit(AuthAction.login, {})).isLeft(), true);
    expect(
        (await useCases.submit(
                AuthAction.register, {'email': 'bad', 'password': 'short'}))
            .isLeft(),
        true);
    expect(
        (await useCases.setupPin('123456', '654321', false, 'unlock')).isLeft(),
        true);
    expect(api.calls, calls);
  });
  test('reset and revoke current/all clear local credentials', () async {
    await login();
    await repository.revoke('other');
    expect(vault.value, isNotNull);
    await repository.revoke('current');
    expect(vault.value, isNull);
    await login();
    await repository.revoke(null);
    expect(vault.value, isNull);
    await login();
    await repository.submit(AuthAction.resetPassword, {});
    expect(vault.value, isNull);
  });
  test('expired stored session requires login', () async {
    await setup();
    final record = jsonDecode(vault.value!) as Map<String, dynamic>;
    record['expiresAt'] =
        DateTime.now().subtract(const Duration(seconds: 1)).toIso8601String();
    vault.value = jsonEncode(record);
    expect((await repository.restore()).fold((f) => f.code, (_) => null),
        AuthError.expired);
    expect(vault.value, isNull);
  });
}
