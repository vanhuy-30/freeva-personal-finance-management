import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../core/money/quantity.dart';
import '../../auth/data/authorized_api.dart';
import '../../auth/domain/auth_repository.dart';
import '../../net_worth/domain/net_worth_history.dart';
import '../domain/investment.dart';
import '../domain/investment_repository.dart';

@LazySingleton(as: InvestmentRepository)
class InvestmentRepositoryImpl implements InvestmentRepository {
  InvestmentRepositoryImpl(this._api);

  final AuthorizedApi _api;

  /// Money arrives as a string; a JSON number is rejected.
  static BigInt _money(Object? value) => BigInt.parse(value as String);

  static BigInt? _moneyOrNull(Object? value) =>
      value == null ? null : _money(value);

  /// Basis points arrive as a string too.
  static int? _bps(Object? value) =>
      value == null ? null : int.parse(value as String);

  static Investment parse(Map<String, dynamic> json) {
    final price = json['latestPrice'] as Map<String, dynamic>?;
    return Investment(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      kind: InvestmentKind.parse(json['kind'] as String),
      name: json['name'] as String,
      currencyCode: json['currencyCode'] as String,
      unit: json['unit'] as String,
      quantity: json['quantity'] as String,
      costBasisMinor: _money(json['costBasisMinor']),
      currentValueMinor: _money(json['currentValueMinor']),
      valuation: InvestmentValuation.values.byName(
        json['valuationBasis'] as String,
      ),
      version: json['version'] as int,
      averageCostMinor: _moneyOrNull(json['averageCostMinor']),
      unrealizedMinor: _moneyOrNull(json['unrealizedMinor']),
      unrealizedBps: _bps(json['unrealizedBps']),
      latestPriceMinor: price == null ? null : _money(price['priceMinor']),
      latestPriceAt: price == null
          ? null
          : DateTime.parse(price['quotedAt'] as String),
      interestRateBps: json['interestRateBps'] as int?,
      startDate: json['startDate'] as String?,
      maturityDate: json['maturityDate'] as String?,
      note: json['note'] as String?,
      archived: json['archivedAt'] != null,
    );
  }

  static InvestmentTrade parseTrade(Map<String, dynamic> json) =>
      InvestmentTrade(
        id: json['id'] as String,
        clientId: json['clientId'] as String,
        side: TradeSide.values.byName(json['side'] as String),
        quantity: parseQuantityApi(json['quantity'] as String)!,
        amountMinor: _money(json['amountMinor']),
        unitPriceMinor: _money(json['unitPriceMinor']),
        tradedOn: json['tradedOn'] as String,
        realizedMinor: _moneyOrNull(json['realizedMinor']),
        accountId: json['accountId'] as String?,
        note: json['note'] as String?,
        currentValueMinor: _moneyOrNull(json['currentValueMinor']),
        unrealizedMinor: _moneyOrNull(json['unrealizedMinor']),
        unrealizedBps: _bps(json['unrealizedBps']),
      );

  static InvestmentTotal _total(Map<String, dynamic> json) => InvestmentTotal(
    currencyCode: json['currencyCode'] as String,
    costBasisMinor: _money(json['costBasisMinor']),
    currentValueMinor: _money(json['currentValueMinor']),
    unrealizedMinor: _money(json['unrealizedMinor']),
    unrealizedBps: _bps(json['unrealizedBps']),
    unpricedCount: json['unpricedCount'] as int,
    kind: json['kind'] == null
        ? null
        : InvestmentKind.parse(json['kind'] as String),
    investmentCount: (json['investmentCount'] as int?) ?? 0,
    shareBps: _bps(json['shareBps']),
  );

  static InvestmentSummary parseSummary(
    Map<String, dynamic> json,
  ) => InvestmentSummary(
    totals: List.unmodifiable(
      (json['totals'] as List).map((e) => _total(e as Map<String, dynamic>)),
    ),
    byKind: List.unmodifiable(
      (json['byKind'] as List).map((e) => _total(e as Map<String, dynamic>)),
    ),
  );

  static List<InvestmentBucket> parseHistory(Map<String, dynamic> json) =>
      List.unmodifiable(
        (json['points'] as List).map((raw) {
          final p = raw as Map<String, dynamic>;
          return (
            asOf: p['asOf'] as String,
            valueByCurrency: {
              for (final item in p['items'] as List)
                (item as Map<String, dynamic>)['currency'] as String: _money(
                  item['valueMinor'],
                ),
            },
          );
        }),
      );

  Future<Either<AuthFailure, T>> _get<T>(
    String path,
    T Function(Map<String, dynamic>) parse, {
    String method = 'GET',
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
  Future<Either<AuthFailure, List<Investment>>> list() => _get(
    'investments',
    (json) => List.unmodifiable(
      (json['items'] as List).map((e) => parse(e as Map<String, dynamic>)),
    ),
  );

  @override
  Future<Either<AuthFailure, InvestmentSummary>> summary() =>
      _get('investments/summary', parseSummary);

  @override
  Future<Either<AuthFailure, List<InvestmentTrade>>> trades(String id) => _get(
    'investments/$id/trades',
    (json) => List.unmodifiable(
      (json['items'] as List).map((e) => parseTrade(e as Map<String, dynamic>)),
    ),
  );

  @override
  Future<Either<AuthFailure, Investment>> sell(String id, SellDraft draft) =>
      _get(
        'investments/$id/trades',
        parse,
        method: 'POST',
        body: {
          'clientId': draft.clientId,
          'side': 'sell',
          'quantity': quantityToApi(draft.quantity),
          if (draft.amountMinor != null)
            'amountMinor': draft.amountMinor.toString()
          else
            'priceMinor': draft.priceMinor.toString(),
          'accountId': draft.accountId,
          'tradedOn': draft.tradedOn,
        },
      );

  @override
  Future<Either<AuthFailure, Investment>> update(
    Investment investment, {
    required String name,
    required String? note,
    required String? maturityDate,
  }) => _get(
    'investments/${investment.id}',
    parse,
    method: 'PATCH',
    body: {
      'version': investment.version,
      'name': name,
      'note': note,
      if (investment.kind == InvestmentKind.savingsDeposit)
        'maturityDate': maturityDate,
    },
  );

  @override
  Future<Either<AuthFailure, Unit>> deleteTrade(
    Investment investment,
    String tradeId,
  ) async {
    final result = await _api.request(
      'DELETE',
      Uri(
        path: 'investments/${investment.id}/trades/$tradeId',
        queryParameters: {'version': '${investment.version}'},
      ).toString(),
    );
    return result.fold(left, (_) => right(unit));
  }

  @override
  Future<Either<AuthFailure, Investment>> addPrice(
    String id, {
    required String clientId,
    required BigInt priceMinor,
    required DateTime quotedAt,
  }) => _get(
    'investments/$id/prices',
    parse,
    method: 'POST',
    body: {
      'clientId': clientId,
      'priceMinor': priceMinor.toString(),
      'quotedAt': quotedAt.toUtc().toIso8601String(),
    },
  );

  @override
  Future<Either<AuthFailure, Investment>> create(InvestmentDraft draft) => _get(
    'investments',
    parse,
    method: 'POST',
    body: {
      'clientId': draft.clientId,
      'kind': draft.kind.apiValue,
      'name': draft.name.trim(),
      'currencyCode': draft.currencyCode,
      'unit': draft.unit,
      if (draft.interestRateBps != null)
        'interestRateBps': draft.interestRateBps,
      if (draft.startDate != null) 'startDate': draft.startDate,
      if (draft.maturityDate != null) 'maturityDate': draft.maturityDate,
      if (draft.note != null && draft.note!.trim().isNotEmpty)
        'note': draft.note!.trim(),
      'initialTrade': {
        'clientId': draft.tradeClientId,
        'quantity': quantityToApi(draft.quantity),
        if (draft.amountMinor != null)
          'amountMinor': draft.amountMinor.toString()
        else
          'priceMinor': draft.priceMinor.toString(),
        'accountId': draft.accountId,
        'tradedOn': draft.tradedOn,
      },
    },
  );

  @override
  Future<Either<AuthFailure, List<InvestmentBucket>>> history(
    NetWorthWindow window,
  ) => _get(
    Uri(
      path: 'reports/investments/history',
      queryParameters: {'window': window.value},
    ).toString(),
    parseHistory,
  );
}
