import 'package:dartz/dartz.dart';

import '../../../core/money/display_converted.dart';
import '../../auth/domain/auth_repository.dart';
import 'fx_rate.dart';

abstract class FxRateRepository {
  Future<Either<AuthFailure, List<FxRate>>> list();

  /// Sets the rate for one direction. [rate] is already validated decimal text.
  Future<Either<AuthFailure, FxRate>> put(String from, String to, String rate);
  Future<Either<AuthFailure, Unit>> remove(String from, String to);

  /// Balance of wallet [id] in the profile currency; null when the server
  /// has no exact conversion (same currency, no rate, fractional result).
  Future<Either<AuthFailure, DisplayConverted?>> walletConverted(String id);

  /// Amount of the transaction leg [legId] in the profile currency.
  Future<Either<AuthFailure, DisplayConverted?>> transactionConverted(
    String legId,
  );
}
