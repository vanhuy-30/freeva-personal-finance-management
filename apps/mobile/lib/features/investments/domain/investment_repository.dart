import 'package:dartz/dartz.dart';

import '../../auth/domain/auth_repository.dart';
import '../../net_worth/domain/net_worth_history.dart';
import 'investment.dart';

/// One bucket of the value history: value per currency on [asOf].
typedef InvestmentBucket = ({String asOf, Map<String, BigInt> valueByCurrency});

abstract class InvestmentRepository {
  Future<Either<AuthFailure, List<Investment>>> list();

  Future<Either<AuthFailure, InvestmentSummary>> summary();

  Future<Either<AuthFailure, List<InvestmentTrade>>> trades(String id);

  /// Sells part or all of a position; returns it after the sale.
  Future<Either<AuthFailure, Investment>> sell(String id, SellDraft draft);

  /// Renames, changes the note or (deposits) the maturity date.
  Future<Either<AuthFailure, Investment>> update(
    Investment investment, {
    required String name,
    required String? note,
    required String? maturityDate,
  });

  /// Changes one buy; the server replays the position and the wallet leg.
  Future<Either<AuthFailure, Investment>> updateTrade(
    Investment investment,
    String tradeId,
    TradeEdit edit,
  );

  /// Deletes one buy; ok also when it was the last one (the position goes).
  Future<Either<AuthFailure, Unit>> deleteTrade(
    Investment investment,
    String tradeId,
  );

  /// Records a manual price; returns the position.
  Future<Either<AuthFailure, Investment>> addPrice(
    String id, {
    required String clientId,
    required BigInt priceMinor,
    required DateTime quotedAt,
  });

  /// Opens a position with its first buy; a repeated name adds the buy to
  /// the existing position and returns that one.
  Future<Either<AuthFailure, Investment>> create(InvestmentDraft draft);

  /// Per-currency value at each bucket of [window], oldest first.
  Future<Either<AuthFailure, List<InvestmentBucket>>> history(
    NetWorthWindow window,
  );
}
