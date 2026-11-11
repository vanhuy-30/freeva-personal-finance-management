import 'package:flutter_test/flutter_test.dart';

import '../../support/server_config_fixture.dart';

import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/goals/domain/goal.dart';
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
      settings,
      goals,
      pending,
      null,
      limits: testServerConfigModel(),
      today: DateTime(2026, 11, 5),
      previewDelay: Duration.zero,
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
    await model.settlePreview();
  }

  test('at most two goals; the third stops being pickable', () {
    model.toggleGoal(OnboardingGoal.track);
    model.toggleGoal(OnboardingGoal.save);
    model.toggleGoal(OnboardingGoal.budget);
    expect(model.goals, [OnboardingGoal.track, OnboardingGoal.save]);
    expect(model.canPickGoal(OnboardingGoal.budget), isFalse);
    model.toggleGoal(OnboardingGoal.save);
    expect(model.canPickGoal(OnboardingGoal.budget), isTrue);
  });

  test(
    'only goals and income go to the server; skipping sends nothing',
    () async {
      await model.saveGoals();
      await model.saveIncome();
      expect(profiles.onboarding, isEmpty);
      model.toggleGoal(OnboardingGoal.track);
      await model.saveGoals();
      model.setIncome(25000000);
      await model.saveIncome();
      expect(profiles.onboarding.map((a) => a.toJson()), [
        {
          'goals': ['track'],
        },
        {'monthlyIncomeMinor': '25000000'},
      ]);
    },
  );

  test('a failed save never throws', () async {
    profiles.failure = const AuthFailure(AuthError.network);
    model.toggleGoal(OnboardingGoal.track);
    await model.saveGoals();
    expect(profiles.onboarding, isEmpty);
  });

  test('income keys: no leading zeros, 12 digit cap, delete', () {
    model.typeIncome('0');
    expect(model.income, BigInt.zero);
    model.typeIncome('1');
    model.typeIncome('000');
    expect(model.income, BigInt.from(1000));
    model.deleteIncomeDigit();
    expect(model.income, BigInt.from(100));
    for (var i = 0; i < 6; i++) {
      model.typeIncome('000');
    }
    expect(model.income.toString().length, lessThanOrEqualTo(12));
  });

  test('the monthly saving shown is the server preview', () async {
    await fillSaving();
    expect(goals.previews.single, ('VND', BigInt.from(60000000), '2027-09-05'));
    expect(model.preview?.requiredPerMonthMinor, BigInt.from(6000000));
    expect(model.preview?.incomeShareBps, 2400);
  });

  test('budget suggestion: income minus the goal, else minus 20%', () async {
    expect(model.suggestion, isNull);
    model.setIncome(25000000);
    final plain = model.suggestion!;
    expect(plain.fromGoal, isFalse);
    expect(plain.saving, BigInt.from(5000000));
    expect(plain.spending, BigInt.from(20000000));
    await fillSaving();
    final withGoal = model.suggestion!;
    expect(withGoal.fromGoal, isTrue);
    expect(withGoal.saving, BigInt.from(6000000));
    expect(withGoal.spending, BigInt.from(19000000));
    goals.previewResult = GoalPreview(
      monthsLeft: 1,
      requiredPerMonthMinor: BigInt.from(60000000),
    );
    model.pickDate('2026-12-01');
    await model.settlePreview();
    expect(model.suggestion, isNull, reason: 'nothing left to spend');
  });

  test('"Dùng mức này" keeps a device draft when no budget API', () async {
    model.setIncome(25000000);
    await model.useSuggestion();
    final saved = (await settings.load()).getOrElse(
      () => throw StateError('x'),
    );
    expect(saved.budgetDraftMinor, 20000000);
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
