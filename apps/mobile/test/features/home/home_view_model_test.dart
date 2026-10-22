import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/home/presentation/viewmodels/home_view_model.dart';
import 'package:mobile/features/settings/data/settings_repository_impl.dart';
import 'package:mobile/features/settings/domain/settings_use_cases.dart';
import 'package:mobile/features/settings/presentation/viewmodels/settings_view_model.dart';

import '../auth/fakes.dart';
import '../settings/fakes.dart' show MemoryPreferences;
import '../transactions/transaction_view_model_test.dart'
    show RecordingAnalytics;
import 'fixtures.dart';
import 'home_fakes.dart';

void main() {
  late DefaultAuthViewModel auth;
  late DefaultSettingsViewModel settings;
  late FakeOverviewCases cases;
  late FakeSyncViewModel sync;
  late DefaultHomeViewModel model;

  setUp(() async {
    final authCases = DefaultAuthUseCases(
      AuthRepositoryImpl(FakeApi(), MemoryVault(), FakeBiometrics()),
    );
    auth = DefaultAuthViewModel(authCases)
      ..stage = AuthStage.unlocked
      ..ready = true;
    settings = DefaultSettingsViewModel(
      DefaultSettingsUseCases(SettingsRepositoryImpl(MemoryPreferences())),
      authCases,
      RecordingAnalytics(),
    );
    await settings.load();
    cases = FakeOverviewCases();
    sync = FakeSyncViewModel();
    model = DefaultHomeViewModel(
      cases,
      auth,
      FakeProfileViewModel(),
      settings,
      sync,
    );
  });

  tearDown(() {
    model.dispose();
    settings.dispose();
    auth.dispose();
  });

  test('starts loading, then shows fresh data', () async {
    cases.results.add(right(overview()));
    expect(model.status, HomeStatus.loading);
    await model.load();
    expect(model.status, HomeStatus.ready);
    expect(model.data, isNotNull);
    expect(model.displayName, 'Minh');
  });

  test('first load failing shows the error card', () async {
    cases.results.add(left(const AuthFailure(AuthError.network)));
    await model.load();
    expect(model.status, HomeStatus.error);
    expect(model.data, isNull);
  });

  test('a later failure keeps the last data as offline', () async {
    final data = overview();
    cases.results
      ..add(right(data))
      ..add(left(const AuthFailure(AuthError.network)));
    await model.load();
    await model.load();
    expect(model.status, HomeStatus.offline);
    expect(model.data, same(data));
  });

  test('synced changes trigger a reload', () async {
    cases.results.add(right(overview()));
    await model.load();
    sync.applied();
    await Future<void>.delayed(Duration.zero);
    expect(cases.calls, 2);
  });

  test('locking drops balances from memory', () async {
    cases.results.add(right(overview()));
    await model.load();
    auth.stage = AuthStage.locked;
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    auth.notifyListeners();
    expect(model.data, isNull);
    expect(model.status, HomeStatus.loading);
  });

  test('the eye toggles the hide-balances preference', () async {
    expect(model.balancesHidden, isFalse);
    await model.toggleBalances();
    expect(settings.balancesHidden, isTrue);
  });
}
