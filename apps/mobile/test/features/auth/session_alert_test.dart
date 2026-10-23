import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/analytics/analytics_event.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/domain/session_alert_notifier.dart';
import 'package:mobile/features/auth/domain/session_notice.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/auth/presentation/widgets/session_alert_banner.dart';
import 'package:mobile/features/settings/data/settings_repository_impl.dart';
import 'package:mobile/features/settings/domain/app_preferences.dart';
import 'package:mobile/features/settings/domain/settings_use_cases.dart';

import '../settings/fakes.dart';
import 'fakes.dart';

void main() {
  test('an empty record seeds every session without alerting', () {
    final decision = decideSessionNotice(
      seenIds: const [],
      sessions: const [
        (id: 'current', current: true),
        (id: 'other', current: false),
      ],
    );
    expect(decision.alert, isFalse);
    expect(decision.seenIds, ['current', 'other']);
  });

  test('only another unseen session alerts, and the current one does not', () {
    final currentOnly = decideSessionNotice(
      seenIds: const ['older'],
      sessions: const [(id: 'current', current: true)],
    );
    expect(currentOnly.alert, isFalse);
    expect(currentOnly.seenIds, ['current']);
    final other = decideSessionNotice(
      seenIds: const ['current'],
      sessions: const [
        (id: 'current', current: true),
        (id: 'other', current: false),
      ],
    );
    expect(other.alert, isTrue);
  });

  test('a new session alerts once, grants notification permission once, and logout clears memory', () async {
    final api = FakeApi();
    final vault = MemoryVault();
    final alerts = RecordingSessionAlerts();
    final analytics = RecordingAnalytics();
    final settings = DefaultSettingsUseCases(
      SettingsRepositoryImpl(MemoryPreferences()),
    );
    final model = DefaultAuthViewModel(
      DefaultAuthUseCases(AuthRepositoryImpl(api, vault, FakeBiometrics())),
      settings: settings,
      alerts: alerts,
      analytics: analytics,
    );
    addTearDown(model.dispose);
    await model.login('user@example.com', 'password long enough');
    await model.setupPin('123456', '123456', false, 'unlock');
    expect(model.newSessionAlert, isFalse);
    expect(vault.seen, contains('current'));

    api.sessionItems = [
      _session('current', current: true),
      _session('sess-foreign'),
    ];
    model.lock();
    await model.unlockPin('123456');
    expect(model.newSessionAlert, isTrue);

    const title = 'New sign-in';
    const body =
        'Another session signed in. Open Freeva to review it and revoke it if it was not you.';
    await model.deliverSessionNotification(title, body);
    await model.deliverSessionNotification(title, body);
    expect(alerts.requests, 1);
    expect(alerts.shown, [(title: title, body: body)]);
    expect(alerts.shown.single.body.contains('@'), isFalse);
    expect(alerts.shown.single.body.contains('sess-foreign'), isFalse);
    expect(RegExp(r'\d').hasMatch(alerts.shown.single.body), isFalse);
    expect(analytics.events, [AnalyticsEvent.notificationsOptIn]);
    final saved = (await settings.load()).getOrElse(
      () => const AppPreferences(),
    );
    expect(saved.notificationPrompted, isTrue);
    expect(saved.notificationsOptInTracked, isTrue);

    await model.openSessionAlert();
    expect(model.newSessionAlert, isFalse);
    api.sessionItems = [
      _session('current', current: true),
      _session('other'),
      _session('newer'),
    ];
    model.lock();
    await model.unlockPin('123456');
    await model.deliverSessionNotification(title, body);
    expect(alerts.requests, 1);
    expect(analytics.events, hasLength(1));
    expect(alerts.shown, hasLength(2));

    await model.logout();
    expect(vault.seen, isNull);
    expect(model.newSessionAlert, isFalse);
  });

  test('denied permission keeps the banner and does not ask again', () async {
    final api = FakeApi();
    final alerts = RecordingSessionAlerts()
      ..requestResult = NotificationAccess.denied;
    final analytics = RecordingAnalytics();
    final settings = DefaultSettingsUseCases(
      SettingsRepositoryImpl(MemoryPreferences()),
    );
    final model = DefaultAuthViewModel(
      DefaultAuthUseCases(
        AuthRepositoryImpl(api, MemoryVault(), FakeBiometrics()),
      ),
      settings: settings,
      alerts: alerts,
      analytics: analytics,
    );
    addTearDown(model.dispose);
    await model.login('user@example.com', 'password long enough');
    await model.setupPin('123456', '123456', false, 'unlock');
    api.sessionItems = [_session('current', current: true), _session('other')];
    model.lock();
    await model.unlockPin('123456');
    await model.deliverSessionNotification('New sign-in', 'Another session');
    expect(model.newSessionAlert, isTrue);
    expect(alerts.shown, isEmpty);
    expect(alerts.requests, 1);
    expect(analytics.events, isEmpty);
    await model.openSessionAlert();
    api.sessionItems = [
      _session('current', current: true),
      _session('other'),
      _session('newer'),
    ];
    model.lock();
    await model.unlockPin('123456');
    await model.deliverSessionNotification('New sign-in', 'Another session');
    expect(alerts.requests, 1);
    expect(alerts.shown, isEmpty);
  });

  test('disabled alerts remember sessions without a banner', () async {
    final api = FakeApi();
    final vault = MemoryVault();
    final settings = DefaultSettingsUseCases(
      SettingsRepositoryImpl(MemoryPreferences()),
    );
    final model = DefaultAuthViewModel(
      DefaultAuthUseCases(AuthRepositoryImpl(api, vault, FakeBiometrics())),
      settings: settings,
      alerts: RecordingSessionAlerts(),
      analytics: RecordingAnalytics(),
    );
    addTearDown(model.dispose);
    await model.login('user@example.com', 'password long enough');
    await model.setupPin('123456', '123456', false, 'unlock');
    final loaded = (await settings.load()).getOrElse(
      () => const AppPreferences(),
    );
    await settings.save(loaded.copyWith(sessionAlertsEnabled: false));
    api.sessionItems = [_session('current', current: true), _session('other')];
    model.lock();
    await model.unlockPin('123456');
    expect(model.newSessionAlert, isFalse);
    expect(vault.seen, contains('other'));
  });

  testWidgets('banner reviews sessions and hides itself', (tester) async {
    await getIt.reset();
    final model = DefaultAuthViewModel(
      DefaultAuthUseCases(
        AuthRepositoryImpl(FakeApi(), MemoryVault(), FakeBiometrics()),
      ),
    );
    model.newSessionAlert = true;
    getIt.registerSingleton<AuthViewModel>(model);
    addTearDown(() async {
      model.dispose();
      await getIt.reset();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('vi'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: SessionAlertBanner(scrollTarget: GlobalKey()),
      ),
    );
    await tester.pump();
    expect(find.text('Phiên đăng nhập mới'), findsOneWidget);
    expect(find.textContaining('@'), findsNothing);
    expect(find.textContaining('••••'), findsNothing);
    await tester.tap(find.text('Xem các phiên'));
    await tester.pumpAndSettle();
    expect(find.text('Phiên đăng nhập mới'), findsNothing);
  });
}

Map<String, dynamic> _session(String id, {bool current = false}) => {
  'id': id,
  'createdAt': '2026-01-01T00:00:00.000Z',
  'expiresAt': '2026-01-08T00:00:00.000Z',
  'current': current,
};

class RecordingSessionAlerts implements SessionAlertNotifier {
  NotificationAccess accessState = NotificationAccess.denied;
  NotificationAccess requestResult = NotificationAccess.granted;
  int requests = 0;
  final shown = <({String title, String body})>[];

  @override
  Future<NotificationAccess> access() async => accessState;

  @override
  Future<NotificationAccess> requestAccess() async {
    requests++;
    accessState = requestResult;
    return requestResult;
  }

  @override
  Future<void> show({required String title, required String body}) async {
    shown.add((title: title, body: body));
  }
}
