import 'package:dartz/dartz.dart';

import '../../auth/domain/auth_repository.dart';
import 'insight.dart';

/// Rule-based insights about the running month, worked out on Freeva's
/// server from the user's own book. Empty when the `insights` flag or Gợi ý
/// tự động is off.
abstract class InsightsRepository {
  Future<Either<AuthFailure, InsightList>> list();
}
