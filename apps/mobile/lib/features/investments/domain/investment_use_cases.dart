import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../core/money/quantity.dart';
import '../../auth/domain/auth_repository.dart';
import '../../net_worth/domain/net_worth_history.dart';
import 'investment.dart';
import 'investment_repository.dart';

abstract class InvestmentUseCases {
  Future<Either<AuthFailure, List<Investment>>> list();

  Future<Either<AuthFailure, InvestmentSummary>> summary();

  Future<Either<AuthFailure, List<InvestmentTrade>>> trades(String id);

  /// Sells [draft.quantity] of [investment]; refuses more than is held.
  Future<Either<AuthFailure, Investment>> sell(
    Investment investment,
    SellDraft draft,
  );

  Future<Either<AuthFailure, Investment>> update(
    Investment investment, {
    required String name,
    required String? note,
    required String? maturityDate,
  });

  Future<Either<AuthFailure, Unit>> deleteTrade(
    Investment investment,
    String tradeId,
  );

  /// Manual price of one unit (zero is allowed: it means worthless).
  Future<Either<AuthFailure, Investment>> addPrice(
    Investment investment, {
    required String clientId,
    required BigInt priceMinor,
    required DateTime quotedAt,
  });

  /// Refuses an unusable draft before the API.
  Future<Either<AuthFailure, Investment>> create(InvestmentDraft draft);

  /// Value line of [currency] over [window]; buckets without that currency
  /// count as zero.
  Future<Either<AuthFailure, List<InvestmentValuePoint>>> valueLine(
    NetWorthWindow window, {
    required String currency,
  });
}

@LazySingleton(as: InvestmentUseCases)
class DefaultInvestmentUseCases implements InvestmentUseCases {
  DefaultInvestmentUseCases(this._repository);

  final InvestmentRepository _repository;

  static final _currency = RegExp(r'^[A-Z]{3}$');
  static final _day = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static const _invalid = AuthFailure(AuthError.invalidInput);

  @override
  Future<Either<AuthFailure, List<InvestmentTrade>>> trades(String id) =>
      _repository.trades(id);

  @override
  Future<Either<AuthFailure, Investment>> sell(
    Investment investment,
    SellDraft draft,
  ) {
    final held = parseQuantityApi(investment.quantity);
    if (held == null ||
        draft.quantity <= BigInt.zero ||
        draft.quantity > held ||
        !(draft.amountMinor != null
            ? draft.amountMinor! > BigInt.zero
            : (draft.priceMinor ?? BigInt.zero) > BigInt.zero) ||
        !_day.hasMatch(draft.tradedOn)) {
      return Future.value(left(_invalid));
    }
    return _repository.sell(investment.id, draft);
  }

  @override
  Future<Either<AuthFailure, Investment>> update(
    Investment investment, {
    required String name,
    required String? note,
    required String? maturityDate,
  }) {
    final text = name.trim();
    final day = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (text.isEmpty ||
        text.length > 80 ||
        (note?.trim().length ?? 0) > 500 ||
        (maturityDate != null &&
            (investment.kind != InvestmentKind.savingsDeposit ||
                !day.hasMatch(maturityDate) ||
                maturityDate.compareTo(investment.startDate ?? '') <= 0))) {
      return Future.value(left(_invalid));
    }
    return _repository.update(
      investment,
      name: text,
      note: note?.trim().isEmpty ?? true ? null : note!.trim(),
      maturityDate: maturityDate,
    );
  }

  @override
  Future<Either<AuthFailure, Unit>> deleteTrade(
    Investment investment,
    String tradeId,
  ) => _repository.deleteTrade(investment, tradeId);

  @override
  Future<Either<AuthFailure, Investment>> addPrice(
    Investment investment, {
    required String clientId,
    required BigInt priceMinor,
    required DateTime quotedAt,
  }) {
    if (priceMinor.isNegative ||
        investment.kind == InvestmentKind.savingsDeposit) {
      return Future.value(left(_invalid));
    }
    return _repository.addPrice(
      investment.id,
      clientId: clientId,
      priceMinor: priceMinor,
      quotedAt: quotedAt,
    );
  }

  @override
  Future<Either<AuthFailure, Investment>> create(InvestmentDraft draft) {
    final name = draft.name.trim();
    final deposit = draft.kind == InvestmentKind.savingsDeposit;
    bool positive(BigInt? v) => v != null && v > BigInt.zero;
    final priced = draft.kind.singleLot
        ? positive(draft.amountMinor)
        : positive(draft.priceMinor) || positive(draft.amountMinor);
    final depositOk =
        !deposit ||
        (draft.interestRateBps != null &&
            draft.interestRateBps! >= 0 &&
            draft.startDate != null &&
            _day.hasMatch(draft.startDate!) &&
            draft.maturityDate != null &&
            _day.hasMatch(draft.maturityDate!) &&
            draft.maturityDate!.compareTo(draft.startDate!) > 0);
    if (name.isEmpty ||
        name.length > 80 ||
        !_currency.hasMatch(draft.currencyCode) ||
        draft.quantity <= BigInt.zero ||
        !priced ||
        !depositOk ||
        !_day.hasMatch(draft.tradedOn) ||
        (draft.note?.trim().length ?? 0) > 500) {
      return Future.value(left(_invalid));
    }
    return _repository.create(draft);
  }

  @override
  Future<Either<AuthFailure, List<Investment>>> list() => _repository.list();

  @override
  Future<Either<AuthFailure, InvestmentSummary>> summary() =>
      _repository.summary();

  @override
  Future<Either<AuthFailure, List<InvestmentValuePoint>>> valueLine(
    NetWorthWindow window, {
    required String currency,
  }) async {
    if (!_currency.hasMatch(currency)) {
      return left(const AuthFailure(AuthError.invalidInput));
    }
    final result = await _repository.history(window);
    return result.map(
      (buckets) => List.unmodifiable([
        for (final b in buckets)
          InvestmentValuePoint(
            asOf: b.asOf,
            valueMinor: b.valueByCurrency[currency] ?? BigInt.zero,
          ),
      ]),
    );
  }
}
