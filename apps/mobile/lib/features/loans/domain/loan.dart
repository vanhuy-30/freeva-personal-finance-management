/// Bank-style loans with interest (module 10). `card` exists in the API but
/// the app never offers it: card instalments live under the card wallet.
enum LoanKind { card, personal, mortgage, other }

enum LoanFrequency { weekly, monthly, quarterly, yearly }

enum LoanStatus { active, overdue, paidOff }

class Loan {
  const Loan({
    required this.id,
    required this.clientId,
    required this.kind,
    required this.name,
    required this.currencyCode,
    required this.principalMinor,
    required this.outstandingMinor,
    required this.paidMinor,
    required this.percentBps,
    required this.interestRateBps,
    required this.frequency,
    required this.startDate,
    required this.periodInterestMinor,
    required this.status,
    required this.version,
    this.installmentMinor,
    this.endDate,
    this.nextDueDate,
    this.accountId,
    this.archived = false,
  });

  final String id;
  final String clientId;
  final LoanKind kind;
  final String name;
  final String currencyCode;
  final BigInt principalMinor;
  final BigInt outstandingMinor;

  /// Principal paid so far.
  final BigInt paidMinor;

  /// paid × 10000 / principal, floored (3000 = 30%).
  final int percentBps;

  /// Annual rate; 1200 = 12%.
  final int interestRateBps;
  final BigInt? installmentMinor;
  final LoanFrequency frequency;
  final String startDate;
  final String? endDate;
  final String? nextDueDate;

  /// Interest of one period on what is still owed.
  final BigInt periodInterestMinor;
  final LoanStatus status;
  final String? accountId;
  final bool archived;
  final int version;

  bool get paidOff => status == LoanStatus.paidOff;
  double get progress => percentBps / 10000;
}

/// One period of the plan from `GET /loans/{id}/schedule`.
class LoanScheduleRow {
  const LoanScheduleRow({
    required this.index,
    required this.interestMinor,
    required this.principalMinor,
    required this.paymentMinor,
    required this.outstandingAfterMinor,
    this.dueDate,
  });

  final int index;
  final String? dueDate;
  final BigInt interestMinor;
  final BigInt principalMinor;
  final BigInt paymentMinor;
  final BigInt outstandingAfterMinor;
}

/// Totals of one currency from `GET /loans/summary`.
class LoanTotal {
  const LoanTotal({
    required this.currencyCode,
    required this.loanCount,
    required this.principalMinor,
    required this.paidMinor,
    required this.outstandingMinor,
    required this.dueThisMonthMinor,
  });

  final String currencyCode;
  final int loanCount;
  final BigInt principalMinor;
  final BigInt paidMinor;
  final BigInt outstandingMinor;

  /// Sum of the schedule payments due this month.
  final BigInt dueThisMonthMinor;
}

class LoanDraft {
  const LoanDraft({
    required this.clientId,
    required this.kind,
    required this.name,
    required this.currencyCode,
    required this.principalMinor,
    required this.outstandingMinor,
    required this.interestRateBps,
    required this.frequency,
    required this.startDate,
    this.installmentMinor,
    this.endDate,
    this.nextDueDate,
    this.accountId,
  });

  final String clientId;
  final LoanKind kind;
  final String name;
  final String currencyCode;
  final BigInt principalMinor;
  final BigInt outstandingMinor;
  final int interestRateBps;
  final BigInt? installmentMinor;
  final LoanFrequency frequency;
  final String startDate;
  final String? endDate;
  final String? nextDueDate;
  final String? accountId;
}

/// A payment split into principal and interest; only principal lowers the
/// debt. The API books principal as a `debt` row and interest as "Lãi vay".
class LoanPayment {
  const LoanPayment({
    required this.clientId,
    required this.principalMinor,
    required this.interestMinor,
    required this.accountId,
    required this.paidOn,
  });

  final String clientId;
  final BigInt principalMinor;
  final BigInt interestMinor;
  final String accountId;
  final String paidOn;

  BigInt get amountMinor => principalMinor + interestMinor;
}

BigInt _periodsPerYear(LoanFrequency f) => BigInt.from(switch (f) {
  LoanFrequency.weekly => 52,
  LoanFrequency.monthly => 12,
  LoanFrequency.quarterly => 4,
  LoanFrequency.yearly => 1,
});

/// Fixed payment that clears [principal] in [periods] equal periods at
/// [rateBps] a year, rounded up; same formula as the API (100.000.000, 12%,
/// 12 months → 8.884.879). Null when [periods] is out of 1..600.
BigInt? annuityPayment(
  BigInt principal,
  int rateBps,
  LoanFrequency frequency,
  int periods,
) {
  if (principal <= BigInt.zero || periods < 1 || periods > 600) return null;
  final n = BigInt.from(periods);
  if (rateBps <= 0) return (principal + n - BigInt.one) ~/ n;
  final a = BigInt.from(rateBps);
  final b = BigInt.from(10000) * _periodsPerYear(frequency);
  final grown = (b + a).pow(periods);
  final numerator = principal * a * grown;
  final denominator = b * (grown - b.pow(periods));
  return (numerator + denominator - BigInt.one) ~/ denominator;
}

/// One period after [day] (`yyyy-MM-dd`); month steps clamp to the month's
/// last day, as the API does.
String addPeriod(String day, LoanFrequency frequency) {
  final y = int.parse(day.substring(0, 4));
  final m = int.parse(day.substring(5, 7));
  final d = int.parse(day.substring(8, 10));
  String fmt(int yy, int mm, int dd) =>
      '${yy.toString().padLeft(4, '0')}-${mm.toString().padLeft(2, '0')}-${dd.toString().padLeft(2, '0')}';
  if (frequency == LoanFrequency.weekly) {
    final next = DateTime.utc(y, m, d + 7);
    return fmt(next.year, next.month, next.day);
  }
  final step = switch (frequency) {
    LoanFrequency.quarterly => 3,
    LoanFrequency.yearly => 12,
    _ => 1,
  };
  final total = y * 12 + (m - 1) + step;
  final ny = total ~/ 12;
  final nm = total % 12 + 1;
  final last = DateTime.utc(ny, nm + 1, 0).day;
  return fmt(ny, nm, d < last ? d : last);
}

/// Payments from [first] up to and including [end] (both `yyyy-MM-dd`);
/// 0 when [end] comes first.
int periodsUntil(String first, String end, LoanFrequency frequency) {
  var count = 0;
  var day = first;
  while (day.compareTo(end) <= 0 && count <= 600) {
    count++;
    day = addPeriod(day, frequency);
  }
  return count;
}

/// Basis points from a typed rate ("12", "9,5", "9.75"); null when it is
/// not a number with at most two decimals or is above 1000%.
int? parseRateBps(String text) {
  final clean = text.trim().replaceAll(',', '.');
  final match = RegExp(r'^(\d{1,4})(?:\.(\d{1,2}))?$').firstMatch(clean);
  if (match == null) return null;
  final whole = int.parse(match.group(1)!);
  final frac = (match.group(2) ?? '').padRight(2, '0');
  final bps = whole * 100 + int.parse(frac.isEmpty ? '0' : frac);
  return bps > 100000 ? null : bps;
}

/// "12", "9,5" (vi) or "9.5" (en) from basis points.
String formatRate(int bps, String decimalSeparator) {
  final whole = bps ~/ 100;
  final frac = bps % 100;
  if (frac == 0) return '$whole';
  final text = frac.toString().padLeft(2, '0').replaceAll(RegExp(r'0$'), '');
  return '$whole$decimalSeparator$text';
}
