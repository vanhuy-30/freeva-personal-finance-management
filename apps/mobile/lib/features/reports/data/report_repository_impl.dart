import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/data/authorized_api.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/report.dart';
import '../domain/report_flow.dart';
import '../domain/report_holdings.dart';
import '../domain/report_period.dart';
import '../domain/report_repository.dart';

@LazySingleton(as: ReportRepository)
class ReportRepositoryImpl implements ReportRepository {
  ReportRepositoryImpl(this._api);

  final AuthorizedApi _api;

  @override
  Future<Either<AuthFailure, CashflowReport>> cashflow(
    ReportPeriodQuery query, {
    String? displayCurrency,
  }) => _request('GET', _cashflowPath(query, displayCurrency), _cashflow);

  @override
  Future<Either<AuthFailure, FlowReport>> flow(ReportPeriodQuery query) =>
      _request('GET', _periodPath('reports/flow', query), _flow);

  @override
  Future<Either<AuthFailure, HoldingsReport>> holdings(
    ReportPeriodQuery query,
  ) => _request('GET', _periodPath('reports/holdings', query), _holdings);

  @override
  Future<Either<AuthFailure, MonthReviewReport>> monthReview({String? on}) =>
      _request(
        'GET',
        Uri(
          path: 'reports/month-review',
          queryParameters: {if (on != null) 'on': on},
        ).toString(),
        _monthReview,
      );

  @override
  Future<Either<AuthFailure, TrendReport>> trend(
    ReportPeriodKind kind, {
    String? on,
  }) => _request(
    'GET',
    Uri(
      path: 'reports/trend',
      queryParameters: {'period': kind.name, if (on != null) 'on': on},
    ).toString(),
    _trend,
  );

  @override
  Future<Either<AuthFailure, NetWorthReport>> netWorth({
    String? displayCurrency,
  }) => _request(
    'GET',
    Uri(
      path: 'reports/net-worth',
      queryParameters: displayCurrency == null
          ? null
          : {'displayCurrency': displayCurrency},
    ).toString(),
    _netWorth,
  );

  Future<Either<AuthFailure, T>> _request<T>(
    String method,
    String path,
    T Function(Map<String, dynamic>) parse,
  ) async {
    final result = await _api.request(method, path);
    return result.fold(left, (json) {
      try {
        return right(parse(json));
      } catch (_) {
        return left(const AuthFailure(AuthError.unavailable));
      }
    });
  }
}

String _periodPath(String path, ReportPeriodQuery query) => Uri(
  path: path,
  queryParameters: {
    'period': query.kind.name,
    if (query.on != null) 'on': query.on,
    if (query.from != null) 'from': query.from,
    if (query.to != null) 'to': query.to,
  },
).toString();

String _cashflowPath(ReportPeriodQuery query, String? displayCurrency) => Uri(
  path: 'reports/cashflow',
  queryParameters: {
    'period': query.kind.name,
    if (query.on != null) 'on': query.on,
    if (query.from != null) 'from': query.from,
    if (query.to != null) 'to': query.to,
    if (displayCurrency != null) 'displayCurrency': displayCurrency,
  },
).toString();

CashflowReport _cashflow(Map<String, dynamic> json) => CashflowReport(
  period: _period(json['period'] as Map<String, dynamic>),
  totals: _rows(json['totals'], _total),
  byCategory: _rows(json['byCategory'], _category),
  byAccount: _rows(json['byAccount'], _account),
  converted: _converted(json['converted'], _cashflowConverted),
  walletBalances: _rows(json['walletBalances'] ?? const [], _walletBalance),
);

WalletBalance _walletBalance(Map<String, dynamic> json) => WalletBalance(
  currency: _currency(json['currency']),
  endMinor: _money(json['endMinor']),
  previousEndMinor: _money(json['previousEndMinor']),
);

FlowReport _flow(Map<String, dynamic> json) {
  final period = json['period'] as Map<String, dynamic>;
  return FlowReport(
    kind: ReportPeriodKind.values.byName(period['kind'] as String),
    from: _date(period['from']),
    to: _date(period['to']),
    granularity: FlowGranularity.values.byName(json['granularity'] as String),
    buckets: _rows(json['buckets'], _bucket),
  );
}

HoldingsReport _holdings(Map<String, dynamic> json) {
  final period = json['period'] as Map<String, dynamic>;
  return HoldingsReport(
    kind: ReportPeriodKind.values.byName(period['kind'] as String),
    from: _date(period['from']),
    to: _date(period['to']),
    debt: _rows(json['debt'], _debtChange),
    investments: _rows(json['investments'], _investChange),
    nextLoanDue: _rows(json['nextLoanDue'], _loanDue),
  );
}

DebtChange _debtChange(Map<String, dynamic> json) => DebtChange(
  currency: _currency(json['currency']),
  start: _money(json['startMinor']),
  end: _money(json['endMinor']),
  change: _money(json['changeMinor']),
  paid: _money(json['paidMinor']),
  borrowed: _money(json['borrowedMinor']),
);

InvestChange _investChange(Map<String, dynamic> json) {
  final bps = json['pnlBps'];
  if (bps != null && bps is! int) throw const FormatException();
  return InvestChange(
    currency: _currency(json['currency']),
    startValue: _money(json['startValueMinor']),
    endValue: _money(json['endValueMinor']),
    invested: _money(json['investedMinor']),
    withdrawn: _money(json['withdrawnMinor']),
    pnl: _money(json['pnlMinor']),
    pnlBps: bps as int?,
  );
}

LoanDue _loanDue(Map<String, dynamic> json) => LoanDue(
  currency: _currency(json['currency']),
  dueOn: _date(json['dueOn']),
  amount: json['amountMinor'] == null ? null : _money(json['amountMinor']),
);

MonthReviewReport _monthReview(Map<String, dynamic> json) {
  final period = _period(json['period'] as Map<String, dynamic>);
  if (period.kind != ReportPeriodKind.month) throw const FormatException();
  return MonthReviewReport(
    period: period,
    currencies: _rows(json['currencies'], _monthCurrency),
  );
}

MonthReviewCurrency _monthCurrency(Map<String, dynamic> json) {
  final rate = json['savingsRateBps'];
  if (rate != null && rate is! int) throw const FormatException();
  return MonthReviewCurrency(
    currency: _currency(json['currency']),
    incomeMinor: _money(json['incomeMinor']),
    expenseMinor: _money(json['expenseMinor']),
    savingsMinor: _money(json['savingsMinor']),
    savingsRateBps: rate as int?,
    topCategories: _rows(json['topCategories'], _monthCategory),
  );
}

MonthReviewCategory _monthCategory(Map<String, dynamic> json) =>
    MonthReviewCategory(
      categoryId: json['categoryId'] as String?,
      parentId: json['parentId'] as String?,
      expenseMinor: _money(json['expenseMinor']),
      transactionCount: json['transactionCount'] as int,
    );

ReportPeriod _period(Map<String, dynamic> json) {
  final start = json['fiscalMonthStartDay'] as int;
  // The server owns the upper bound (`limit.periodStartDayMax`).
  if (start < 1) throw const FormatException();
  final timezone = json['timezone'] as String;
  if (timezone.isEmpty) throw const FormatException();
  return ReportPeriod(
    kind: ReportPeriodKind.values.byName(json['kind'] as String),
    from: _date(json['from']),
    to: _date(json['to']),
    timezone: timezone,
    fiscalMonthStartDay: start,
  );
}

CashflowTotal _total(Map<String, dynamic> json) => CashflowTotal(
  currency: _currency(json['currency']),
  incomeMinor: _money(json['incomeMinor']),
  expenseMinor: _money(json['expenseMinor']),
  netMinor: _money(json['netMinor']),
);

CashflowCategoryRow _category(Map<String, dynamic> json) => CashflowCategoryRow(
  categoryId: json['categoryId'] as String?,
  parentId: json['parentId'] as String?,
  currency: _currency(json['currency']),
  incomeMinor: _money(json['incomeMinor']),
  expenseMinor: _money(json['expenseMinor']),
  transactionCount: json['transactionCount'] as int,
);

TrendReport _trend(Map<String, dynamic> json) => TrendReport(
  kind: ReportPeriodKind.values.byName(json['kind'] as String),
  buckets: _rows(json['buckets'], _bucket),
);

TrendBucket _bucket(Map<String, dynamic> json) => TrendBucket(
  from: _date(json['from']),
  to: _date(json['to']),
  totals: _rows(
    json['totals'],
    (row) => TrendTotal(
      currency: _currency(row['currency']),
      incomeMinor: _money(row['incomeMinor']),
      expenseMinor: _money(row['expenseMinor']),
    ),
  ),
);

CashflowAccountRow _account(Map<String, dynamic> json) => CashflowAccountRow(
  accountId: json['accountId'] as String,
  currency: _currency(json['currency']),
  incomeMinor: _money(json['incomeMinor']),
  expenseMinor: _money(json['expenseMinor']),
  transferMinor: _money(json['transferMinor']),
  netMinor: _money(json['netMinor']),
);

NetWorthReport _netWorth(Map<String, dynamic> json) => NetWorthReport(
  items: _rows(json['items'], _netWorthTotal),
  converted: _converted(json['converted'], _netWorthConverted),
);

T? _converted<T>(Object? value, T Function(Map<String, dynamic>) parse) =>
    value == null ? null : parse(value as Map<String, dynamic>);

NetWorthConverted _netWorthConverted(Map<String, dynamic> json) =>
    NetWorthConverted(
      currency: _currency(json['currency']),
      assetsMinor: _money(json['assetsMinor']),
      liabilitiesMinor: _money(json['liabilitiesMinor']),
      netWorthMinor: _money(json['netWorthMinor']),
      unconverted: _rows(json['unconverted'], _unconverted),
    );

CashflowConverted _cashflowConverted(Map<String, dynamic> json) =>
    CashflowConverted(
      currency: _currency(json['currency']),
      incomeMinor: _money(json['incomeMinor']),
      expenseMinor: _money(json['expenseMinor']),
      unconverted: _rows(json['unconverted'], _unconverted),
    );

UnconvertedCurrency _unconverted(Map<String, dynamic> json) =>
    UnconvertedCurrency(
      currency: _currency(json['currency']),
      reason: switch (json['reason']) {
        'MISSING_RATE' => UnconvertedReason.missingRate,
        'FRACTIONAL' => UnconvertedReason.fractional,
        _ => throw const FormatException(),
      },
    );

NetWorthTotal _netWorthTotal(Map<String, dynamic> json) => NetWorthTotal(
  currency: _currency(json['currency']),
  assetsMinor: _money(json['assetsMinor']),
  liabilitiesMinor: _money(json['liabilitiesMinor']),
  netWorthMinor: _money(json['netWorthMinor']),
);

List<T> _rows<T>(Object? value, T Function(Map<String, dynamic>) parse) =>
    (value as List).map((row) => parse(row as Map<String, dynamic>)).toList();

String _date(Object? value) {
  final text = value as String;
  if (!isCalendarDate(text)) throw const FormatException();
  return text;
}

String _currency(Object? value) {
  final text = value as String;
  if (!RegExp(r'^[A-Z]{3}$').hasMatch(text)) throw const FormatException();
  return text;
}

BigInt _money(Object? value) {
  final text = value as String;
  if (!RegExp(r'^-?[0-9]+$').hasMatch(text)) throw const FormatException();
  return BigInt.parse(text);
}
