import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/data/authorized_api.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/budget.dart';
import '../domain/budget_repository.dart';

@LazySingleton(as: BudgetRepository)
class BudgetRepositoryImpl implements BudgetRepository {
  BudgetRepositoryImpl(this._api);

  final AuthorizedApi _api;

  Future<Either<AuthFailure, T>> _request<T>(
    String method,
    String path,
    T Function(Map<String, dynamic>) parse, {
    Map<String, dynamic>? body,
  }) async {
    final result = await _api.request(method, path, body: body);
    return result.fold(left, (json) {
      try {
        return right(parse(json));
      } catch (_) {
        return left(const AuthFailure(AuthError.unavailable));
      }
    });
  }

  @override
  Future<Either<AuthFailure, BudgetCurrent>> current({
    String? on,
    BudgetApplyTo? applyTo,
  }) => _request(
    'GET',
    Uri(
      path: 'budgets/current',
      queryParameters: {
        if (on != null) 'on': on,
        if (applyTo != null) 'applyTo': budgetApplyToApi(applyTo),
      },
    ).toString(),
    _current,
  );

  @override
  Future<Either<AuthFailure, BudgetSummary>> put(BudgetDraft draft) => _request(
    'PUT',
    'budgets/current',
    _summary,
    body: {
      'limitMinor': draft.limitMinor.toString(),
      'alertThresholds': draft.alertThresholds,
      'categories': [
        for (final line in draft.categories)
          {
            'categoryId': line.categoryId,
            'limitMinor': line.limitMinor.toString(),
          },
      ],
      'applyTo': budgetApplyToApi(draft.applyTo),
      if (draft.on != null) 'on': draft.on,
      if (draft.version != null) 'version': draft.version,
    },
  );

  @override
  Future<Either<AuthFailure, Unit>> delete({
    BudgetApplyTo applyTo = BudgetApplyTo.defaultTemplate,
    String? on,
    int? version,
  }) => _request(
    'DELETE',
    Uri(
      path: 'budgets/current',
      queryParameters: {
        'applyTo': budgetApplyToApi(applyTo),
        if (on != null) 'on': on,
        if (version != null) 'version': '$version',
      },
    ).toString(),
    (_) => unit,
  );
}

BudgetCurrent _current(Map<String, dynamic> json) {
  final budget = json['budget'];
  return BudgetCurrent(
    budget: budget == null ? null : _summary(budget as Map<String, dynamic>),
    period: _period(json['period'] as Map<String, dynamic>),
  );
}

BudgetSummary _summary(Map<String, dynamic> json) => BudgetSummary(
  id: json['id'] as String,
  currencyCode: _currency(json['currencyCode']),
  limitMinor: _money(json['limitMinor']),
  spentMinor: _money(json['spentMinor']),
  remainingMinor: _money(json['remainingMinor']),
  percentBps: json['percentBps'] as int,
  status: BudgetStatus.values.byName(json['status'] as String),
  alertThresholds: (json['alertThresholds'] as List).cast<int>(),
  crossedThresholds: (json['crossedThresholds'] as List).cast<int>(),
  categories: [
    for (final row in json['categories'] as List)
      _category(row as Map<String, dynamic>),
  ],
  period: _period(json['period'] as Map<String, dynamic>),
  applyTo: budgetApplyToFromApi(json['applyTo'] as String? ?? 'default'),
  isOverride: json['isOverride'] as bool? ?? false,
  version: json['version'] as int,
);

BudgetCategoryLine _category(Map<String, dynamic> json) => BudgetCategoryLine(
  categoryId: json['categoryId'] as String,
  limitMinor: _money(json['limitMinor']),
  spentMinor: _money(json['spentMinor']),
  remainingMinor: _money(json['remainingMinor']),
  percentBps: json['percentBps'] as int,
  status: BudgetStatus.values.byName(json['status'] as String),
);

BudgetPeriod _period(Map<String, dynamic> json) {
  final start = json['fiscalMonthStartDay'] as int;
  if (start < 1 || start > 28) throw const FormatException();
  final timezone = json['timezone'] as String;
  if (timezone.isEmpty) throw const FormatException();
  return BudgetPeriod(
    from: _date(json['from']),
    to: _date(json['to']),
    timezone: timezone,
    fiscalMonthStartDay: start,
  );
}

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
