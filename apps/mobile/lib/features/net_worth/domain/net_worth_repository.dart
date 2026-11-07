import 'package:dartz/dartz.dart';

import '../../auth/domain/auth_repository.dart';
import 'net_worth_history.dart';

/// Raw per-currency rows of one bucket.
typedef NetWorthRow = ({
  String currency,
  BigInt assetsMinor,
  BigInt liabilitiesMinor,
  BigInt netWorthMinor,
});

typedef NetWorthBucket = ({String asOf, List<NetWorthRow> items});

typedef InvestmentBucket = ({String asOf, Map<String, BigInt> valueByCurrency});

abstract class NetWorthRepository {
  Future<Either<AuthFailure, List<NetWorthBucket>>> history(
    NetWorthWindow window,
  );

  Future<Either<AuthFailure, List<InvestmentBucket>>> investmentHistory(
    NetWorthWindow window,
  );
}
