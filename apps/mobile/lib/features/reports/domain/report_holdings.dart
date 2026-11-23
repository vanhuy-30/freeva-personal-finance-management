import 'report.dart';

/// How the debt of one currency moved during a period (`GET /reports/holdings`).
/// Debt is loans, money borrowed from people and what credit-card wallets owe.
class DebtChange {
  const DebtChange({
    required this.currency,
    required this.start,
    required this.end,
    required this.change,
    required this.paid,
    required this.borrowed,
  });

  final String currency;
  final BigInt start;
  final BigInt end;

  /// End minus start: negative while the debt is shrinking.
  final BigInt change;
  final BigInt paid;

  /// New loans, new borrowing and spending on a card: `change + paid`.
  final BigInt borrowed;
}

/// Investments of one currency over a period; [pnl] is the value gained or
/// lost, not the value change (money put in and taken out is left out of it).
class InvestChange {
  const InvestChange({
    required this.currency,
    required this.startValue,
    required this.endValue,
    required this.invested,
    required this.withdrawn,
    required this.pnl,
    required this.pnlBps,
  });

  final String currency;
  final BigInt startValue;
  final BigInt endValue;
  final BigInt invested;
  final BigInt withdrawn;
  final BigInt pnl;

  /// Basis points of the money at stake; null before anything was invested.
  final int? pnlBps;
}

/// Soonest unpaid installment of a loan.
class LoanDue {
  const LoanDue({
    required this.currency,
    required this.dueOn,
    required this.amount,
  });

  final String currency;
  final String dueOn;
  final BigInt? amount;
}

class HoldingsReport {
  const HoldingsReport({
    required this.kind,
    required this.from,
    required this.to,
    required this.debt,
    required this.investments,
    required this.nextLoanDue,
  });

  final ReportPeriodKind kind;
  final String from;
  final String to;
  final List<DebtChange> debt;
  final List<InvestChange> investments;
  final List<LoanDue> nextLoanDue;

  DebtChange? debtOf(String currency) =>
      debt.where((row) => row.currency == currency).firstOrNull;

  InvestChange? investOf(String currency) =>
      investments.where((row) => row.currency == currency).firstOrNull;

  LoanDue? dueOf(String currency) =>
      nextLoanDue.where((row) => row.currency == currency).firstOrNull;
}
