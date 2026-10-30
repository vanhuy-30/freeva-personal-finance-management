import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/onboarding/domain/onboarding_answers.dart';
import 'package:mobile/features/profile/data/profile_repository_impl.dart';
import 'package:mobile/features/profile/domain/profile_use_cases.dart';
import 'package:mobile/features/profile/presentation/viewmodels/profile_view_model.dart';

import '../auth/fakes.dart';
import 'fakes.dart';

void main() {
  test(
    'use case accepts days 1 and 28, rejects invalid fields without writes',
    () async {
      final repo = MemoryProfiles();
      final cases = ProfileUseCases(repo);
      final options = (await repo.options()).getOrElse(
        () => throw StateError('options'),
      );
      for (final profile in [
        initial.copyWith(fiscalDay: 0),
        initial.copyWith(fiscalDay: 29),
        initial.copyWith(locale: 'fr'),
        initial.copyWith(currency: 'XXX'),
        initial.copyWith(timezone: '+07:00'),
      ]) {
        expect((await cases.save(profile, options)).isLeft(), true);
      }
      expect(repo.saves, 0);
      expect((await cases.save(initial, options)).isRight(), true);
      expect(
        (await cases.save(initial.copyWith(fiscalDay: 28), options)).isRight(),
        true,
      );
    },
  );
  test(
    'repository serializes integer day/version and rejects malformed response',
    () async {
      final api = Transport();
      final repo = ProfileRepositoryImpl(api);
      api.response = {
        'locale': 'en',
        'defaultCurrencyCode': 'USD',
        'timezone': 'UTC',
        'fiscalMonthStartDay': 28,
        'version': 2,
      };
      expect((await repo.save(initial)).isRight(), true);
      expect(api.body!['fiscalMonthStartDay'], isA<int>());
      expect(api.body!['version'], 1);
      api.response['fiscalMonthStartDay'] = 29;
      expect((await repo.load()).isLeft(), true);
      api.failure = const AuthFailure(AuthError.expired);
      expect(
        (await repo.load()).fold((e) => e.code, (_) => null),
        AuthError.expired,
      );
    },
  );
  test(
    'budget goes out as a string and the profile reads the saved answers',
    () async {
      final api = Transport();
      final repo = ProfileRepositoryImpl(api);
      final cases = ProfileUseCases(repo);
      expect(
        (await cases.saveOnboarding(
          OnboardingAnswers(budgetMinor: BigInt.from(15000000)),
        )).isRight(),
        true,
      );
      expect(api.body, {'budgetMinor': '15000000'});
      api.method = null;
      expect(
        (await cases.saveOnboarding(
          OnboardingAnswers(budgetMinor: BigInt.zero),
        )).isLeft(),
        true,
      );
      expect(api.method, isNull);
      api.response = {
        'locale': 'vi',
        'defaultCurrencyCode': 'VND',
        'timezone': 'UTC',
        'fiscalMonthStartDay': 1,
        'version': 1,
        'goals': ['save'],
        'trackingHabit': 'app',
        'reviewCadence': 'weekly',
        'onboardingBudgetMinor': '15000000',
      };
      final loaded = (await repo.load()).getOrElse(() => throw StateError('x'));
      expect(loaded.habit, 'app');
      expect(loaded.cadence, 'weekly');
      expect(loaded.budgetMinor, BigInt.from(15000000));
      api.response = {
        ...api.response,
        'onboardingBudgetMinor': 'abc',
        'trackingHabit': null,
      };
      final bad = (await repo.load()).getOrElse(() => throw StateError('x'));
      expect(bad.budgetMinor, isNull);
      expect(bad.habit, isNull);
    },
  );
  test(
    'onboarding answers go out as a PATCH with only the set parts',
    () async {
      final api = Transport();
      final repo = ProfileRepositoryImpl(api);
      final cases = ProfileUseCases(repo);
      expect(
        (await cases.saveOnboarding(
          const OnboardingAnswers(
            goals: [OnboardingGoal.save, OnboardingGoal.debt],
          ),
        )).isRight(),
        true,
      );
      expect(api.method, 'PATCH');
      expect(api.path, 'profile/onboarding');
      expect(api.body, {
        'goals': ['save', 'debt'],
      });
      api.method = null;
      expect(
        (await cases.saveOnboarding(const OnboardingAnswers())).isRight(),
        true,
      );
      expect(api.method, isNull);
      expect(
        (await cases.saveOnboarding(
          const OnboardingAnswers(
            goals: [
              OnboardingGoal.save,
              OnboardingGoal.debt,
              OnboardingGoal.track,
            ],
          ),
        )).isLeft(),
        true,
      );
    },
  );
  test(
    'reads displayName and sends it back on save (null clears it)',
    () async {
      final api = Transport();
      final repo = ProfileRepositoryImpl(api);
      api.response = {
        'displayName': '  Minh ',
        'locale': 'vi',
        'defaultCurrencyCode': 'VND',
        'timezone': 'UTC',
        'fiscalMonthStartDay': 1,
        'version': 1,
      };
      final loaded = (await repo.load()).getOrElse(() => throw StateError('x'));
      expect(loaded.displayName, 'Minh');
      await repo.save(loaded);
      expect(api.body!['displayName'], 'Minh');
      await repo.save(loaded.copyWith(displayName: null));
      expect(api.body!.containsKey('displayName'), isTrue);
      expect(api.body!['displayName'], isNull);
      api.response['displayName'] = null;
      expect(
        (await repo.load()).getOrElse(() => throw StateError('x')).displayName,
        isNull,
      );
    },
  );
  group('view model', () {
    late MemoryProfiles repo;
    late DefaultAuthViewModel auth;
    late DefaultProfileViewModel model;
    late FakeApi api;
    late FakeSharer sharer;
    late AuthRepositoryImpl authRepo;
    setUp(() async {
      api = FakeApi();
      sharer = FakeSharer();
      authRepo = AuthRepositoryImpl(api, MemoryVault(), FakeBiometrics());
      await authRepo.submit(AuthAction.login, {
        'email': 'user@example.com',
        'password': 'password long enough',
      });
      auth = DefaultAuthViewModel(DefaultAuthUseCases(authRepo));
      auth.stage = AuthStage.unlocked;
      auth.hasPin = true;
      repo = MemoryProfiles();
      model = DefaultProfileViewModel(
        ProfileUseCases(repo),
        auth,
        exportCase(authRepo, sharer),
      );
      await Future<void>.delayed(Duration.zero);
    });
    tearDown(() {
      model.dispose();
      auth.dispose();
    });
    test(
      'the saved name is handed to the lock screen on load and on save',
      () async {
        repo.value = repo.value.copyWith(displayName: 'Minh');
        await model.load();
        expect(auth.name, 'Minh');
        model.draft = model.saved!.copyWith(displayName: ' Lan ');
        await model.save();
        expect(auth.name, 'Lan');
      },
    );
    test(
      'applies locale only after save, reloads saved fields and cancels edits',
      () async {
        model.edit(
          model.draft!.copyWith(
            locale: 'en',
            currency: 'USD',
            timezone: 'America/New_York',
            fiscalDay: 28,
          ),
        );
        expect(model.locale, 'vi');
        await model.save();
        expect(model.locale, 'en');
        expect(model.saved!.version, 2);
        expect(model.dirty, false);
        model.edit(model.draft!.copyWith(fiscalDay: 2));
        model.cancel();
        expect(model.draft!.fiscalDay, 28);
        await model.load();
        expect(model.draft!.timezone, 'America/New_York');
      },
    );
    test('failure preserves draft and duplicate saves cannot race', () async {
      repo.failure = const AuthFailure(AuthError.network);
      model.edit(model.draft!.copyWith(locale: 'en'));
      final pending = Completer<void>();
      repo.pending = pending.future;
      final saving = model.save();
      await model.save();
      expect(repo.saves, 1);
      pending.complete();
      await saving;
      expect(model.locale, 'vi');
      expect(model.draft!.locale, 'en');
      expect(model.failure!.code, AuthError.network);
      expect(model.loading, false);
    });
    test(
      'conflict requires reload; server values replace stale draft',
      () async {
        model.edit(model.draft!.copyWith(fiscalDay: 28));
        repo.failure = const AuthFailure(AuthError.conflict);
        await model.save();
        expect(model.failure!.code, AuthError.conflict);
        expect(model.saved!.fiscalDay, 1);
        repo.failure = null;
        repo.value = initial.copyWith(fiscalDay: 10);
        await model.load();
        expect(model.draft!.fiscalDay, 10);
        expect(model.dirty, false);
      },
    );
    test(
      'late save after lock never restores profile or applies locale',
      () async {
        model.edit(model.draft!.copyWith(locale: 'en'));
        final pending = Completer<void>();
        repo.pending = pending.future;
        final saving = model.save();
        auth.lock();
        pending.complete();
        await saving;
        expect(model.saved, null);
        expect(model.draft, null);
        expect(model.locale, 'vi');
      },
    );
    test(
      'late load after logout cannot leak previous account preferences',
      () async {
        final pending = Completer<void>();
        repo.pending = pending.future;
        repo.value = initial.copyWith(locale: 'en');
        final loading = model.load();
        await auth.forgetDevice();
        pending.complete();
        await loading;
        expect(model.saved, null);
        expect(model.locale, 'vi');
      },
    );
    test('expired session clears profile and returns to signed out', () async {
      repo.failure = const AuthFailure(AuthError.expired);
      await model.load();
      expect(auth.stage, AuthStage.signedOut);
      expect(model.saved, null);
      expect(model.loading, false);
    });
  });

  group('account export and delete', () {
    late FakeApi api;
    late MemoryVault vault;
    late AuthRepositoryImpl authRepo;
    late FakeSharer sharer;
    late DefaultAuthViewModel auth;
    late DefaultProfileViewModel model;
    setUp(() async {
      api = FakeApi();
      vault = MemoryVault();
      sharer = FakeSharer();
      authRepo = AuthRepositoryImpl(api, vault, FakeBiometrics());
      await authRepo.submit(AuthAction.login, {
        'email': 'user@example.com',
        'password': 'password long enough',
      });
      auth = DefaultAuthViewModel(DefaultAuthUseCases(authRepo));
      auth.stage = AuthStage.unlocked;
      model = DefaultProfileViewModel(
        ProfileUseCases(MemoryProfiles()),
        auth,
        exportCase(authRepo, sharer),
      );
      await Future<void>.delayed(Duration.zero);
    });
    tearDown(() {
      model.dispose();
      auth.dispose();
    });

    test('export shares the API body unchanged', () async {
      api.exportBody = '{"b":1,\n "a":[ 2 ]}';
      expect(await model.exportData(), isTrue);
      expect(api.lastPath, 'account/export');
      expect(sharer.content, '{"b":1,\n "a":[ 2 ]}');
      expect(sharer.name, matches(RegExp(r'^freeva-export-\d{8}\.json$')));
      expect(model.exporting, isFalse);
      expect(model.failure, isNull);
    });

    test('dismissed share sheet is not a failure', () async {
      sharer.result = false;
      expect(await model.exportData(), isFalse);
      expect(model.failure, isNull);
    });

    test('network error on export keeps session and shares nothing', () async {
      api.failure = const AuthFailure(AuthError.network);
      expect(await model.exportData(), isFalse);
      expect(model.failure?.code, AuthError.network);
      expect(sharer.content, isNull);
      expect(vault.value, isNotNull);
    });

    test('share failure surfaces as a failure', () async {
      sharer.fail = true;
      expect(await model.exportData(), isFalse);
      expect(model.failure, isNotNull);
      expect(model.exporting, isFalse);
    });

    test('delete clears session and goes signed out', () async {
      await auth.deleteAccount();
      expect(api.lastPath, 'account');
      expect(auth.stage, AuthStage.signedOut);
      expect(vault.value, isNull);
    });

    test(
      'network error on delete keeps everything and stays signed in',
      () async {
        api.failure = const AuthFailure(AuthError.network);
        await auth.deleteAccount();
        expect(auth.failure?.code, AuthError.network);
        expect(auth.stage, AuthStage.unlocked);
        expect(vault.value, isNotNull);
      },
    );

    test('server refusal on delete keeps everything', () async {
      api.failure = const AuthFailure(AuthError.unavailable);
      await auth.deleteAccount();
      expect(auth.stage, AuthStage.unlocked);
      expect(vault.value, isNotNull);
    });
  });
}
