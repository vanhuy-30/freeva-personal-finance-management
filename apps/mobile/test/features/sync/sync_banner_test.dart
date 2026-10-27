import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/sync/domain/sync_item.dart';
import 'package:mobile/features/sync/presentation/viewmodels/sync_view_model.dart';
import 'package:mobile/features/sync/presentation/widgets/sync_status_banner.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';

import 'sync_fakes.dart';

void main() {
  late FixedSync model;

  setUp(() async {
    await getIt.reset();
    model = FixedSync([
      syncItem('a'),
      syncItem('b', status: SyncItemStatus.conflict),
    ]);
    getIt.registerSingleton<SyncViewModel>(model);
  });

  tearDown(() => getIt.reset());

  Widget app({String locale = 'vi'}) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: SyncStatusBanner()),
        ),
        GoRoute(
          path: '/sync',
          builder: (_, _) => const Scaffold(body: Text('sync-screen')),
        ),
      ],
    );
    addTearDown(router.dispose);
    return MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.light,
      locale: Locale(locale),
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
    );
  }

  testWidgets('says what needs a look and what only waits, in both languages', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    expect(find.text('1 thay đổi cần bạn xem'), findsOneWidget);
    expect(find.text('1 thay đổi khác đang chờ gửi'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        '1 thay đổi cần bạn xem · 1 thay đổi khác đang chờ gửi',
      ),
      findsOneWidget,
    );
    await tester.pumpWidget(app(locale: 'en'));
    expect(
      find.bySemanticsLabel('1 changes need you · 1 more waiting to send'),
      findsOneWidget,
    );
  });

  testWidgets('only waiting changes give the neutral line; nothing hides it', (
    tester,
  ) async {
    model.items = [syncItem('a')];
    await tester.pumpWidget(app());
    expect(find.text('1 thay đổi đang chờ gửi'), findsOneWidget);
    model.items = const [];
    model.notifyListeners();
    await tester.pump();
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('tapping opens the sync screen', (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();
    expect(find.text('sync-screen'), findsOneWidget);
  });

  test('a conflict item reads as needing attention', () {
    expect(model.attention.single.status, SyncItemStatus.conflict);
    expect(model.waiting.single.type, TransactionType.expense);
  });
}
