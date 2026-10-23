import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/sync/domain/sync_item.dart';
import 'package:mobile/features/sync/presentation/pages/sync_compare_page.dart';
import 'package:mobile/features/sync/presentation/viewmodels/sync_view_model.dart';
import 'package:mobile/features/sync/presentation/widgets/sync_duplicate_host.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';
import 'package:mobile/features/transactions/domain/transaction_use_cases.dart';
import 'package:mobile/features/transactions/presentation/viewmodels/transaction_view_model.dart';

import '../transactions/c1_stub.dart';
import 'sync_fakes.dart';

class _ReadOnlyCases implements TransactionUseCases {
  _ReadOnlyCases(this.rows);
  final Map<String, TransactionBundle> rows;
  @override
  Future<Either<AuthFailure, TransactionBundle>> read(String id) async =>
      rows[id] == null
      ? left(const AuthFailure(AuthError.unavailable))
      : right(rows[id]!);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FixedSync model;
  late StubTransactionViewModel tx;

  SyncQueueItem conflict() =>
      syncItem(
        'c',
        action: SyncAction.update,
        serverId: 'srv-1',
        merchant: 'Phở Thìn',
        amount: -65000,
      ).copyWith(
        status: SyncItemStatus.conflict,
        reason: SyncReason.changedElsewhere,
        server: SyncServerCopy(
          id: 'srv-1',
          version: 4,
          occurredOn: '2026-10-22',
          amountMinor: '-60000',
          currencyCode: 'VND',
          categoryId: 'food',
          merchant: 'Phở Thìn',
          updatedAt: DateTime(2026, 10, 22, 12, 50),
        ),
      );

  setUp(() async {
    await getIt.reset();
    tx = StubTransactionViewModel();
    model = FixedSync([conflict()]);
    getIt
      ..registerSingleton<SyncViewModel>(model)
      ..registerSingleton<TransactionViewModel>(tx);
  });

  tearDown(() => getIt.reset());

  Widget app(Widget home, {String locale = 'vi'}) {
    final router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(path: '/start', builder: (_, _) => home),
        GoRoute(
          path: '/sync',
          builder: (_, _) => const Scaffold(body: Text('sync-list')),
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

  Future<void> show(WidgetTester t, Widget w) async {
    t.view.physicalSize = const Size(390, 1000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(w);
    await t.pumpAndSettle();
  }

  group('Chọn bản giữ lại', () {
    testWidgets('shows both versions, the saved one chosen, differences kept', (
      t,
    ) async {
      await show(t, app(const SyncComparePage(opId: 'c')));
      expect(find.text('Chọn bản giữ lại'), findsOneWidget);
      expect(find.text('Bản trên máy này'), findsOneWidget);
      expect(find.text('Bản đã lưu'), findsOneWidget);
      expect(find.text('−65.000'), findsOneWidget);
      expect(find.text('−60.000'), findsOneWidget);
      expect(find.text('Giữ bản đã lưu'), findsOneWidget);
      expect(find.textContaining('Sửa ở máy khác lúc'), findsOneWidget);
    });

    testWidgets('keeping the saved one drops the local change', (t) async {
      await show(t, app(const SyncComparePage(opId: 'c')));
      await t.tap(find.text('Giữ bản đã lưu'));
      await t.pumpAndSettle();
      expect(model.items, isEmpty);
      expect(model.kept, isEmpty);
      expect(find.text('sync-list'), findsOneWidget);
    });

    testWidgets(
      'choosing this device\'s version changes the button and sends it',
      (t) async {
        await show(t, app(const SyncComparePage(opId: 'c')));
        await t.tap(find.text('Bản trên máy này'));
        await t.pump();
        expect(find.text('Giữ bản trên máy này'), findsOneWidget);
        await t.tap(find.text('Giữ bản trên máy này'));
        await t.pumpAndSettle();
        expect(model.kept, ['c']);
        expect(find.text('sync-list'), findsOneWidget);
      },
    );

    testWidgets('a deleted-here conflict says so on this device\'s side', (
      t,
    ) async {
      model.items = [
        conflict().copyWith(action: SyncAction.delete, legs: const []),
      ];
      await show(t, app(const SyncComparePage(opId: 'c')));
      expect(find.text('Đã xoá'), findsWidgets);
    });

    testWidgets('without a server copy there is nothing to compare', (t) async {
      model.items = [conflict().copyWith(server: null)];
      await show(t, app(const SyncComparePage(opId: 'c')));
      expect(find.text('sync-list'), findsOneWidget);
    });

    testWidgets('fits a small screen at large text', (t) async {
      t.view.physicalSize = const Size(320, 700);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      for (final locale in ['vi', 'en']) {
        await t.pumpWidget(
          app(const SyncComparePage(opId: 'c'), locale: locale),
        );
        await t.pumpAndSettle();
        expect(t.takeException(), isNull, reason: locale);
      }
    });
  });

  group('Có thể bạn đã ghi rồi', () {
    late List<TransactionBundle> rows;
    setUp(() {
      rows = tx.rows.take(2).toList();
      getIt.registerSingleton<TransactionUseCases>(
        _ReadOnlyCases({rows[0].id: rows[0], rows[1].id: rows[1]}),
      );
      model.duplicate = SyncDuplicate(
        newId: rows[0].id,
        existingId: rows[1].id,
      );
    });

    Widget host() =>
        app(const SyncDuplicateHost(child: Scaffold(body: Text('tab-root'))));

    testWidgets('asks at a tab root and "Giữ cả hai" changes nothing', (
      t,
    ) async {
      await show(t, host());
      expect(find.text('Có thể bạn đã ghi rồi'), findsOneWidget);
      expect(find.text('VỪA GHI'), findsOneWidget);
      expect(find.text('ĐÃ CÓ'), findsOneWidget);
      await t.tap(find.text('Giữ cả hai'));
      await t.pumpAndSettle();
      expect(tx.removed, isEmpty);
      expect(model.duplicate, isNull);
    });

    testWidgets('"Xoá bản vừa ghi" deletes the new one and offers Hoàn tác', (
      t,
    ) async {
      await show(t, host());
      await t.tap(find.text('Xoá bản vừa ghi'));
      await t.pumpAndSettle();
      expect(tx.removed.single.id, rows[0].id);
      expect(find.text('Hoàn tác'), findsOneWidget);
      await t.tap(find.text('Hoàn tác'));
      expect(tx.undone.single.id, rows[0].id);
    });

    testWidgets('a copy that cannot be read drops the question quietly', (
      t,
    ) async {
      await getIt.unregister<TransactionUseCases>();
      getIt.registerSingleton<TransactionUseCases>(_ReadOnlyCases({}));
      await show(t, host());
      expect(find.text('Có thể bạn đã ghi rồi'), findsNothing);
      expect(model.duplicate, isNull);
    });
  });
}
