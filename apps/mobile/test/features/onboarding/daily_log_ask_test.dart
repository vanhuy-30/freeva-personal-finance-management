import 'dart:io';

import '../../support/server_config_fixture.dart';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/notifications/domain/notification_models.dart';
import 'package:mobile/features/notifications/domain/notification_use_cases.dart';
import 'package:mobile/features/onboarding/domain/pending_goal_use_cases.dart';
import 'package:mobile/features/onboarding/presentation/viewmodels/first_run_nudges_view_model.dart';
import 'package:mobile/features/onboarding/presentation/widgets/budget_ask_sheet.dart';
import 'package:mobile/features/onboarding/presentation/widgets/daily_log_ask_sheet.dart';
import 'package:mobile/features/settings/data/settings_repository_impl.dart';
import 'package:mobile/features/settings/domain/settings_use_cases.dart';
import 'package:mobile/features/wallets/domain/wallet_use_cases.dart';

import '../../core/widgets/widget_test_app.dart';
import '../auth/setup_deps.dart';
import '../goals/goal_stub.dart';
import '../notifications/fake_notification_view_model.dart';
import '../settings/fakes.dart';
import 'budget_fakes.dart';

class _Notifications extends Fake implements NotificationUseCases {
  _Notifications({required this.reminderOn, required this.offline});
  final bool reminderOn;
  final bool offline;

  @override
  Future<Either<AuthFailure, NotificationPreferences>> preferences() async {
    if (offline) return left(const AuthFailure(AuthError.network));
    final base = FakeNotificationViewModel().preferences!;
    return right(
      NotificationPreferences(
        kinds: [
          for (final k in base.kinds)
            NotificationKindToggle(
              kind: k.kind,
              enabled: k.kind == NotificationKind.dailyLog
                  ? reminderOn
                  : k.enabled,
              available: k.available,
              managedLocally: k.managedLocally,
            ),
        ],
        dailyLogTime: base.dailyLogTime,
        quietHoursEnabled: base.quietHoursEnabled,
        quietStart: base.quietStart,
        quietEnd: base.quietEnd,
        version: base.version,
        updatedAt: base.updatedAt,
      ),
    );
  }
}

void main() {
  setUp(registerTestServerConfig);
  setUpAll(loadTestFonts);

  FirstRunNudgesViewModel nudges(
    DefaultSettingsUseCases settings, {
    FakeBudgets? budgets,
    bool reminderOn = false,
    bool offline = false,
  }) => FirstRunNudgesViewModel(
    PendingGoalUseCases(
      settings,
      FakeGoalUseCases(goals: []),
      DefaultWalletUseCases(MemoryWalletRepository(), testServerConfigModel()),
      EmailAuth(),
    ),
    settings,
    budgets ?? FakeBudgets(hasBudget: true),
    testServerConfigModel(),
    _Notifications(reminderOn: reminderOn, offline: offline),
  );

  test('the reminder is offered once, only after a transaction, only for '
      '"Quản lý chi tiêu"', () async {
    final settings = DefaultSettingsUseCases(
      SettingsRepositoryImpl(MemoryPreferences()),
    );
    final model = nudges(settings);
    await model.check(trackGoal: false, hasTransactions: true);
    expect(model.askDailyLog, isFalse);
    await model.check(trackGoal: true, hasTransactions: false);
    expect(model.askDailyLog, isFalse);
    await model.check(trackGoal: true, hasTransactions: true);
    expect(model.askDailyLog, isTrue);
    await model.dailyLogAnswered();
    expect(model.askDailyLog, isFalse);
    await model.check(trackGoal: true, hasTransactions: true);
    expect(model.askDailyLog, isFalse);
  });

  test('after a reinstall the reminder is not offered again when the account '
      'already has it on', () async {
    final settings = DefaultSettingsUseCases(
      SettingsRepositoryImpl(MemoryPreferences()),
    );
    final model = nudges(settings, reminderOn: true);
    await model.check(trackGoal: true, hasTransactions: true);
    expect(model.askDailyLog, isFalse);
    expect(
      (await settings.load()).getOrElse(() => throw 0).dailyLogAsked,
      isTrue,
    );
  });

  test('offline: nothing is asked and nothing is remembered', () async {
    final settings = DefaultSettingsUseCases(
      SettingsRepositoryImpl(MemoryPreferences()),
    );
    final model = nudges(settings, offline: true);
    await model.check(trackGoal: true, hasTransactions: true);
    expect(model.askDailyLog, isFalse);
    expect(
      (await settings.load()).getOrElse(() => throw 0).dailyLogAsked,
      isFalse,
    );
    final later = nudges(settings);
    await later.check(trackGoal: true, hasTransactions: true);
    expect(later.askDailyLog, isTrue);
  });

  test('the budget is offered once when there is none, before the reminder, '
      'from the declared income midpoint', () async {
    final settings = DefaultSettingsUseCases(
      SettingsRepositoryImpl(MemoryPreferences()),
    );
    final budgets = FakeBudgets();
    final model = nudges(settings, budgets: budgets);
    await model.check(
      trackGoal: true,
      hasTransactions: true,
      incomeMidpointMinor: BigInt.from(15000000),
    );
    expect(model.askBudget, isTrue);
    expect(model.askDailyLog, isFalse);
    // 15M minus the 20% savings share.
    expect(model.budgetSuggestion, BigInt.from(12000000));
    expect(await model.setBudget(BigInt.from(11000000)), isTrue);
    expect(budgets.puts.single.limitMinor, BigInt.from(11000000));
    await model.budgetAnswered();
    expect(model.askBudget, isFalse);
    await model.check(trackGoal: true, hasTransactions: true);
    expect(model.askBudget, isFalse);
    expect(model.askDailyLog, isTrue);
  });

  test('no income: the budget sheet starts empty; an existing budget is '
      'never asked about', () async {
    final settings = DefaultSettingsUseCases(
      SettingsRepositoryImpl(MemoryPreferences()),
    );
    final model = nudges(settings, budgets: FakeBudgets());
    await model.check(trackGoal: false, hasTransactions: false);
    expect(model.askBudget, isTrue);
    expect(model.budgetSuggestion, isNull);
    final other = nudges(
      DefaultSettingsUseCases(SettingsRepositoryImpl(MemoryPreferences())),
      budgets: FakeBudgets(hasBudget: true),
    );
    await other.check(trackGoal: false, hasTransactions: false);
    expect(other.askBudget, isFalse);
  });

  Future<FakeNotificationViewModel> open(
    WidgetTester t, {
    bool dark = false,
  }) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final notifications = FakeNotificationViewModel();
    await t.pumpWidget(
      testApp(
        Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => showDailyLogAskSheet(context, notifications),
              child: const Text('open'),
            ),
          ),
        ),
        dark: dark,
      ),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    return notifications;
  }

  testWidgets('"Bật" saves 21:00 and turns the daily log on', (t) async {
    final notifications = await open(t);
    expect(find.text('Nhắc ghi chi mỗi tối'), findsOneWidget);
    expect(find.text('21:00'), findsOneWidget);
    await t.tap(find.text('Bật'));
    await t.pumpAndSettle();
    expect(notifications.savedDailyLogTimes, ['21:00']);
    final daily = notifications.preferences!.kinds.firstWhere(
      (k) => k.kind == NotificationKind.dailyLog,
    );
    expect(daily.enabled, isTrue);
    expect(find.text('Nhắc ghi chi mỗi tối'), findsNothing);
  });

  for (final dark in [false, true]) {
    testWidgets(
      'sheet golden ${dark ? 'dark' : 'light'}',
      skip: !Platform.isMacOS,
      (t) async {
        await open(t, dark: dark);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/daily_log_ask${dark ? '_dark' : ''}.png'),
        );
      },
    );
  }

  Future<FakeBudgets> openBudget(
    WidgetTester t, {
    bool dark = false,
    BigInt? midpoint,
  }) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final budgets = FakeBudgets();
    final settings = DefaultSettingsUseCases(
      SettingsRepositoryImpl(MemoryPreferences()),
    );
    final model = nudges(settings, budgets: budgets);
    await t.runAsync(
      () => model.check(
        trackGoal: false,
        hasTransactions: false,
        incomeMidpointMinor: midpoint,
      ),
    );
    await t.pumpWidget(
      testApp(
        Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => showBudgetAskSheet(
                context,
                model,
                currency: 'VND',
                today: DateTime(2026, 11, 19),
              ),
              child: const Text('open'),
            ),
          ),
        ),
        dark: dark,
      ),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    return budgets;
  }

  testWidgets('budget sheet: suggested from income, "Đặt ngân sách" saves it', (
    t,
  ) async {
    final budgets = await openBudget(t, midpoint: BigInt.from(15000000));
    expect(find.text('Đặt ngân sách tháng 11'), findsOneWidget);
    expect(find.text('12.000.000'), findsOneWidget);
    expect(find.text('Gợi ý theo thu nhập bạn chọn.'), findsOneWidget);
    await t.tap(find.text('Đặt ngân sách'));
    await t.pumpAndSettle();
    expect(budgets.puts.single.limitMinor, BigInt.from(12000000));
    expect(find.text('Đặt ngân sách tháng 11'), findsNothing);
  });

  testWidgets('budget sheet without income starts empty and cannot save', (
    t,
  ) async {
    await openBudget(t);
    expect(find.text('Gợi ý theo thu nhập bạn chọn.'), findsNothing);
    await t.tap(find.text('Đặt ngân sách'));
    await t.pump();
    expect(find.text('Đặt ngân sách tháng 11'), findsOneWidget);
  });

  for (final dark in [false, true]) {
    testWidgets(
      'budget sheet golden ${dark ? 'dark' : 'light'}',
      skip: !Platform.isMacOS,
      (t) async {
        await openBudget(t, dark: dark, midpoint: BigInt.from(15000000));
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/budget_ask${dark ? '_dark' : ''}.png'),
        );
      },
    );
  }
}
