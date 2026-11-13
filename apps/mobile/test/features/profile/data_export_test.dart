import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/profile/domain/export_period.dart';
import 'package:mobile/features/profile/presentation/pages/data_export_page.dart';
import 'package:mobile/features/profile/presentation/viewmodels/data_export_view_model.dart';
import 'package:mobile/features/transactions/domain/transaction_filter.dart';

import 'data_export_stub.dart';

void main() {
  tearDown(() => getIt.reset());

  group('exportRange', () {
    const custom = DateRange('2026-01-05', '2026-02-06');
    test('months follow the fiscal day', () {
      expect(
        exportRange(ExportPeriod.thisMonth, '2026-11-05', 1, null),
        const DateRange('2026-11-01', '2026-11-30'),
      );
      expect(
        exportRange(ExportPeriod.thisMonth, '2026-11-05', 15, null),
        const DateRange('2026-10-15', '2026-11-14'),
      );
    });
    test('3 months is this month and the two before', () {
      expect(
        exportRange(ExportPeriod.last3Months, '2026-11-05', 1, null),
        const DateRange('2026-09-01', '2026-11-30'),
      );
      expect(
        exportRange(ExportPeriod.last3Months, '2026-02-10', 1, null),
        const DateRange('2025-12-01', '2026-02-28'),
      );
    });
    test('year, all time and custom', () {
      expect(
        exportRange(ExportPeriod.thisYear, '2026-11-05', 1, null),
        const DateRange('2026-01-01', '2026-11-05'),
      );
      expect(exportRange(ExportPeriod.allTime, '2026-11-05', 1, null), isNull);
      expect(exportRange(ExportPeriod.custom, '2026-11-05', 1, custom), custom);
      expect(exportRange(ExportPeriod.custom, '2026-11-05', 1, null), isNull);
    });
  });

  group('DataExportViewModel', () {
    late ExportHarness h;
    setUp(() async => h = await ExportHarness.create());
    tearDown(() => h.model.dispose());

    test('load reads wallets and the row count for this month', () async {
      await h.model.load();
      expect(h.model.wallets, hasLength(3));
      expect(h.model.count, 248);
      expect(h.transactions.queries.single.pageSize, 1);
      expect(h.transactions.queries.single.from, isNotNull);
      expect(h.model.canExport, isTrue);
    });

    test('changing period or wallets recounts with the same filter', () async {
      await h.model.load();
      h.model.selectPeriod(ExportPeriod.allTime);
      h.model.selectWallets({'vcb', 'cash'});
      await Future<void>.delayed(Duration.zero);
      final last = h.transactions.queries.last;
      expect(last.from, isNull);
      expect(last.accountIds, ['cash', 'vcb']);
    });

    test('custom without a range cannot export', () async {
      await h.model.load();
      h.model.selectPeriod(ExportPeriod.custom);
      expect(h.model.canExport, isFalse);
      h.model.selectPeriod(
        ExportPeriod.custom,
        custom: const DateRange('2026-01-01', '2026-01-31'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(h.model.canExport, isTrue);
      expect(h.transactions.queries.last.to, '2026-01-31');
    });

    test('empty and too-large results block the CSV', () async {
      h.transactions.total = 0;
      await h.model.load();
      expect(h.model.canExport, isFalse);
      h.transactions.total = 50001;
      h.model.selectPeriod(ExportPeriod.allTime);
      await Future<void>.delayed(Duration.zero);
      expect(h.model.tooMany, isTrue);
      expect(h.model.canExport, isFalse);
      h.model.selectKind(ExportKind.fullCopy);
      expect(h.model.canExport, isTrue);
    });

    test('CSV export shares the bytes with the filter in the URL', () async {
      await h.model.load();
      h.model.selectWallets({'vcb'});
      await Future<void>.delayed(Duration.zero);
      expect(await h.model.export(), isTrue);
      expect(h.api.lastPath, contains('transactions/export.csv?from='));
      expect(h.api.lastPath, contains('accountId=vcb'));
      expect(h.sharer.bytes, [0xEF, 0xBB, 0xBF, 0x61]);
      expect(h.sharer.mime, 'text/csv');
      expect(
        h.sharer.name,
        matches(RegExp(r'^freeva-transactions-\d{8}\.csv$')),
      );
      expect(h.model.failure, isNull);
      expect(h.model.exporting, isFalse);
    });

    test('all time and no wallets sends no query', () async {
      await h.model.load();
      h.model.selectPeriod(ExportPeriod.allTime);
      await Future<void>.delayed(Duration.zero);
      await h.model.export();
      expect(h.api.lastPath, 'transactions/export.csv');
    });

    test('dismissed sheet is not a failure', () async {
      await h.model.load();
      h.sharer.result = false;
      expect(await h.model.export(), isFalse);
      expect(h.model.failure, isNull);
    });

    test('network error shares nothing; expired ends the session', () async {
      await h.model.load();
      h.api.failure = const AuthFailure(AuthError.network);
      expect(await h.model.export(), isFalse);
      expect(h.model.failure?.code, AuthError.network);
      expect(h.sharer.bytes, isNull);
      h.api.failure = const AuthFailure(AuthError.expired);
      await h.model.export();
      expect(h.auth.expired, 1);
    });

    test('share failure surfaces as a failure', () async {
      await h.model.load();
      h.sharer.fail = true;
      expect(await h.model.export(), isFalse);
      expect(h.model.failure?.code, AuthError.storage);
    });

    test('full copy reuses the JSON export', () async {
      await h.model.load();
      h.model.selectKind(ExportKind.fullCopy);
      expect(await h.model.export(), isTrue);
      expect(h.profile.exports, 1);
      expect(h.api.lastPath, isNot(contains('export.csv')));
    });
  });

  group('DataExportPage', () {
    Future<ExportHarness> open(WidgetTester t, {double scale = 1}) async {
      t.view.physicalSize = const Size(390, 900);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final (h, app) = (await t.runAsync(
        () => exportApp(const DataExportPage(), scale: scale),
      ))!;
      await t.pumpWidget(app);
      await t.pump();
      await t.pump();
      return h;
    }

    testWidgets('shows the summary and exports', (t) async {
      final h = await open(t);
      expect(find.text('Bảng giao dịch'), findsOneWidget);
      expect(find.textContaining('248 giao dịch'), findsOneWidget);
      await t.tap(find.text('Xuất file'));
      await t.pump();
      expect(h.sharer.mime, 'text/csv');
    });

    testWidgets('full copy hides the period and wallet fields', (t) async {
      await open(t);
      await t.tap(find.text('Bản sao đầy đủ'));
      await t.pump();
      expect(find.text('3 tháng'), findsNothing);
      expect(find.text('Tất cả ví'), findsNothing);
      expect(find.textContaining('Gồm toàn bộ'), findsOneWidget);
    });

    testWidgets('SEC-P6-002: full copy asks for the password first', (t) async {
      final h = await open(t);
      await t.tap(find.text('Bản sao đầy đủ'));
      await t.pump();
      await t.tap(find.text('Xuất file'));
      await t.pumpAndSettle();
      expect(find.text('Nhập mật khẩu để tiếp tục'), findsOneWidget);
      await t.enterText(find.byType(TextField), 'mk-bi-mat-7');
      await t.tap(find.text('Xong'));
      await t.pumpAndSettle();
      expect(h.profile.exports, 1);
      expect(h.profile.password, 'mk-bi-mat-7');
    });

    testWidgets('SEC-P6-002: cancelling the password exports nothing', (
      t,
    ) async {
      final h = await open(t);
      await t.tap(find.text('Bản sao đầy đủ'));
      await t.pump();
      await t.tap(find.text('Xuất file'));
      await t.pumpAndSettle();
      await t.tap(find.text('Huỷ'));
      await t.pumpAndSettle();
      expect(h.profile.exports, 0);
    });

    testWidgets('chips wrap without overflow at 320 pt and 1.3x', (t) async {
      t.view.physicalSize = const Size(320, 700);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final (_, app) = (await t.runAsync(
        () => exportApp(const DataExportPage(), scale: 1.3),
      ))!;
      await t.pumpWidget(app);
      await t.pump();
      await t.pump();
      expect(t.takeException(), isNull);
    });
  });
}
