import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/calendar/domain/calendar_month.dart';
import 'package:mobile/features/home/domain/overview_glance.dart';
import 'package:mobile/features/investments/domain/investment.dart';
import 'package:mobile/features/net_worth/domain/net_worth_history.dart';
import 'package:mobile/features/wallets/domain/credit_card_status.dart';
import 'package:mobile/features/wallets/domain/wallet.dart';

import 'fixtures.dart';

CalendarMonth calendar(List<CalendarDay> days) => CalendarMonth(
  month: '2026-11',
  timezone: 'Asia/Ho_Chi_Minh',
  today: '2026-11-10',
  days: days,
);

CalendarDay billDay(
  String date,
  String name,
  int amount, {
  bool paid = false,
  String currency = 'VND',
}) => CalendarDay(
  date: date,
  transactions: const [],
  recurring: const [],
  bills: [
    CalendarBillItem(
      id: name,
      name: name,
      dueOn: date,
      amountMinor: b(amount),
      amountKind: 'fixed',
      currencyCode: currency,
      paid: paid,
      overdue: false,
    ),
  ],
);

CalendarDay recurringDay(String date, String type, int amount) => CalendarDay(
  date: date,
  transactions: const [],
  recurring: [
    CalendarRecurringItem(
      id: 'r-$date',
      type: type,
      amountMinor: b(amount),
      currencyCode: 'VND',
      categoryName: null,
      occurredOn: date,
    ),
  ],
  bills: const [],
);

NetWorthPoint point(String asOf, int net, {int? invested}) => NetWorthPoint(
  asOf: asOf,
  assetsMinor: b(net),
  liabilitiesMinor: BigInt.zero,
  netWorthMinor: b(net),
  investmentMinor: invested == null ? null : b(invested),
);

void main() {
  final today = DateTime(2026, 11, 10, 9, 30);
  final until = DateTime(2026, 11, 30);

  group('upcomingSummary', () {
    test('adds unpaid bills, recurring expenses, loans and card debt', () {
      final data = pa3Overview();
      final cards = [
        for (final wallet in data.wallets)
          if (wallet.draft.type == WalletType.credit)
            CreditCardStatus.of(wallet, today),
      ];
      final result = upcomingSummary(
        today: today,
        until: until,
        currency: 'VND',
        calendar: [
          calendar([
            billDay('2026-11-15', 'Học phí', 6230000),
            billDay('2026-11-12', 'Điện', 800000, paid: true),
            billDay('2026-11-20', 'Netflix', 260000, currency: 'USD'),
            recurringDay('2026-11-28', 'expense', 500000),
            recurringDay('2026-11-28', 'income', 18500000),
            recurringDay('2026-11-05', 'expense', 999),
          ]),
        ],
        loans: data.loans!,
        cards: cards,
      )!;
      // Tuition 6,23 + recurring 0,5 + mortgage 9,2 + main card 15,6; the
      // travel card is due 05/12, after the month.
      expect(result.totalMinor, b(31530000));
      expect(result.count, 4);
      expect(result.nearest.name, 'Học phí');
      expect(result.until, until);
    });

    test('an overdue bill comes first; nothing due gives null', () {
      final result = upcomingSummary(
        today: today,
        until: until,
        currency: 'VND',
        calendar: [
          calendar([
            billDay('2026-11-03', 'Nước', 150000),
            billDay('2026-11-15', 'Học phí', 6230000),
          ]),
        ],
        loans: const [],
        cards: const [],
      )!;
      expect(result.nearest.name, 'Nước');
      expect(result.nearest.dueOn, DateTime(2026, 11, 3));
      expect(
        upcomingSummary(
          today: today,
          until: until,
          currency: 'VND',
          calendar: const [],
          loans: const [],
          cards: const [],
        ),
        isNull,
      );
    });
  });

  test('calendarMonthsBetween covers a fiscal month over two months', () {
    expect(calendarMonthsBetween(today, until), ['2026-11']);
    expect(
      calendarMonthsBetween(DateTime(2026, 11, 28), DateTime(2026, 12, 24)),
      ['2026-11', '2026-12'],
    );
  });

  group('netWorthChangeBps', () {
    NetWorthSeries series(List<NetWorthPoint> points) => NetWorthSeries(
      window: NetWorthWindow.month,
      currency: 'VND',
      points: points,
    );

    test('compares today with the last day before the month', () {
      final value = netWorthChangeBps(
        series([
          point('2026-10-30', 600),
          point('2026-10-31', 1000),
          point('2026-11-05', 900),
          point('2026-11-10', 1018),
        ]),
        '2026-11-01',
      );
      expect(value, 180);
    });

    test('is null without a base or with a base at or below zero', () {
      expect(netWorthChangeBps(null, '2026-11-01'), isNull);
      expect(
        netWorthChangeBps(
          series([point('2026-11-01', 10), point('2026-11-10', 20)]),
          '2026-11-01',
        ),
        isNull,
      );
      expect(
        netWorthChangeBps(
          series([point('2026-10-31', -5), point('2026-11-10', 20)]),
          '2026-11-01',
        ),
        isNull,
      );
    });
  });

  test('investmentGlance takes the total and the line of one currency', () {
    final summary = InvestmentSummary(
      totals: [
        InvestmentTotal(
          currencyCode: 'VND',
          costBasisMinor: b(100),
          currentValueMinor: b(108),
          unrealizedMinor: b(8),
          unrealizedBps: 800,
          unpricedCount: 0,
        ),
      ],
    );
    final trend = NetWorthSeries(
      window: NetWorthWindow.month,
      currency: 'VND',
      points: [
        point('2026-11-09', 500, invested: 100),
        point('2026-11-10', 510),
        point('2026-11-11', 520, invested: 108),
      ],
    );
    final glance = investmentGlance(summary, trend, 'VND')!;
    expect(glance.valueMinor, b(108));
    expect(glance.unrealizedBps, 800);
    expect(glance.trend, [b(100), b(108)]);
    expect(investmentGlance(summary, trend, 'USD'), isNull);
    expect(investmentGlance(null, trend, 'VND'), isNull);
  });
}
