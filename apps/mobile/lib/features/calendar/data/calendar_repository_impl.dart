import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/data/authorized_api.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/calendar_month.dart';
import '../domain/calendar_repository.dart';

@LazySingleton(as: CalendarRepository)
class CalendarRepositoryImpl implements CalendarRepository {
  CalendarRepositoryImpl(this._api);
  final AuthorizedApi _api;

  CalendarTransactionItem _tx(Map<String, dynamic> json) =>
      CalendarTransactionItem(
        id: json['id'] as String,
        type: json['type'] as String,
        amountMinor: BigInt.parse(json['amountMinor'] as String),
        currencyCode: json['currencyCode'] as String,
        categoryName: json['categoryName'] as String?,
      );

  CalendarRecurringItem _recurring(Map<String, dynamic> json) =>
      CalendarRecurringItem(
        id: json['id'] as String,
        type: json['type'] as String,
        amountMinor: BigInt.parse(json['amountMinor'] as String),
        currencyCode: json['currencyCode'] as String,
        categoryName: json['categoryName'] as String?,
        occurredOn: json['occurredOn'] as String,
      );

  CalendarBillItem _bill(Map<String, dynamic> json) => CalendarBillItem(
    id: json['id'] as String,
    name: json['name'] as String,
    dueOn: json['dueOn'] as String,
    amountMinor: BigInt.parse(json['amountMinor'] as String),
    amountKind: json['amountKind'] as String,
    currencyCode: json['currencyCode'] as String,
    paid: json['paid'] as bool,
    overdue: json['overdue'] as bool,
  );

  CalendarDay _day(Map<String, dynamic> json) => CalendarDay(
    date: json['date'] as String,
    transactions: (json['transactions'] as List)
        .map((item) => _tx(item as Map<String, dynamic>))
        .toList(growable: false),
    recurring: (json['recurring'] as List)
        .map((item) => _recurring(item as Map<String, dynamic>))
        .toList(growable: false),
    bills: (json['bills'] as List)
        .map((item) => _bill(item as Map<String, dynamic>))
        .toList(growable: false),
  );

  CalendarMonth _parse(Map<String, dynamic> json) => CalendarMonth(
    month: json['month'] as String,
    timezone: json['timezone'] as String,
    today: json['today'] as String,
    days: (json['days'] as List)
        .map((item) => _day(item as Map<String, dynamic>))
        .toList(growable: false),
  );

  @override
  Future<Either<AuthFailure, CalendarMonth>> month(String month) async {
    final result = await _api.request('GET', 'calendar?month=$month');
    return result.fold(left, (json) {
      try {
        return right(_parse(json));
      } catch (_) {
        return left(const AuthFailure(AuthError.unavailable));
      }
    });
  }
}
