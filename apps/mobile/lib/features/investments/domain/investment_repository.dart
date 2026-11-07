import 'package:dartz/dartz.dart';

import '../../auth/domain/auth_repository.dart';
import '../../net_worth/domain/net_worth_history.dart';
import 'investment.dart';

/// One bucket of the value history: value per currency on [asOf].
typedef InvestmentBucket = ({String asOf, Map<String, BigInt> valueByCurrency});

abstract class InvestmentRepository {
  Future<Either<AuthFailure, List<Investment>>> list();

  Future<Either<AuthFailure, InvestmentSummary>> summary();

  /// Per-currency value at each bucket of [window], oldest first.
  Future<Either<AuthFailure, List<InvestmentBucket>>> history(
    NetWorthWindow window,
  );
}
