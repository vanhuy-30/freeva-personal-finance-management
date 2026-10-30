import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';
import 'package:mobile/features/transactions/domain/transaction_use_cases.dart';
import 'package:mobile/features/transactions/presentation/viewmodels/transaction_composer.dart';
import 'package:mobile/features/wallets/data/wallet_repository_impl.dart';
import 'package:mobile/features/wallets/domain/credit_card_status.dart';
import 'package:mobile/features/wallets/domain/wallet_flow.dart';
import 'package:mobile/features/wallets/domain/wallet_totals.dart';
import 'package:mobile/features/wallets/presentation/pages/wallet_detail_page.dart';
import 'package:mobile/features/wallets/presentation/viewmodels/wallet_detail_view_model.dart';

import '../home/fixtures.dart' show b, wallet;
import '../transactions/c1_stub.dart';
import 'd1_stub.dart';
import 'wallet_test.dart' show WalletTransport;
import 'package:mobile/features/fx_rates/domain/fx_rate_use_cases.dart';
import '../fx_rates/fakes.dart';
import 'package:mobile/core/money/display_converted.dart';

/// Records list queries and answers with one summary row.
class _Cases implements TransactionUseCases {
  final queries = <TransactionQuery>[];
  TransactionSummary summary = TransactionSummary.empty;
  bool fail = false;

  @override
  Future<Either<AuthFailure, TransactionListPage>> list(
    TransactionQuery query,
  ) async {
    queries.add(query);
    if (fail) return left(const AuthFailure(AuthError.network));
    return right(
      TransactionListPage(legs: const [], page: 1, total: 0, summary: summary),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('credit card', () {
    final today = DateTime(2026, 10, 21);
    test('available never goes below zero; days to the next due date', () {
      final card = CreditCardStatus.of(creditCard(), today);
      expect(card.used, b(11450000));
      expect(card.available, b(8550000));
      expect(card.daysUntilDue(today), 4);
      expect(card.dueWithin(today, 7), isTrue);
      final over = CreditCardStatus.of(creditCard(balance: -25000000), today);
      expect(over.available, BigInt.zero);
      expect(over.level, CreditLevel.critical);
      expect(
        CreditCardStatus.of(creditCard(limit: null), today).available,
        isNull,
      );
      final late = CreditCardStatus.of(creditCard(), DateTime(2026, 10, 26));
      expect(late.nextDue, DateTime(2026, 11, 25));
      expect(late.daysUntilDue(DateTime(2026, 10, 26)), 30);
      expect(late.dueWithin(DateTime(2026, 10, 26), 7), isFalse);
    });
    test('a positive card balance is no debt', () {
      final card = CreditCardStatus.of(creditCard(balance: 5000), today);
      expect(card.used, BigInt.zero);
      expect(card.ratio, 0);
    });
  });

  test('totals per currency put the profile currency first', () {
    final totals = walletTotals([
      wallet('a', 'A', balance: 100),
      wallet('u', 'U', currency: 'USD', balance: 250),
      creditCard(balance: -40),
    ], 'VND');
    expect(totals.map((t) => (t.currency, t.minor, t.count)), [
      ('VND', b(60), 2),
      ('USD', b(250), 1),
    ]);
    expect(
      walletTotals([wallet('u', 'U', currency: 'USD')], 'VND').first.currency,
      'USD',
    );
    expect(walletTotals(const [], 'VND').single.count, 0);
  });

  test('money in and out count transfers', () {
    final flow = WalletFlow.fromTotals([
      TransactionTotal(
        currency: 'VND',
        income: b(18500000),
        expense: b(-712000),
        transferIn: b(100000),
        transferOut: b(-500000),
      ),
    ]);
    expect(flow.moneyIn, b(18600000));
    expect(flow.moneyOut, b(1212000));
  });

  test('repository saves the order in one PUT and parses the reply', () async {
    final api = WalletTransport();
    final repo = WalletRepositoryImpl(api);
    final wallets = (await repo.load()).getOrElse(() => throw StateError(''));
    final saved = await repo.reorder([wallets[1], wallets[0], wallets[2]]);
    expect(saved.getOrElse(() => const []).map((w) => w.id), ['b', 'a', 'c']);
    expect(api.calls.last.method, 'PUT');
    expect(api.calls.last.path, 'financial-accounts/order');
  });

  group('detail view model', () {
    test('loads the balance in the profile currency, and tolerates failure', () async {
      final rates = MemoryFxRates()
        ..wallet['usd'] = DisplayConverted(
          currency: 'VND',
          minor: BigInt.from(308500),
          rate: '25000.00000000',
          quotedAt: DateTime.utc(2026, 10, 30, 2),
        );
      final converted = DefaultWalletDetailViewModel(
        _Cases(),
        StubTransactionViewModel(),
        FxRateUseCases(rates),
        walletId: 'usd',
      );
      addTearDown(converted.dispose);
      expect(converted.converted, isNull);
      await converted.reload();
      expect(converted.converted!.minor, BigInt.from(308500));
      expect(converted.converted!.rate, '25000.00000000');

      final other = DefaultWalletDetailViewModel(
        _Cases(),
        StubTransactionViewModel(),
        FxRateUseCases(rates..failure = const AuthFailure(AuthError.network)),
        walletId: 'usd',
      );
      addTearDown(other.dispose);
      await other.reload();
      expect(other.converted, isNull);
    });

    test('month flow asks this month for this wallet only', () async {
      final cases = _Cases()
        ..summary = TransactionSummary(
          count: 2,
          totals: [
            TransactionTotal(
              currency: 'VND',
              income: b(1000),
              expense: b(-300),
              transferOut: b(-200),
            ),
          ],
        );
      final detail = DefaultWalletDetailViewModel(
        cases,
        StubTransactionViewModel(),
        FxRateUseCases(MemoryFxRates()),
        walletId: 'vcb',
      );
      addTearDown(detail.dispose);
      await detail.reload();
      expect(detail.flow!.moneyIn, b(1000));
      expect(detail.flow!.moneyOut, b(500));
      final month = cases.queries.firstWhere((q) => q.pageSize == 1);
      expect(month.accountIds, ['vcb']);
      expect(month.from, '2026-10-01');
      final history = cases.queries.firstWhere((q) => q.pageSize != 1);
      expect(history.accountIds, ['vcb']);
      expect(history.from, isNull);
    });
    test('a failed flow shows as failed, not zero', () async {
      final cases = _Cases()..fail = true;
      final detail = DefaultWalletDetailViewModel(
        cases,
        StubTransactionViewModel(),
        FxRateUseCases(MemoryFxRates()),
        walletId: 'vcb',
      );
      addTearDown(detail.dispose);
      await detail.reload();
      expect(detail.flow, isNull);
      expect(detail.flowFailed, isTrue);
    });
  });

  group('record from a wallet', () {
    StubTransactionViewModel model() =>
        StubTransactionViewModel()
          ..wallets = canvasWallets().where((w) => !w.archived).toList();
    test('"Ghi từ ví này" keeps the wallet as source', () {
      final c = TransactionComposer(model(), fromAccountId: 'momo');
      expect(c.accountId, 'momo');
    });
    test('"Trả thẻ" is a transfer into the card from another wallet', () {
      final c = TransactionComposer(
        model(),
        initialType: TransactionType.transfer,
        toAccountId: 'card',
      );
      expect(c.transfer, isTrue);
      expect(c.counterAccountId, 'card');
      expect(c.accountId, isNot('card'));
    });
    test('unknown ids fall back to the defaults', () {
      final c = TransactionComposer(model(), fromAccountId: 'gone');
      expect(c.accountId, 'vcb');
    });
  });

  group('detail page', () {
    tearDown(() => getIt.reset());
    Future<List<String>> open(WidgetTester tester, String id) async {
      final pushed = <String>[];
      await d1App(const SizedBox());
      final router = GoRouter(
        initialLocation: '/wallets/$id',
        routes: [
          GoRoute(
            path: '/wallets/:id',
            builder: (_, state) =>
                WalletDetailPage(walletId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/record',
            builder: (_, state) {
              pushed.add(state.uri.toString());
              return const Text('record');
            },
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.light,
          locale: const Locale('vi'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          routerConfig: router,
        ),
      );
      await tester.pump();
      return pushed;
    }

    testWidgets('card shows due chip and "Trả thẻ" opens a transfer into it', (
      tester,
    ) async {
      final pushed = await open(tester, 'card');
      expect(find.text('còn 4 ngày'), findsOneWidget);
      expect(find.text('Ngày 20 hằng tháng'), findsOneWidget);
      await tester.tap(find.text('Trả thẻ'));
      await tester.pumpAndSettle();
      expect(pushed, ['/record?type=transfer&to=card']);
    });

    testWidgets('wallet actions record from it or transfer from it', (
      tester,
    ) async {
      final pushed = await open(tester, 'vcb');
      expect(find.text('Ngân hàng · VND'), findsOneWidget);
      await tester.tap(find.text('Chuyển ví'));
      await tester.pumpAndSettle();
      expect(pushed, ['/record?type=transfer&from=vcb']);
    });

    testWidgets('a wallet that is gone says so', (tester) async {
      await open(tester, 'nope');
      expect(find.text('Không tìm thấy ví này'), findsOneWidget);
    });
  });
}
