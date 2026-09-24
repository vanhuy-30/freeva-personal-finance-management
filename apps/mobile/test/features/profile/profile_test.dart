import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
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
  group('view model', () {
    late MemoryProfiles repo;
    late DefaultAuthViewModel auth;
    late DefaultProfileViewModel model;
    setUp(() async {
      auth = DefaultAuthViewModel(
        DefaultAuthUseCases(
          AuthRepositoryImpl(FakeApi(), MemoryVault(), FakeBiometrics()),
        ),
      );
      auth.stage = AuthStage.unlocked;
      repo = MemoryProfiles();
      model = DefaultProfileViewModel(ProfileUseCases(repo), auth);
      await Future<void>.delayed(Duration.zero);
    });
    tearDown(() {
      model.dispose();
      auth.dispose();
    });
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
}
