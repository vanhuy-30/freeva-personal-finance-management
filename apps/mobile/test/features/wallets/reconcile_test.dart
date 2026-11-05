import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations_vi.dart';
import 'package:mobile/core/widgets/money_display.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';
import 'package:mobile/features/transactions/presentation/widgets/transaction_naming.dart';
import 'package:mobile/core/widgets/freeva_button.dart';
import 'package:mobile/features/auth/data/authorized_api.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/transactions/data/transaction_repository_impl.dart';
import 'package:mobile/features/transactions/domain/transaction_use_cases.dart';
import 'package:mobile/features/wallets/data/wallet_repository_impl.dart';
import 'package:mobile/features/wallets/domain/reconcile_result.dart';
import 'package:mobile/features/wallets/domain/wallet.dart';
import 'package:mobile/features/wallets/domain/wallet_use_cases.dart';
import 'package:mobile/features/wallets/presentation/pages/wallet_detail_page.dart';

import '../../core/widgets/widget_test_app.dart' show loadTestFonts;
import '../home/fixtures.dart' show b, wallet;

import 'package:mobile/features/transactions/presentation/widgets/adjustment_sheet.dart';

import '../transactions/c1_stub.dart' show StubTransactionViewModel, c1App, tx;
import 'd1_stub.dart';

class _Api implements AuthorizedApi {
  final calls =
      <
        ({
          String method,
          String path,
          Map<String, dynamic>? body,
          Map<String, String>? headers,
        })
      >[];
  Map<String, dynamic> answer = {};
  @override
  Future<Either<AuthFailure, Map<String, dynamic>>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    calls.add((method: method, path: path, body: body, headers: headers));
    return right(answer);
  }
}

void main() {
  setUpAll(loadTestFonts);
  tearDown(() => getIt.reset());

  group('repository', () {
    test(
      'posts the real balance with the idempotency key and keeps bigint',
      () async {
        final api = _Api()
          ..answer = {
            'currentBalanceMinor': '9223372036854775000',
            'targetBalanceMinor': '9223372036854775807',
            'deltaMinor': '807',
            'transaction': {'legs': [], 'fx': null},
          };
        final repo = WalletRepositoryImpl(api);
        final w = wallet('vcb', 'Vietcombank');
        final result = (await repo.reconcile(
          w,
          BigInt.parse('9223372036854775807'),
          clientId: 'c1',
        )).getOrElse(() => throw StateError('failed'));
        final call = api.calls.single;
        expect(call.method, 'POST');
        expect(call.path, 'financial-accounts/vcb/reconcile');
        expect(call.body, {
          'clientId': 'c1',
          'actualBalanceMinor': '9223372036854775807',
        });
        expect(call.headers, {'Idempotency-Key': 'c1'});
        expect(result.deltaMinor, BigInt.from(807));
        expect(result.currentMinor, BigInt.parse('9223372036854775000'));
        expect(result.adjusted, isTrue);
      },
    );

    test(
      'dry run sends the flag; no transaction means nothing written',
      () async {
        final api = _Api()
          ..answer = {
            'currentBalanceMinor': '10',
            'targetBalanceMinor': '10',
            'deltaMinor': '0',
            'transaction': null,
          };
        final result = (await WalletRepositoryImpl(api).reconcile(
          wallet('a', 'A'),
          BigInt.from(10),
          clientId: 'c',
          dryRun: true,
        )).getOrElse(() => throw StateError('failed'));
        expect(api.calls.single.body!['dryRun'], isTrue);
        expect(result.adjusted, isFalse);
      },
    );
  });

  group('adjustment rows', () {
    final naming = TransactionNaming(
      SVi(),
      categories: const [],
      wallets: [wallet('vcb', 'Vietcombank')],
    );
    TransactionLabel label(int amount) => naming.label(
      groupTransactionLegs([
        tx(
          'a',
          account: 'vcb',
          amount: amount,
          type: TransactionType.adjustment,
        ),
      ]).single,
    );
    test('read as a balance adjustment, signed by the move', () {
      final up = label(212000);
      expect(up.title, 'Điều chỉnh số dư');
      expect(up.detail, 'Vietcombank');
      expect(up.tone, MoneyTone.income);
      expect(label(-50000).tone, MoneyTone.expense);
      expect(label(-50000).minor, b(50000));
    });
  });

  group('adjustment edit', () {
    final cases = DefaultTransactionUseCases(TransactionRepositoryImpl(_Api()));
    TransactionBundle row({int amount = 212000, int version = 1}) =>
        groupTransactionLegs([
          tx(
            'a',
            account: 'vcb',
            amount: amount,
            type: TransactionType.adjustment,
          ),
        ]).single;
    test('refuses zero and anything that is not an adjustment', () async {
      expect((await cases.adjust(row(), BigInt.zero)).isLeft(), isTrue);
      final expense = groupTransactionLegs([
        tx('e', account: 'vcb', amount: -5, category: 'food'),
      ]).single;
      expect((await cases.adjust(expense, BigInt.one)).isLeft(), isTrue);
    });
    test(
      'patches the amount only, keeping category and merchant empty',
      () async {
        final api = _Api()..answer = {'legs': [], 'fx': null};
        final repo = TransactionRepositoryImpl(api);
        await DefaultTransactionUseCases(repo)
            .adjust(row(), BigInt.from(-1500));
        final call = api.calls.single;
        expect(call.method, 'PATCH');
        expect(call.body!['categoryId'], isNull);
        expect(call.body!['merchant'], isNull);
        expect(call.body!['fx'], isNull);
        expect((call.body!['legs'] as List).single['amountMinor'], '-1500');
      },
    );

    testWidgets('sheet saves the signed amount and stays off when unchanged', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final model = StubTransactionViewModel();
      final bundle = row();
      await tester.pumpWidget(
        await c1App(
          Scaffold(
            body: AdjustmentSheet(model: model, bundle: bundle),
          ),
          model: model,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      final save = find.widgetWithText(FreevaButton, 'Lưu thay đổi');
      expect(find.text('212.000'), findsOneWidget);
      expect(tester.widget<FreevaButton>(save).onPressed, isNull);
      await tester.enterText(find.byType(TextField), '-50000');
      await tester.pump();
      await tester.tap(save);
      await tester.pump(const Duration(milliseconds: 300));
      expect(model.adjusted, [(bundle.id, b(-50000))]);
    });
  });

  group('use case', () {
    final cases = DefaultWalletUseCases(WalletRepositoryImpl(_Api()));
    test('a card debt cannot be negative', () async {
      final card = wallet('card', 'Thẻ', type: WalletType.credit);
      final r = await cases.reconcile(card, BigInt.from(-1), clientId: 'c');
      expect(r.isLeft(), isTrue);
    });
    test('an overdrawn wallet may be matched to a negative balance', () async {
      final api = _Api()
        ..answer = {
          'currentBalanceMinor': '0',
          'targetBalanceMinor': '-5',
          'deltaMinor': '-5',
          'transaction': null,
        };
      final r = await DefaultWalletUseCases(WalletRepositoryImpl(api))
          .reconcile(wallet('a', 'A'), BigInt.from(-5), clientId: 'c');
      expect(r.isRight(), isTrue);
      expect(api.calls.single.body!['actualBalanceMinor'], '-5');
    });
    test('a hidden wallet is refused before any request', () async {
      final r = await cases.reconcile(
        wallet('a', 'A', archived: true),
        BigInt.one,
        clientId: 'c',
      );
      expect(r.isLeft(), isTrue);
    });
  });

  group('sheet', () {
    final confirm = find.widgetWithText(FreevaButton, 'Khớp số dư');
    final wallets = [wallet('vcb', 'Vietcombank', balance: 17288000)];
    final answer = ReconcileResult(
      currentMinor: b(17288000),
      targetMinor: b(17500000),
      deltaMinor: b(212000),
      adjusted: false,
    );

    Future<StubWalletViewModel> open(
      WidgetTester tester, {
      bool dark = false,
      ReconcileResult? result,
      List<Wallet>? list,
      String id = 'vcb',
    }) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final model = StubWalletViewModel(wallets: list ?? wallets)
        ..result = result ?? answer;
      await tester.pumpWidget(
        await d1App(
          WalletDetailPage(walletId: id),
          model: model,
          detail: StubWalletDetail(walletId: id),
          dark: dark,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Khớp số dư'));
      await tester.pump(const Duration(milliseconds: 400));
      return model;
    }

    testWidgets('shows the server difference and saves', (tester) async {
      final model = await open(tester);
      expect(find.text('Khớp số dư Vietcombank'), findsOneWidget);
      expect(find.text('17.288.000'), findsWidgets);
      expect(find.text('+212.000'), findsNothing);
      await tester.enterText(find.byType(TextField), '17500000');
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('+212.000'), findsOneWidget);
      await tester.tap(confirm);
      await tester.pump(const Duration(milliseconds: 400));
      expect(model.reconciled, [('vcb', b(17500000))]);
    });

    testWidgets('no difference keeps the button off', (tester) async {
      await open(
        tester,
        result: ReconcileResult(
          currentMinor: b(17288000),
          targetMinor: b(17288000),
          deltaMinor: BigInt.zero,
          adjusted: false,
        ),
      );
      await tester.enterText(find.byType(TextField), '17288000');
      await tester.pump(const Duration(milliseconds: 400));
      final button = tester.widget<FreevaButton>(confirm);
      expect(button.onPressed, isNull);
    });

    testWidgets('an overdrawn wallet takes a minus sign, a card does not', (
      tester,
    ) async {
      final model = await open(tester);
      await tester.enterText(find.byType(TextField), '-5000');
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('-5.000'), findsOneWidget);
      await tester.tap(confirm);
      await tester.pump(const Duration(milliseconds: 400));
      expect(model.reconciled, [('vcb', b(-5000))]);
    });

    testWidgets('a card reconciles against debt', (tester) async {
      final model = await open(
        tester,
        id: 'card',
        list: [
          wallet(
            'card',
            'Thẻ chính',
            type: WalletType.credit,
            balance: -11450000,
            limit: 20000000,
          ),
        ],
        result: ReconcileResult(
          currentMinor: b(-11450000),
          targetMinor: b(-11000000),
          deltaMinor: b(450000),
          adjusted: false,
        ),
      );
      expect(find.text('Dư nợ trên app'), findsOneWidget);
      expect(find.text('Dư nợ thật trong app ngân hàng'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '11000000');
      await tester.pump(const Duration(milliseconds: 400));
      // Debt went down by 450.000: the typed number minus what the app shows.
      expect(find.text('−450.000'), findsOneWidget);
      expect(model.reconciled, isEmpty);
    });

    Future<void> golden(WidgetTester tester, String name, bool dark) async {
      await open(tester, dark: dark);
      await tester.enterText(find.byType(TextField), '17500000');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(seconds: 1));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/reconcile_$name.png'),
      );
    }

    testWidgets('golden', skip: !Platform.isMacOS, (tester) async {
      await golden(tester, 'sheet', false);
    });
    testWidgets('golden dark', skip: !Platform.isMacOS, (tester) async {
      await golden(tester, 'sheet_dark', true);
    });
  });
}
