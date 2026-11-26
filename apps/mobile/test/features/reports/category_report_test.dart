import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../support/server_config_fixture.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/reports/domain/category_detail.dart';
import 'package:mobile/features/reports/domain/report.dart';
import 'package:mobile/features/reports/domain/report_breakdown.dart';
import 'package:mobile/features/reports/presentation/pages/report_category_page.dart';
import 'package:mobile/features/reports/presentation/viewmodels/category_report_view_model.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';

import '../auth/fakes.dart';
import '../transactions/c1_stub.dart' show StubTransactionViewModel;
import 'f1_stub.dart';
import '../transactions/c1_stub.dart' show tx;
import 'f2_stub.dart';

DefaultAuthViewModel _auth() =>
    DefaultAuthViewModel(
        DefaultAuthUseCases(
          AuthRepositoryImpl(
            FakeApi(),
            MemoryVault(),
            FakeBiometrics(),
            testServerConfigModel(),
          ),
          testServerConfigModel(),
        ),
      )
      ..stage = AuthStage.unlocked
      ..hasPin = true
      ..ready = true;

void main() {
  group('categoryDetail', () {
    test('splits a parent into children and "(chung)", against its total', () {
      final detail = categoryDetail(f2Args());
      expect(detail.total, BigInt.from(3541600));
      expect(detail.percent, 38);
      expect([for (final b in detail.bars) b.name], ['Ăn ngoài', 'Cà phê']);
      expect(detail.bars.any((b) => b.general), isFalse);
    });

    test(
      'marks the parent\'s own spending as general only beside children',
      () {
        CashflowCategoryRow row(
          String id,
          String name,
          int spend, {
          String? parent,
          String? parentName,
        }) => CashflowCategoryRow(
          categoryId: id,
          parentId: parent,
          currency: 'VND',
          incomeMinor: BigInt.zero,
          expenseMinor: BigInt.from(-spend),
          name: name,
          parentName: parentName,
        );
        CategoryDetailArgs args(List<CashflowCategoryRow> rows) {
          final report = CashflowReport(
            period: october().period,
            totals: const [],
            byCategory: rows,
            byAccount: const [],
          );
          return CategoryDetailArgs(
            report: report,
            currency: 'VND',
            digits: 0,
            kind: BreakdownKind.expense,
            slice: reportBreakdown(
              report,
              'VND',
              BreakdownKind.expense,
              top: 3,
            ).slices.first,
          );
        }

        final mixed = categoryDetail(
          args([
            row('food', 'Ăn uống', 1231600),
            row(
              'market',
              'Đi chợ',
              1820000,
              parent: 'food',
              parentName: 'Ăn uống',
            ),
          ]),
        );
        expect(
          [for (final b in mixed.bars) (b.name, b.general)],
          [('Đi chợ', false), ('Ăn uống', true)],
        );
        final alone = categoryDetail(args([row('food', 'Ăn uống', 500)]));
        expect(alone.bars.single.general, isFalse);
        expect(alone.percent, 100);
      },
    );

    test('"Khác" lists each folded category once', () {
      final detail = categoryDetail(f2Args(index: 3));
      expect(detail.bars, hasLength(6));
      expect(detail.total, BigInt.from(1864000));
      expect(detail.percent, 20);
    });

    test(
      'filter ids cover every leaf; uncategorised income cannot be filtered',
      () {
        expect(f2Args().categoryIds, ['coffee', 'out']);
        final report = CashflowReport(
          period: october().period,
          totals: const [],
          byCategory: [
            CashflowCategoryRow(
              categoryId: null,
              parentId: null,
              currency: 'VND',
              incomeMinor: BigInt.from(5),
              expenseMinor: BigInt.zero,
            ),
          ],
          byAccount: const [],
        );
        final slices = reportBreakdown(
          report,
          'VND',
          BreakdownKind.income,
          top: 3,
        ).slices;
        final args = CategoryDetailArgs(
          report: report,
          currency: 'VND',
          digits: 0,
          kind: BreakdownKind.income,
          slice: slices.single,
        );
        expect(args.categoryIds, isNull);
      },
    );
  });

  group('CategoryReportViewModel', () {
    late FakeTransactionRepository repository;
    late DefaultAuthViewModel auth;

    setUp(() {
      repository = FakeTransactionRepository();
      auth = _auth();
    });
    tearDown(() => auth.dispose());

    test(
      'asks for ten of the slice, newest first, in its currency and period',
      () async {
        final model = CategoryReportViewModel(repository, auth, f2Args());
        await model.load();
        final query = repository.queries.single;
        expect(query.page, 1);
        expect(query.pageSize, 10);
        expect(query.type, TransactionType.expense);
        expect(query.sort, TransactionSort.date);
        expect(query.currency, 'VND');
        expect(query.categoryIds, ['coffee', 'out']);
        expect((query.from, query.to), ('2026-10-01', '2026-10-31'));
        expect(model.count, 42);
        expect(model.items, hasLength(3));
        model.dispose();
      },
    );

    test(
      '"Xem thêm" appends the next page until every row is loaded',
      () async {
        repository
          ..total = 25
          ..legsFor = (query) => [
            for (var i = 0; i < 10 && (query.page - 1) * 10 + i < 25; i++)
              tx(
                'p${query.page}-$i',
                account: 'cash',
                amount: -1000,
                day: '2026-10-10',
                category: 'food',
              ),
          ];
        final model = CategoryReportViewModel(repository, auth, f2Args());
        await model.load();
        expect(model.items, hasLength(10));
        expect(model.hasMore, isTrue);
        await model.loadMore();
        expect(repository.queries.last.page, 2);
        expect(model.items, hasLength(20));
        await model.loadMore();
        expect(model.items, hasLength(25));
        expect(model.hasMore, isFalse);
        final calls = repository.queries.length;
        await model.loadMore();
        expect(repository.queries, hasLength(calls));
        model.dispose();
      },
    );

    test('changing the order starts again from the first page', () async {
      repository.total = 25;
      final model = CategoryReportViewModel(repository, auth, f2Args());
      await model.load();
      await model.setSort(TransactionSort.amountAsc);
      final query = repository.queries.last;
      expect(query.page, 1);
      expect(query.sort, TransactionSort.amountAsc);
      expect(model.sort, TransactionSort.amountAsc);
      final calls = repository.queries.length;
      await model.setSort(TransactionSort.amountAsc);
      expect(repository.queries, hasLength(calls));
      model.dispose();
    });

    test(
      'a failure keeps the screen usable; an expired session signs out',
      () async {
        repository.failure = const AuthFailure(AuthError.network);
        final model = CategoryReportViewModel(repository, auth, f2Args());
        await model.load();
        expect(model.failure?.code, AuthError.network);
        expect(model.items, isEmpty);
        repository.failure = const AuthFailure(AuthError.expired);
        await model.load();
        expect(auth.stage, AuthStage.signedOut);
        model.dispose();
      },
    );
  });

  group('ReportCategoryPage', () {
    late FakeTransactionRepository repository;
    late StubTransactionViewModel transactions;
    late DefaultAuthViewModel auth;

    setUp(() async {
      await getIt.reset();
      registerTestServerConfig();
      repository = FakeTransactionRepository();
      transactions = StubTransactionViewModel();
      auth = _auth();
      getIt.registerSingleton<AuthViewModel>(auth);
      await registerF2(repository, transactions);
    });
    tearDown(() async {
      auth.dispose();
      await getIt.reset();
      registerTestServerConfig();
    });

    Widget app(CategoryDetailArgs args, {double scale = 1}) =>
        MaterialApp.router(
          theme: AppTheme.light,
          locale: const Locale('vi'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: scale,
            maxScaleFactor: scale,
            child: child!,
          ),
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, __) => ReportCategoryPage(args: args),
              ),
              GoRoute(
                path: '/reports/category',
                builder: (_, state) => ReportCategoryPage(
                  args: state.extra! as CategoryDetailArgs,
                ),
              ),
              GoRoute(
                path: '/transactions',
                builder: (_, __) => const Text('DANH SÁCH'),
              ),
            ],
          ),
        );

    testWidgets('shows total, share, bars and the largest transactions', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(f2Args()));
      await tester.pumpAndSettle();
      expect(find.text('Ăn uống'), findsOneWidget);
      expect(find.text('Tháng 10, 2026'), findsOneWidget);
      expect(find.textContaining('3.541.600'), findsOneWidget);
      expect(find.text('38% tổng chi · 42 giao dịch'), findsOneWidget);
      expect(find.text('Ăn ngoài'), findsOneWidget);
      expect(find.text('Giao dịch'), findsOneWidget);
      expect(find.text('Co.opmart'), findsOneWidget);
      expect(find.text('Xem thêm'), findsOneWidget);
      expect(find.text('Xem cả 42'), findsNothing);
    });

    testWidgets('sorts by date or amount and loads ten more on "Xem thêm"', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(f2Args()));
      await tester.pumpAndSettle();
      for (final (label, sort) in [
        ('Cũ nhất', TransactionSort.dateAsc),
        ('Lớn nhất', TransactionSort.amountDesc),
        ('Nhỏ nhất', TransactionSort.amountAsc),
        ('Mới nhất', TransactionSort.date),
      ]) {
        await tester.tap(find.byIcon(LucideIcons.arrowUpDown));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(repository.queries.last.sort, sort);
        expect(repository.queries.last.page, 1);
      }
      await tester.ensureVisible(find.text('Xem thêm'));
      await tester.tap(find.text('Xem thêm'));
      await tester.pumpAndSettle();
      expect(repository.queries.last.page, 2);
      expect(repository.queries.last.sort, TransactionSort.date);
    });

    testWidgets(
      'hides the largest block when the API cannot filter the slice',
      (tester) async {
        final report = CashflowReport(
          period: october().period,
          totals: const [],
          byCategory: [
            CashflowCategoryRow(
              categoryId: null,
              parentId: null,
              currency: 'VND',
              incomeMinor: BigInt.from(500000),
              expenseMinor: BigInt.zero,
            ),
          ],
          byAccount: const [],
        );
        final slice = reportBreakdown(
          report,
          'VND',
          BreakdownKind.income,
          top: 3,
        ).slices.single;
        await tester.pumpWidget(
          app(
            CategoryDetailArgs(
              report: report,
              currency: 'VND',
              digits: 0,
              kind: BreakdownKind.income,
              slice: slice,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Khác'), findsOneWidget);
        expect(find.text('Giao dịch'), findsNothing);
        expect(repository.queries, isEmpty);
      },
    );

    testWidgets('a category inside "Khác" opens with its own transactions', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final args = f2Args(index: 3);
      final bar = categoryDetail(args).bars.first;
      expect(bar.memberId, isNotNull);
      await tester.pumpWidget(app(args));
      await tester.pumpAndSettle();
      expect(find.text('Khác'), findsOneWidget);
      final calls = repository.queries.length;
      await tester.tap(find.text(bar.name));
      await tester.pumpAndSettle();
      expect(find.text(bar.name), findsWidgets);
      expect(find.text('Khác'), findsNothing);
      expect(repository.queries.length, greaterThan(calls));
      expect(repository.queries.last.categoryIds, isNotEmpty);
    });

    testWidgets('fits 320 pt at 1.3× and 2× text', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final scale in [1.3, 2.0]) {
        await tester.pumpWidget(app(f2Args(), scale: scale));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(ListView), const Offset(0, -900));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  });
}
