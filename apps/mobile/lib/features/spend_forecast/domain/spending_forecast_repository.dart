import 'package:dartz/dartz.dart';

import '../../auth/domain/auth_repository.dart';
import 'spending_forecast.dart';

/// Month-end spending projected on Freeva's server from the user's own book.
/// The forecast is null when the `forecast` flag or Gợi ý tự động is off.
abstract class SpendingForecastRepository {
  Future<Either<AuthFailure, SpendingForecastResult>> load();
}
