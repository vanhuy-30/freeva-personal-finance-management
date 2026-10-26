import 'package:flutter/material.dart';
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
import 'f2_stub.dart';

DefaultAuthViewModel _auth() =>
    DefaultAuthViewModel(
        DefaultAuthUseCases(
          AuthRepositoryImpl(FakeApi(), MemoryVault(), FakeBiometrics()),
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
      'asks for the three largest of the slice in its currency and period',
      () async {
        final model = CategoryReportViewModel(repository, auth, f2Args());
        await model.load();
        final query = repository.queries.single;
        expect(query.pageSize, 3);
        expect(query.type, TransactionType.expense);
        expect(query.sort, TransactionSort.amountDesc);
        expect(query.currency, 'VND');
        expect(query.categoryIds, ['coffee', 'out']);
        expect((query.from, query.to), ('2026-10-01', '2026-10-31'));
        expect(model.count, 42);
        expect(model.largest, hasLength(3));
        model.dispose();
      },
    );

    test(
      'a failure keeps the screen usable; an expired session signs out',
      () async {
        repository.failure = const AuthFailure(AuthError.network);
        final model = CategoryReportViewModel(repository, auth, f2Args());
        await model.load();
        expect(model.failure?.code, AuthError.network);
        expect(model.largest, isEmpty);
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
      repository = FakeTransactionRepository();
      transactions = StubTransactionViewModel();
      auth = _auth();
      getIt.registerSingleton<AuthViewModel>(auth);
      await registerF2(repository, transactions);
    });
    tearDown(() async {
      auth.dispose();
      await getIt.reset();
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
      expect(find.text('Giao dịch lớn nhất'), findsOneWidget);
      expect(find.text('Co.opmart'), findsOneWidget);
      expect(find.text('Xem cả 42'), findsOneWidget);
    });

    testWidgets('"Xem cả N" opens the list filtered to this slice and period', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(f2Args()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xem cả 42'));
      await tester.pumpAndSettle();
      expect(find.text('DANH SÁCH'), findsOneWidget);
      final filter = transactions.filter;
      expect(filter.type, TransactionType.expense);
      expect(filter.categoryIds, {'coffee', 'out'});
      expect(filter.custom?.from, '2026-10-01');
      expect(filter.custom?.to, '2026-10-31');
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
        expect(find.text('Giao dịch lớn nhất'), findsNothing);
        expect(repository.queries, isEmpty);
      },
    );

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
