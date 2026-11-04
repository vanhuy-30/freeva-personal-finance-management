/// Money lent to someone (they owe you) or borrowed from someone (you owe
/// them). Not income or expense; no interest.
enum DebtDirection { lent, borrowed }

/// `overdue` = past the due date with money still owed.
enum DebtStatus { open, overdue, settled }

class PersonalDebt {
  const PersonalDebt({
    required this.id,
    required this.clientId,
    required this.direction,
    required this.counterparty,
    required this.currencyCode,
    required this.principalMinor,
    required this.outstandingMinor,
    required this.paidMinor,
    required this.accountId,
    required this.occurredOn,
    required this.status,
    required this.version,
    this.dueDate,
    this.note,
    this.archived = false,
  });

  final String id;
  final String clientId;
  final DebtDirection direction;
  final String counterparty;
  final String currencyCode;

  /// Amount first lent or borrowed.
  final BigInt principalMinor;

  /// What is still owed.
  final BigInt outstandingMinor;

  /// Received back (lent) or paid back (borrowed) so far.
  final BigInt paidMinor;
  final String accountId;

  /// `YYYY-MM-DD`.
  final String occurredOn;
  final String? dueDate;
  final String? note;
  final DebtStatus status;
  final bool archived;
  final int version;

  bool get lent => direction == DebtDirection.lent;
  bool get settled => status == DebtStatus.settled;

  /// Share already settled, 0..1, for the progress bar.
  double get progress => principalMinor <= BigInt.zero
      ? 0
      : (paidMinor * BigInt.from(10000) ~/ principalMinor).toInt() / 10000;
}

/// Totals of one currency from `GET /personal-debts/summary`.
class DebtTotal {
  const DebtTotal({
    required this.currencyCode,
    required this.receivableMinor,
    required this.payableMinor,
    required this.receivableCount,
    required this.payableCount,
  });

  final String currencyCode;

  /// Others owe you.
  final BigInt receivableMinor;

  /// You owe others.
  final BigInt payableMinor;
  final int receivableCount;
  final int payableCount;
}

/// One repayment received or made.
class DebtPayment {
  const DebtPayment({
    required this.id,
    required this.accountId,
    required this.amountMinor,
    required this.paidOn,
  });

  final String id;
  final String accountId;
  final BigInt amountMinor;
  final String paidOn;
}

class DebtDraft {
  const DebtDraft({
    required this.clientId,
    required this.direction,
    required this.counterparty,
    required this.amountMinor,
    required this.accountId,
    required this.occurredOn,
    this.dueDate,
    this.note,
  });

  /// Kept across retries so a resend never records the debt twice.
  final String clientId;
  final DebtDirection direction;
  final String counterparty;
  final BigInt amountMinor;
  final String accountId;
  final String occurredOn;
  final String? dueDate;
  final String? note;
}

class DebtRepay {
  const DebtRepay({
    required this.clientId,
    required this.amountMinor,
    required this.accountId,
    required this.paidOn,
  });

  final String clientId;
  final BigInt amountMinor;
  final String accountId;
  final String paidOn;
}

/// Half of [outstanding] rounded down to a whole unit of the currency
/// ("Một nửa"): 2.000.000 → 1.000.000, 5 → 2. Never zero while something is
/// owed.
BigInt halfOf(BigInt outstanding, int digits) {
  if (outstanding <= BigInt.one) return outstanding;
  final unit = BigInt.from(10).pow(digits);
  final half = outstanding ~/ BigInt.two;
  final whole = half ~/ unit * unit;
  return whole > BigInt.zero ? whole : half;
}
