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
        'password': 'password long enough',
      })).isRight(),
      true,
    );
  }

  Future<void> setup({bool bio = false}) async {
    await login();
    expect(
      (await repository.setupPin('123456', bio, 'unlock')).isRight(),
      true,
    );
  }

  test(
    'PIN hash is salted; cold start locks and PIN validates server session',
    () async {
      await setup();
      expect(vault.value, isNot(contains('123456')));
      expect(jsonDecode(vault.value!)['salt'], isNotEmpty);
      final restored = AuthRepositoryImpl(api, vault, biometrics);
      expect(
        (await restored.restore()).getOrElse(() => AuthStage.signedOut),
        AuthStage.locked,
      );
      expect((await restored.unlockPin('123456')).isRight(), true);
      expect(api.lastPath, 'sessions');
    },
  );
  test(
    'failed PIN attempts survive restart and fifth failure removes credentials',
    () async {
      await setup();
      for (var i = 0; i < 5; i++) {
        final restarted = AuthRepositoryImpl(api, vault, biometrics);
        await restarted.restore();
        final result = await restarted.unlockPin('000000');
        expect(
          result.fold((f) => f.code, (_) => null),
          i == 4 ? AuthError.expired : AuthError.wrongPin,
        );
      }
      expect(vault.value, isNull);
    },
  );
  test('a session without a PIN restores into the app and has no PIN', () async {
    await login();
    final restored = AuthRepositoryImpl(api, vault, biometrics);
    expect(
      (await restored.restore()).getOrElse(() => AuthStage.signedOut),
      AuthStage.unlocked,
    );
    expect((await restored.pinSet()).getOrElse(() => true), false);
    expect(vault.value, isNotNull);
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
      AuthError.expired,
    );
    expect(vault.value, isNull);
  });
  test('storage errors fail closed and do not authenticate', () async {
    vault.fail = true;
    expect((await repository.restore()).isLeft(), true);
    expect((await repository.submit(AuthAction.login, {})).isLeft(), true);
  });
  test('logout network failure retains credentials for retry; forget is local only', () async {
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
      await useCases.submit(AuthAction.login, {
        'email': ' User@Example.com ',
        'password': ' password with spaces ',
      });
      expect(api.lastBody, {
        'email': 'user@example.com',
        'password': ' password with spaces ',
      });
      final calls = api.calls;
      expect((await useCases.submit(AuthAction.login, {})).isLeft(), true);
      expect(
        (await useCases.submit(AuthAction.register, {
          'email': 'bad',
          'password': 'short',
          'termsAccepted': 'true',
        })).isLeft(),
        true,
      );
      // DS-P2-004: new passwords need a letter and a digit.
      for (final weak in ['no digits in this one', '1234567890123']) {
        expect(
          (await useCases.submit(AuthAction.register, {
            'email': 'lan@example.com',
            'password': weak,
          })).isLeft(),
          true,
        );
      }
      final before = api.calls;
      expect(
        (await useCases.submit(AuthAction.register, {
          'email': 'lan@example.com',
          'password': 'mật khẩu có số 7',
          'termsAccepted': 'true',
        })).isRight(),
        true,
      );
      expect(api.calls, before + 1);
      await useCases.submit(AuthAction.login, {
        'email': 'lan@example.com',
        'password': 'no digits in this one',
      });
      expect(api.calls, before + 2);
      expect(
        (await useCases.setupPin('123456', '654321', false, 'unlock')).isLeft(),
        true,
      );
      // Only the two valid submissions above reached the API.
      expect(api.calls, calls + 2);
    },
  );
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
  test(
    'enabling biometrics keeps the flag unchanged when confirmation fails',
    () async {
      await setup();
      biometrics.accepted = false;
      expect(
        (await repository.setBiometricEnabled(true, 'unlock')).isLeft(),
        true,
      );
      expect(jsonDecode(vault.value!)['biometrics'], false);
      expect(biometrics.calls, 1);
      biometrics.accepted = true;
      expect(
        (await repository.setBiometricEnabled(true, 'unlock')).isRight(),
        true,
      );
      final calls = biometrics.calls;
      expect(
        (await repository.setBiometricEnabled(false, 'unlock')).isRight(),
        true,
      );
      expect(biometrics.calls, calls);
      expect(jsonDecode(vault.value!)['biometrics'], false);
    },
  );
  test('biometrics cannot be enabled before a PIN exists', () async {
    await login();
    expect(
      (await repository.setBiometricEnabled(
        true,
        'unlock',
      )).fold((f) => f.code, (_) => null),
      AuthError.invalidInput,
    );
    expect(biometrics.calls, 0);
  });
  test('expired stored session requires login', () async {
    await setup();
    final record = jsonDecode(vault.value!) as Map<String, dynamic>;
    record['expiresAt'] = DateTime.now()
        .subtract(const Duration(seconds: 1))
        .toIso8601String();
    vault.value = jsonEncode(record);
    expect(
      (await repository.restore()).fold((f) => f.code, (_) => null),
      AuthError.expired,
    );
    expect(vault.value, isNull);
  });
  test(
    'new sessions seed once, alert once, and logout clears the record',
    () async {
      Map<String, dynamic> session(String id, {required bool current}) => {
        'id': id,
        'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
        'expiresAt': DateTime.utc(2026, 1, 8).toIso8601String(),
        'current': current,
      };
      api.sessionItems = [
        session('current', current: true),
        session('other', current: false),
      ];
      await setup();
      final seeded = await repository.observeSessions();
      expect(seeded.getOrElse(() => throw StateError('seed')).alert, isFalse);
      expect(vault.seen, contains('current'));
      expect(vault.seen, contains('other'));
      final again = await repository.observeSessions();
      expect(again.getOrElse(() => throw StateError('again')).alert, isFalse);
      api.sessionItems = [
        session('current', current: true),
        session('other', current: false),
        session('newer', current: false),
      ];
      final noticed = await repository.observeSessions();
      expect(noticed.getOrElse(() => throw StateError('notice')).alert, isTrue);
      final repeat = await repository.observeSessions();
      expect(repeat.getOrElse(() => throw StateError('repeat')).alert, isFalse);
      final remembered = vault.seen;
      api.failure = const AuthFailure(AuthError.network);
      expect((await repository.observeSessions()).isLeft(), isTrue);
      expect(vault.seen, remembered);
      api.failure = null;
      api.sessionItems = [session('current', current: true)];
      final dropped = await repository.observeSessions();
      expect(dropped.getOrElse(() => throw StateError('drop')).alert, isFalse);
      expect(vault.seen, isNot(contains('other')));
      await repository.logout();
      expect(vault.seen, isNull);
      expect(vault.value, isNull);
    },
  );
  test('corrupt seen sessions do not overwrite the stored list', () async {
    await setup();
    vault.seen = '{"email":"user@example.com"}';
    expect(
      (await repository.observeSessions()).fold((f) => f.code, (_) => null),
      AuthError.storage,
    );
    expect(vault.seen, contains('email'));
  });
  test('the current session alone does not raise an alert', () async {
    await setup();
    vault.seen = '["older"]';
    api.sessionItems = [
      {
        'id': 'current',
        'createdAt': DateTime.utc(2026, 1, 2).toIso8601String(),
        'expiresAt': DateTime.utc(2026, 1, 9).toIso8601String(),
        'current': true,
      },
    ];
    final decision = await repository.observeSessions();
    expect(
      decision.getOrElse(() => throw StateError('current')).alert,
      isFalse,
    );
    expect(vault.seen, '["current"]');
  });

  group('DS-P2-003 account security', () {
    test('keeps the sign-in email on the device and hands it back', () async {
      await setup();
      expect(
        (await repository.accountEmail()).getOrElse(() => null),
        'user@example.com',
      );
    });

    test(
      'changing the PIN needs the old one and then unlocks only with the new',
      () async {
        await setup();
        expect((await repository.changePin('000000', '654321')).isLeft(), true);
        expect((await repository.changePin('123456', '12ab56')).isLeft(), true);
        expect(
          (await repository.changePin('123456', '654321')).isRight(),
          true,
        );
        expect(vault.value, isNot(contains('654321')));
        final restarted = AuthRepositoryImpl(api, vault, biometrics);
        await restarted.restore();
        expect((await restarted.unlockPin('123456')).isLeft(), true);
        expect((await restarted.unlockPin('654321')).isRight(), true);
      },
    );

    test('a wrong old PIN counts as an unlock attempt and the fifth clears the device', () async {
      await setup();
      Object? last;
      for (var i = 0; i < 5; i++) {
        last = (await repository.changePin(
          '000000',
          '654321',
        )).fold((e) => e.code, (_) => null);
      }
      expect(last, AuthError.expired);
      expect(vault.value, isNull);
    });

    test(
      'change password posts both passwords and leaves this session alone',
      () async {
        await setup();
        final done = await repository.changePassword(
          'old password 12345',
          'new password 12345',
        );
        expect(done.isRight(), true);
        expect(api.lastPath, 'auth/change-password');
        expect(api.lastBody, {
          'currentPassword': 'old password 12345',
          'newPassword': 'new password 12345',
        });
        expect(vault.value, isNotNull);
      },
    );

    test('revokeOthers ends every session but the current one', () async {
      await setup();
      final now = DateTime.now().toIso8601String();
      final later = DateTime.now()
          .add(const Duration(days: 5))
          .toIso8601String();
      api.sessionItems = [
        {
          'id': 'current',
          'createdAt': now,
          'expiresAt': later,
          'current': true,
        },
        {
          'id': 'other-1',
          'createdAt': now,
          'expiresAt': later,
          'current': false,
        },
        {
          'id': 'other-2',
          'createdAt': now,
          'expiresAt': later,
          'current': false,
        },
      ];
      expect((await repository.revokeOthers()).isRight(), true);
      expect(api.lastPath, 'sessions/other-2');
      expect(vault.value, isNotNull);
    });

    test('use cases check the rules before asking the server', () async {
      final cases = DefaultAuthUseCases(repository);
      Future<AuthError?> pin(String a, String b, String c) async =>
          (await cases.changePin(a, b, c)).fold((e) => e.code, (_) => null);
      expect(await pin('123456', '654321', '654322'), AuthError.passwordMismatch);
      expect(await pin('123456', '123456', '123456'), AuthError.invalidInput);
      expect(await pin('12345', '654321', '654321'), AuthError.invalidInput);
      Future<AuthError?> password(String a, String b, String c) async =>
          (await cases.changePassword(
            a,
            b,
            c,
          )).fold((e) => e.code, (_) => null);
      expect(
        await password('old', 'new password 12345', 'other password 12345'),
        AuthError.passwordMismatch,
      );
      expect(
        await password('old', 'no digits in this one', 'no digits in this one'),
        AuthError.invalidInput,
      );
      expect(
        await password(
          'same password 12345',
          'same password 12345',
          'same password 12345',
        ),
        AuthError.invalidInput,
      );
      expect(
        await password('', 'new password 12345', 'new password 12345'),
        AuthError.invalidInput,
      );
      expect(api.calls, 0);
    });
  });
}
