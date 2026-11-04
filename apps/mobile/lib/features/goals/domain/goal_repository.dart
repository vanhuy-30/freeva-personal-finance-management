import 'package:dartz/dartz.dart';

import '../../auth/domain/auth_repository.dart';
import 'goal.dart';

abstract class GoalRepository {
  Future<Either<AuthFailure, List<Goal>>> list({bool includeArchived = false});
  Future<Either<AuthFailure, Goal>> find(String id);
  Future<Either<AuthFailure, Goal>> create(GoalDraft draft);
  Future<Either<AuthFailure, Goal>> update(
    Goal goal, {
    String? kind,
    String? name,
    BigInt? targetMinor,
    String? targetDate,
    bool clearTargetDate = false,
    String? icon,
    String? colorToken,
  });
  Future<Either<AuthFailure, Unit>> archive(Goal goal);
  Future<Either<AuthFailure, Goal>> contribute(Goal goal, GoalMove move);
  Future<Either<AuthFailure, Goal>> withdraw(Goal goal, GoalMove move);
  Future<Either<AuthFailure, Goal>> adjust(Goal goal, BigInt currentMinor);
  Future<Either<AuthFailure, List<GoalEntry>>> entries(String id);
  Future<Either<AuthFailure, List<GoalPreset>>> presets();
}
