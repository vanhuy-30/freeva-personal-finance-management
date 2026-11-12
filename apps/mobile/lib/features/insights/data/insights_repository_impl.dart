import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/data/authorized_api.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/insight.dart';
import '../domain/insights_repository.dart';

@LazySingleton(as: InsightsRepository)
class InsightsRepositoryImpl implements InsightsRepository {
  InsightsRepositoryImpl(this._api);

  final AuthorizedApi _api;

  @override
  Future<Either<AuthFailure, InsightList>> list() async {
    final result = await _api.request('GET', 'insights');
    return result.fold(left, (json) {
      try {
        return right(parse(json));
      } catch (_) {
        return left(const AuthFailure(AuthError.unavailable));
      }
    });
  }

  /// Parses the response. Kinds this app does not know are skipped, so the
  /// server can add new ones without breaking older apps.
  static InsightList parse(Map<String, dynamic> json) {
    final period = json['period'] as Map<String, dynamic>?;
    return InsightList(
      currencyCode: json['currencyCode'] as String?,
      period: period == null
          ? null
          : InsightPeriod(
              from: period['from'] as String,
              to: period['to'] as String,
              today: period['today'] as String,
            ),
      items: List.unmodifiable([
        for (final raw in json['items'] as List)
          if (_item(raw as Map<String, dynamic>) case final item?) item,
      ]),
    );
  }

  static Insight? _item(Map<String, dynamic> json) => switch (json['kind']) {
    'budget_risk' => BudgetRiskInsight(
      category: _category(json['category']),
      spentMinor: _money(json['spentMinor']),
      limitMinor: _money(json['limitMinor']),
      percent: _int(json['percent']),
      daysLeft: _int(json['daysLeft']),
    ),
    'outlier' => OutlierInsight(
      category: _category(json['category'])!,
      transactionId: json['transactionId'] as String,
      merchant: json['merchant'] as String?,
      occurredOn: json['occurredOn'] as String,
      amountMinor: _money(json['amountMinor']),
      usualMinor: _money(json['usualMinor']),
      times: _int(json['times']),
    ),
    'category_change' => CategoryChangeInsight(
      category: _category(json['category'])!,
      currentMinor: _money(json['currentMinor']),
      previousMinor: _money(json['previousMinor']),
      changePercent: (json['changePercent'] as num?)?.toInt(),
      up: _up(json['direction']),
    ),
    'spend_trend' => SpendTrendInsight(
      currentMinor: _money(json['currentMinor']),
      previousMinor: _money(json['previousMinor']),
      changePercent: (json['changePercent'] as num?)?.toInt(),
      up: _up(json['direction']),
      days: _int(json['days']),
    ),
    _ => null,
  };

  static InsightCategory? _category(Object? raw) {
    if (raw == null) return null;
    final json = raw as Map<String, dynamic>;
    return InsightCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      iconToken: json['iconToken'] as String?,
      colorToken: json['colorToken'] as String?,
    );
  }

  static BigInt _money(Object? value) => BigInt.parse(value as String);

  static int _int(Object? value) => (value as num).toInt();

  static bool _up(Object? value) => switch (value) {
    'up' => true,
    'down' => false,
    _ => throw FormatException('direction $value'),
  };
}
