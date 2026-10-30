import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/money/money_input_formatter.dart';
import 'package:mobile/features/wallets/domain/wallet.dart';
import 'package:mobile/features/wallets/presentation/viewmodels/wallet_form.dart';

import '../home/fixtures.dart' show b, wallet;
import 'd1_stub.dart' show creditCard;

const _currencies = [WalletCurrency('VND', 0), WalletCurrency('USD', 2)];

String _type(MoneyInputFormatter f, String text) => f
    .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: text))
    .text;

void main() {
  group('money input', () {
    test('groups thousands per locale and keeps minor digits', () {
      final vnd = MoneyInputFormatter(minorDigits: 0, locale: 'vi');
      expect(_type(vnd, '11450000'), '11.450.000');
      expect(_type(vnd, '11.450.0001'), '114.500.001');
      expect(_type(vnd, '00012'), '12');
      expect(_type(vnd, '-5'), '5');
      final usd = MoneyInputFormatter(
        minorDigits: 2,
        locale: 'en',
        allowNegative: true,
      );
      expect(_type(usd, '-1234.567'), '-1,234.56');
      expect(_type(usd, '12.'), '12.');
    });
    test('reads grouped text back exactly', () {
      expect(parseGroupedMoney('11.450.000', 0, 'vi'), b(11450000));
      expect(parseGroupedMoney('-1,234.56', 2, 'en'), b(-123456));
      expect(
        parseGroupedMoney('9.223.372.036.854.775.807', 0, 'vi'),
        BigInt.parse('9223372036854775807'),
      );
      expect(parseGroupedMoney('', 0, 'vi'), isNull);
      expect(parseGroupedMoney('-', 0, 'vi'), isNull);
    });
  });

  group('wallet form', () {
    WalletForm form({Wallet? editing}) => WalletForm(
      currencies: _currencies,
      clientId: 'c',
      mainCurrency: 'VND',
      wallet: editing,
    );
    test('new wallet: bank, profile currency, empty balance is zero', () {
      final f = form();
      expect(f.type, WalletType.bank);
      expect(f.currency, 'VND');
      final draft = f.build(name: ' Ví ', amount: '', limit: '', locale: 'vi')!;
      expect(draft.name, 'Ví');
      expect(draft.initialBalance, BigInt.zero);
    });
    test('card debt is stored negative; card fields drop for other types', () {
      final f = form()
        ..setType(WalletType.credit)
        ..setDueDay(25);
      final card = f.build(
        name: 'Thẻ',
        amount: '11.450.000',
        limit: '20.000.000',
        minimum: '500.000',
        locale: 'vi',
      )!;
      expect(card.initialBalance, b(-11450000));
      expect(card.creditLimit, b(20000000));
      expect(card.minimumPayment, b(500000));
      expect(card.dueDay, 25);
      f.setType(WalletType.cash);
      final cash = f.build(
        name: 'Ví',
        amount: '5',
        limit: '9',
        minimum: '1',
        locale: 'vi',
      )!;
      expect(cash.initialBalance, b(5));
      expect((cash.creditLimit, cash.dueDay, cash.minimumPayment), (null, null, null));
    });
    test('marks what is wrong instead of saving', () {
      final f = form()..setType(WalletType.credit);
      expect(
        f.build(name: ' ', amount: '1', limit: '-5', minimum: '-1', locale: 'vi'),
        isNull,
      );
      expect(f.errors, {
        WalletFormError.name,
        WalletFormError.limit,
        WalletFormError.minimum,
      });
    });
    test(
      'editing shows debt as positive; locked forms ignore type changes',
      () {
        final f = form(
          editing: Wallet(
            id: 'card',
            createdAt: DateTime.utc(2026),
            draft: WalletDraft(
              name: 'Thẻ',
              type: WalletType.credit,
              currency: 'VND',
              initialBalance: b(-1500000),
              creditLimit: b(20000000),
              minimumPayment: b(300000),
            ),
            balance: b(-1500000),
            version: 1,
            sortOrder: 0,
            archived: false,
            hasTransactions: true,
          ),
        );
        expect(f.amountText('vi'), '1.500.000');
        expect(f.limitText('vi'), '20.000.000');
        expect(f.minimumText('vi'), '300.000');
        expect(f.locked, isTrue);
        f
          ..setType(WalletType.cash)
          ..setCurrency('USD');
        expect((f.type, f.currency), (WalletType.credit, 'VND'));
        expect(form(editing: creditCard()).locked, isFalse);
        expect(
          form(editing: wallet('u', 'U', currency: 'USD')).currency,
          'USD',
        );
      },
    );
  });
}
