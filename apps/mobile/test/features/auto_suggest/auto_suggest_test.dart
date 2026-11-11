import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auto_suggest/data/auto_suggest_repository_impl.dart';
import 'package:mobile/features/auto_suggest/presentation/viewmodels/auto_suggest_view_model.dart';
import 'package:mobile/features/profile/data/profile_repository_impl.dart';
import 'package:mobile/features/server_config/domain/server_config.dart';

import '../profile/fakes.dart';
import 'auto_suggest_fakes.dart';

void main() {
  group('data', () {
    test('reads the merchant list and calls the right endpoints', () async {
      final api = Transport()
        ..response = {
          'items': [
            {
              'id': 'a',
              'merchant': 'Highlands Coffee',
              'category': {
                'id': 'cat',
                'name': 'Cà phê',
                'iconToken': 'coffee',
                'colorToken': null,
              },
              'updatedAt': '2026-11-10T03:00:00.000Z',
            },
          ],
          'total': 1,
        };
      final repo = AutoSuggestRepositoryImpl(api);
      final list = (await repo.mappings()).getOrElse(
        () => throw StateError(''),
      );
      expect(api.method, 'GET');
      expect(api.path, 'category-suggestions/mappings');
      expect(list.single.merchant, 'Highlands Coffee');
      expect(list.single.categoryName, 'Cà phê');
      expect(list.single.iconToken, 'coffee');
      expect(list.single.colorToken, isNull);
      expect(list.single.updatedAt, DateTime.utc(2026, 11, 10, 3));

      api.response = {'items': 'nope'};
      expect((await repo.mappings()).isLeft(), isTrue);

      api.response = {};
      expect((await repo.setEnabled(false)).isRight(), isTrue);
      expect((api.method, api.path), ('PUT', 'profile/auto-suggest'));
      expect(api.body, {'enabled': false});
      await repo.forget('a');
      expect(
        (api.method, api.path),
        ('DELETE', 'category-suggestions/mappings/a'),
      );
      await repo.clear();
      expect(
        (api.method, api.path),
        ('DELETE', 'category-suggestions/mappings'),
      );
    });

    test(
      'profile reads autoSuggestEnabled (default on), never PUTs it',
      () async {
        final api = Transport();
        final repo = ProfileRepositoryImpl(api);
        api.response = {
          'locale': 'vi',
          'defaultCurrencyCode': 'VND',
          'timezone': 'UTC',
          'fiscalMonthStartDay': 1,
          'version': 1,
        };
        Future<bool> flag() async => (await repo.load())
            .getOrElse(() => throw StateError(''))
            .autoSuggestEnabled;
        expect(await flag(), isTrue);
        api.response['autoSuggestEnabled'] = false;
        expect(await flag(), isFalse);
        final off = (await repo.load()).getOrElse(() => throw StateError(''));
        expect(off.withDisplayCurrency('USD').autoSuggestEnabled, isFalse);
        expect(off.copyWith(locale: 'en').autoSuggestEnabled, isFalse);
        await repo.save(off);
        expect(api.body!.containsKey('autoSuggestEnabled'), isFalse);
      },
    );
  });

  group('view model', () {
    late MemoryAutoSuggest repo;
    late FakeFlags flags;
    late FakeProfile profile;
    late FakeAuth auth;
    late DefaultAutoSuggestViewModel model;

    setUp(() {
      repo = MemoryAutoSuggest();
      flags = FakeFlags();
      profile = FakeProfile();
      auth = FakeAuth();
      model = DefaultAutoSuggestViewModel(repo, flags, profile, auth);
    });
    tearDown(() => model.dispose());

    test('row shows when any of the three flags is on', () {
      expect(model.available, isFalse);
      flags
        ..on = {FeatureFlags.forecast}
        ..notifyListeners();
      expect(model.available, isTrue);
    });

    test('switch saves at once and reverts on failure', () async {
      expect(model.enabled, isTrue);
      expect(await model.setEnabled(false), isTrue);
      expect(model.enabled, isFalse);
      expect(repo.enabledCalls, [false]);

      repo.failure = const AuthFailure(AuthError.network);
      final pending = model.setEnabled(true);
      expect(model.enabled, isTrue, reason: 'optimistic');
      expect(await pending, isFalse);
      expect(model.enabled, isFalse);
    });

    test('forget removes one row; already gone counts as done', () async {
      await model.load();
      expect(model.mappings, hasLength(6));
      final first = model.mappings.first;
      expect(await model.forget(first), isTrue);
      expect(model.mappings.map((m) => m.id), isNot(contains(first.id)));
      expect(repo.forgotten, [first.id]);

      // 404: the server no longer has it.
      final second = model.mappings.first;
      repo
        ..forgetFailure = const AuthFailure(AuthError.unavailable)
        ..items = repo.items.where((m) => m.id != second.id).toList();
      expect(await model.forget(second), isTrue);
      expect(model.mappings, hasLength(4));

      // Real failure: the row comes back in place.
      final third = model.mappings[1];
      expect(await model.forget(third), isFalse);
      expect(model.mappings[1].id, third.id);
    });

    test('clear all empties the list, restores it on failure', () async {
      await model.load();
      repo.failure = const AuthFailure(AuthError.network);
      expect(await model.clearAll(), isFalse);
      expect(model.mappings, hasLength(6));
      repo.failure = null;
      expect(await model.clearAll(), isTrue);
      expect(model.mappings, isEmpty);
      expect(repo.clears, 1);
    });

    test('empty list stays empty and loaded', () async {
      repo.items = [];
      await model.load();
      expect(model.loaded, isTrue);
      expect(model.mappings, isEmpty);
    });

    test('expired session signs out and a new stage resets state', () async {
      await model.load();
      repo.failure = const AuthFailure(AuthError.expired);
      await model.setEnabled(false);
      expect(auth.expired, 1);
      auth
        ..stage = AuthStage.locked
        ..notifyListeners();
      expect(model.mappings, isEmpty);
      expect(model.loaded, isFalse);
    });
  });
}
