import 'dart:io';

import '../../support/server_config_fixture.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/notifications/domain/notification_models.dart';
import 'package:mobile/features/onboarding/domain/pending_goal_use_cases.dart';
import 'package:mobile/features/onboarding/presentation/viewmodels/first_run_nudges_view_model.dart';
import 'package:mobile/features/onboarding/presentation/widgets/daily_log_ask_sheet.dart';
import 'package:mobile/features/settings/data/settings_repository_impl.dart';
import 'package:mobile/features/settings/domain/settings_use_cases.dart';
import 'package:mobile/features/wallets/domain/wallet_use_cases.dart';

import '../../core/widgets/widget_test_app.dart';
import '../auth/setup_deps.dart';
import '../goals/goal_stub.dart';
import '../notifications/fake_notification_view_model.dart';
import '../settings/fakes.dart';

void main() {
  setUp(registerTestServerConfig);
  setUpAll(loadTestFonts);

  FirstRunNudgesViewModel nudges(DefaultSettingsUseCases settings) =>
      FirstRunNudgesViewModel(
        PendingGoalUseCases(
          settings,
          FakeGoalUseCases(goals: []),
          DefaultWalletUseCases(
            MemoryWalletRepository(),
            testServerConfigModel(),
          ),
          EmailAuth(),
        ),
        settings,
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

  testWidgets('"Bật nhắc" saves 21:00 and turns the daily log on', (t) async {
    final notifications = await open(t);
    expect(find.text('Nhắc ghi chi mỗi tối?'), findsOneWidget);
    expect(find.text('21:00'), findsOneWidget);
    await t.tap(find.text('Bật nhắc'));
    await t.pumpAndSettle();
    expect(notifications.savedDailyLogTimes, ['21:00']);
    final daily = notifications.preferences!.kinds.firstWhere(
      (k) => k.kind == NotificationKind.dailyLog,
    );
    expect(daily.enabled, isTrue);
    expect(find.text('Nhắc ghi chi mỗi tối?'), findsNothing);
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
}
