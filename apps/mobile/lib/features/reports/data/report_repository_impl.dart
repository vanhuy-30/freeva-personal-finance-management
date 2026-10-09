import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/data/authorized_api.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/report.dart';
import '../domain/report_repository.dart';

@LazySingleton(as: ReportRepository)
class ReportRepositoryImpl implements ReportRepository {
  ReportRepositoryImpl(this._api);

  final AuthorizedApi _api;

  @override
  Future<Either<AuthFailure, CashflowReport>> cashflow(
    ReportPeriodQuery query,
  ) => _request('GET', _cashflowPath(query), _cashflow);

  @override
  Future<Either<AuthFailure, NetWorthReport>> netWorth() =>
      _request('GET', 'reports/net-worth', _netWorth);

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

String _cashflowPath(ReportPeriodQuery query) => Uri(
  path: 'reports/cashflow',
  queryParameters: {
    'period': query.kind.name,
    if (query.on != null) 'on': query.on,
    if (query.from != null) 'from': query.from,
    if (query.to != null) 'to': query.to,
  },
).toString();

CashflowReport _cashflow(Map<String, dynamic> json) => CashflowReport(
  period: _period(json['period'] as Map<String, dynamic>),
  totals: _rows(json['totals'], _total),
  byCategory: _rows(json['byCategory'], _category),
  byAccount: _rows(json['byAccount'], _account),
);

ReportPeriod _period(Map<String, dynamic> json) {
  final start = json['fiscalMonthStartDay'] as int;
  if (start < 1 || start > 28) throw const FormatException();
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
);

CashflowAccountRow _account(Map<String, dynamic> json) => CashflowAccountRow(
  accountId: json['accountId'] as String,
  currency: _currency(json['currency']),
  incomeMinor: _money(json['incomeMinor']),
  expenseMinor: _money(json['expenseMinor']),
  transferMinor: _money(json['transferMinor']),
  netMinor: _money(json['netMinor']),
);

NetWorthReport _netWorth(Map<String, dynamic> json) =>
    NetWorthReport(items: _rows(json['items'], _netWorthTotal));

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
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) {
    throw const FormatException();
  }
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
