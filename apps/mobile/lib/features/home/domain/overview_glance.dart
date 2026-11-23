import '../../calendar/domain/calendar_month.dart';
import '../../investments/domain/investment.dart';
import '../../loans/domain/loan.dart';
import '../../net_worth/domain/net_worth_history.dart';
import '../../wallets/domain/credit_card_status.dart';

/// Where an upcoming payment comes from.
enum UpcomingKind { bill, recurring, loan, card }

/// One payment still to make, in the main currency.
class UpcomingPayment {
  const UpcomingPayment({
    required this.kind,
    required this.dueOn,
    required this.amountMinor,
    this.name,
  });

  final UpcomingKind kind;

  /// Null for a recurring item without a category: the UI says "Định kỳ".
  final String? name;
  final DateTime dueOn;
  final BigInt amountMinor;
}

/// "Sắp phải trả" tile (PA 3): what is due from today to [until].
class UpcomingSummary {
  const UpcomingSummary({
    required this.totalMinor,
    required this.count,
    required this.nearest,
    required this.until,
  });

  final BigInt totalMinor;
  final int count;

  /// Earliest item; an overdue bill comes first.
  final UpcomingPayment nearest;
  final DateTime until;
}

DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

DateTime? _parse(String? value) {
  if (value == null) return null;
  final parsed = DateTime.tryParse(value);
  return parsed == null ? null : _day(parsed);
}

/// Unpaid bills due by [until] (overdue ones too), recurring expenses, loan
/// installments and credit-card debt due between [today] and [until], in
/// [currency] only. Null when nothing is due.
UpcomingSummary? upcomingSummary({
  required DateTime today,
  required DateTime until,
  required String currency,
  required List<CalendarMonth> calendar,
  required List<Loan> loans,
  required List<CreditCardStatus> cards,
}) {
  final from = _day(today);
  final to = _day(until);
  bool ahead(DateTime day) => !day.isBefore(from) && !day.isAfter(to);
  final items = <UpcomingPayment>[];
  final seenBills = <String>{};
  for (final month in calendar) {
    for (final day in month.days) {
      for (final bill in day.bills) {
        final due = _parse(bill.dueOn);
        if (bill.paid || due == null || due.isAfter(to)) continue;
        if (bill.currencyCode != currency || !seenBills.add(bill.id)) continue;
        items.add(
          UpcomingPayment(
            kind: UpcomingKind.bill,
            name: bill.name,
            dueOn: due,
            amountMinor: bill.amountMinor.abs(),
          ),
        );
      }
      for (final item in day.recurring) {
        final due = _parse(item.occurredOn);
        if (item.type != 'expense' || due == null || !ahead(due)) continue;
        if (item.currencyCode != currency) continue;
        items.add(
          UpcomingPayment(
            kind: UpcomingKind.recurring,
            name: item.categoryName,
            dueOn: due,
            amountMinor: item.amountMinor.abs(),
          ),
        );
      }
    }
  }
  for (final loan in loans) {
    final due = _parse(loan.nextDueDate);
    final amount = loan.installmentMinor;
    if (loan.archived || due == null || due.isAfter(to)) continue;
    if (amount == null || amount <= BigInt.zero) continue;
    if (loan.currencyCode != currency) continue;
    items.add(
      UpcomingPayment(
        kind: UpcomingKind.loan,
        name: loan.name,
        dueOn: due,
        amountMinor: amount,
      ),
    );
  }
  for (final card in cards) {
    final due = card.nextDue;
    if (due == null || !ahead(_day(due)) || card.used <= BigInt.zero) continue;
    if (card.wallet.draft.currency != currency) continue;
    items.add(
      UpcomingPayment(
        kind: UpcomingKind.card,
        name: card.wallet.draft.name,
        dueOn: _day(due),
        amountMinor: card.used,
      ),
    );
  }
  if (items.isEmpty) return null;
  items.sort((a, b) => a.dueOn.compareTo(b.dueOn));
  return UpcomingSummary(
    totalMinor: items.fold(BigInt.zero, (sum, item) => sum + item.amountMinor),
    count: items.length,
    nearest: items.first,
    until: to,
  );
}

/// Calendar months (`YYYY-MM`) that cover [today] to [until].
List<String> calendarMonthsBetween(DateTime today, DateTime until) {
  String key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';
  final months = <String>[];
  var cursor = DateTime(today.year, today.month);
  final last = DateTime(until.year, until.month);
  while (!cursor.isAfter(last) && months.length < 3) {
    months.add(key(cursor));
    cursor = DateTime(cursor.year, cursor.month + 1);
  }
  return months;
}

/// Net worth change since the end of the day before [monthFrom], in basis
/// points of that day's value. Null without such a point or when it was not
/// above zero.
int? netWorthChangeBps(NetWorthSeries? series, String monthFrom) {
  final points = series?.points ?? const <NetWorthPoint>[];
  if (points.length < 2) return null;
  NetWorthPoint? base;
  for (final point in points) {
    if (point.asOf.compareTo(monthFrom) < 0) base = point;
  }
  if (base == null || base.netWorthMinor <= BigInt.zero) return null;
  final change = points.last.netWorthMinor - base.netWorthMinor;
  return (change * BigInt.from(10000) ~/ base.netWorthMinor).toInt();
}

/// "Đầu tư" tile: value, gain and the faint line, in one currency.
class InvestmentGlance {
  const InvestmentGlance({
    required this.valueMinor,
    required this.unrealizedMinor,
    required this.trend,
    required this.costMinor,
    this.kinds = const [],
    this.unrealizedBps,
  });

  final BigInt valueMinor;
  final BigInt unrealizedMinor;

  /// Money put in (vốn).
  final BigInt costMinor;

  /// Categories held, largest first; shown when the tile has the full width.
  final List<InvestmentTotal> kinds;

  /// Null when nothing is priced yet.
  final int? unrealizedBps;

  /// Oldest-first values; fewer than two means no line.
  final List<BigInt> trend;
}

/// Null when the user holds nothing in [currency]. The line comes from the
/// investment part of [series] when it is in the same currency.
InvestmentGlance? investmentGlance(
  InvestmentSummary? summary,
  NetWorthSeries? series,
  String currency,
) {
  final total = summary?.totalOf(currency);
  if (total == null || total.currentValueMinor <= BigInt.zero) return null;
  return InvestmentGlance(
    valueMinor: total.currentValueMinor,
    unrealizedMinor: total.unrealizedMinor,
    unrealizedBps: total.unrealizedBps,
    costMinor: total.costBasisMinor,
    kinds: summary!.kindsOf(currency),
    trend: series == null || series.currency != currency
        ? const []
        : [
            for (final point in series.points)
              if (point.investmentMinor case final BigInt value) value,
          ],
  );
}
