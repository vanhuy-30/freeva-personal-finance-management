import 'package:flutter_test/flutter_test.dart';

import '../../support/server_config_fixture.dart';

import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/onboarding/domain/onboarding_answers.dart';
import 'package:mobile/features/onboarding/domain/pending_goal.dart';
import 'package:mobile/features/onboarding/domain/pending_goal_use_cases.dart';
import 'package:mobile/features/onboarding/presentation/viewmodels/onboarding_view_model.dart';
import 'package:mobile/features/profile/domain/profile_use_cases.dart';
import 'package:mobile/features/settings/data/settings_repository_impl.dart';
import 'package:mobile/features/settings/domain/settings_use_cases.dart';
import 'package:mobile/features/wallets/domain/wallet.dart';
import 'package:mobile/features/wallets/domain/wallet_use_cases.dart';

import '../auth/setup_deps.dart';
import '../goals/goal_stub.dart';
import '../profile/fakes.dart';
import '../settings/fakes.dart';

void main() {
  late MemoryProfiles profiles;
  late MemoryPreferences preferences;
  late DefaultSettingsUseCases settings;
  late FakeGoalUseCases goals;
  late MemoryWalletRepository wallets;
  late EmailAuth auth;
  late PendingGoalUseCases pending;
  late OnboardingViewModel model;

  setUp(() {
    profiles = MemoryProfiles();
    preferences = MemoryPreferences();
    settings = DefaultSettingsUseCases(SettingsRepositoryImpl(preferences));
    goals = FakeGoalUseCases(goals: []);
    wallets = MemoryWalletRepository();
    auth = EmailAuth();
    pending = PendingGoalUseCases(
      settings,
      goals,
      DefaultWalletUseCases(wallets, testServerConfigModel()),
      auth,
    );
    model = OnboardingViewModel(
      ProfileUseCases(profiles, testServerConfigModel()),
      pending,
      limits: testServerConfigModel(),
      today: DateTime(2026, 11, 5),
    );
  });
  tearDown(() => model.dispose());

  Future<Map<String, String>?> pendingGoal() async => (await settings.load())
      .getOrElse(() => throw StateError('x'))
      .pendingGoal;

  Future<void> fillSaving() async {
    model.pickKind('home');
    model.setTargetMinor(BigInt.from(60000000));
    model.pickDate('2027-09-05');
  }

  test('any number of goals, saved in the board order', () async {
    model.toggleGoal(OnboardingGoal.habits);
    model.toggleGoal(OnboardingGoal.track);
    model.toggleGoal(OnboardingGoal.debt);
    expect(model.canPickGoal(OnboardingGoal.assets), isTrue);
    await model.saveGoals();
    expect(profiles.onboarding.single.toJson(), {
      'goals': ['track', 'debt', 'habits'],
    });
  });

  test('only goals and the income band go to the server; skipping and "Không '
      'muốn chia sẻ" send nothing', () async {
    await model.saveGoals();
    await model.saveIncome();
    expect(profiles.onboarding, isEmpty);
    model.pickNotShared();
    await model.saveIncome();
    expect(profiles.onboarding, isEmpty);
    model.toggleGoal(OnboardingGoal.track);
    await model.saveGoals();
    expect(model.incomeBands.length, 5);
    model.pickIncome(model.incomeBands[2]);
    expect(model.incomeNotShared, isFalse);
    await model.saveIncome();
    expect(profiles.onboarding.map((a) => a.toJson()), [
      {
        'goals': ['track'],
      },
      {
        'declaredIncome': {'minMinor': '10000000', 'maxMinor': '20000000'},
      },
    ]);
  });

  test('a failed save never throws', () async {
    profiles.failure = const AuthFailure(AuthError.network);
    model.toggleGoal(OnboardingGoal.track);
    await model.saveGoals();
    expect(profiles.onboarding, isEmpty);
  });

  test('"Khác" needs a name and keeps it as the goal name', () async {
    model.pickKind('custom');
    model.setTargetMinor(BigInt.from(20000000));
    model.pickDate('2027-01-05');
    expect(model.savingReady, isFalse);
    model.setCustomName('  Mua laptop  ');
    expect(model.savingReady, isTrue);
    await model.keepSavingGoal('Khác');
    expect((await pendingGoal())!['name'], 'Mua laptop');
  });

  test('the saving goal waits for a wallet, then is created once', () async {
    await fillSaving();
    await model.keepSavingGoal('Mua nhà');
    expect(await pendingGoal(), isNotNull);
    expect(await pending.flush(), isFalse, reason: 'no wallet yet');
    expect(goals.created, isEmpty);
    await wallets.save(
      WalletDraft(
        name: 'Thẻ',
        type: WalletType.credit,
        currency: 'VND',
        initialBalance: BigInt.zero,
        creditLimit: BigInt.from(1),
        closeDay: 1,
        dueDay: 10,
      ),
      clientId: 'c1',
    );
    expect(await pending.flush(), isFalse, reason: 'never a credit card');
    await wallets.save(
      WalletDraft(
        name: 'Tiền mặt',
        type: WalletType.cash,
        currency: 'VND',
        initialBalance: BigInt.zero,
      ),
      clientId: 'c2',
    );
    expect(await pending.flush(), isTrue);
    final draft = goals.created.single;
    expect(draft.name, 'Mua nhà');
    expect(draft.kind, 'home');
    expect(draft.accountId, 'w2');
    expect(draft.targetMinor, BigInt.from(60000000));
    expect(draft.targetDate, '2027-09-05');
    expect(await pendingGoal(), isNull);
    expect(await pending.flush(), isFalse);
  });

  test('another account signing in on this device drops the draft', () async {
    await fillSaving();
    await model.keepSavingGoal('Mua nhà');
    auth.email = 'other@example.test';
    expect(await pending.flush(), isFalse);
    expect(await pendingGoal(), isNull);
    expect(goals.created, isEmpty);
  });

  test('a broken stored draft is ignored', () {
    expect(PendingGoal.fromJson({'owner': 'x'}), isNull);
  });
}
