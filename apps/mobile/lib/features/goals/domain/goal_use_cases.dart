import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/domain/auth_repository.dart';
import 'goal.dart';
import 'goal_forecast.dart';
import 'goal_repository.dart';
import '../../server_config/domain/app_limits.dart';

abstract class GoalUseCases {
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
  Future<Either<AuthFailure, GoalPreview>> preview({
    required String currency,
    required BigInt targetMinor,
    required String targetDate,
  });

  /// When the goal is likely reached at the recent pace; null when off.
  Future<Either<AuthFailure, GoalForecast?>> forecast(String id);
}

@LazySingleton(as: GoalUseCases)
class DefaultGoalUseCases implements GoalUseCases {
  DefaultGoalUseCases(this._repository, this._limits);

  /// Server limits (MOB-P5-001).
  final AppLimitsSource _limits;
  final GoalRepository _repository;

  static final _day = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static const _invalid = AuthFailure(AuthError.invalidInput);

  bool _name(String name) =>
      name.trim().isNotEmpty &&
      name.trim().length <= _limits.requireLimits.goalNameMaxLength;
  bool _date(String? day) => day == null || _day.hasMatch(day);

  @override
  Future<Either<AuthFailure, List<Goal>>> list({
    bool includeArchived = false,
  }) => _repository.list(includeArchived: includeArchived);

  @override
  Future<Either<AuthFailure, Goal>> find(String id) => _repository.find(id);

  @override
  Future<Either<AuthFailure, Goal>> create(GoalDraft draft) {
    if (!goalKinds.contains(draft.kind) ||
        !_name(draft.name) ||
        draft.targetMinor <= BigInt.zero ||
        (draft.currentMinor ?? BigInt.zero) < BigInt.zero ||
        !_date(draft.targetDate)) {
      return Future.value(left(_invalid));
    }
    return _repository.create(draft);
  }

  @override
  Future<Either<AuthFailure, Goal>> update(
    Goal goal, {
    String? kind,
    String? name,
    BigInt? targetMinor,
    String? targetDate,
    bool clearTargetDate = false,
    String? icon,
    String? colorToken,
  }) {
    if ((kind != null && !goalKinds.contains(kind)) ||
        (name != null && !_name(name)) ||
        (targetMinor != null && targetMinor <= BigInt.zero) ||
        !_date(targetDate)) {
      return Future.value(left(_invalid));
    }
    return _repository.update(
      goal,
      kind: kind,
      name: name?.trim(),
      targetMinor: targetMinor,
      targetDate: targetDate,
      clearTargetDate: clearTargetDate,
      icon: icon,
      colorToken: colorToken,
    );
  }

  @override
  Future<Either<AuthFailure, Unit>> archive(Goal goal) =>
      _repository.archive(goal);

  Either<AuthFailure, Unit> _move(GoalMove move, {BigInt? max}) {
    if (move.amountMinor <= BigInt.zero || !_day.hasMatch(move.occurredOn)) {
      return left(_invalid);
    }
    if (max != null && move.amountMinor > max) return left(_invalid);
    return right(unit);
  }

  @override
  Future<Either<AuthFailure, Goal>> contribute(Goal goal, GoalMove move) {
    final check = _move(move);
    return check.fold(
      (e) => Future.value(left(e)),
      (_) => _repository.contribute(goal, move),
    );
  }

  @override
  Future<Either<AuthFailure, Goal>> withdraw(Goal goal, GoalMove move) {
    final check = _move(move, max: goal.currentMinor);
    return check.fold(
      (e) => Future.value(left(e)),
      (_) => _repository.withdraw(goal, move),
    );
  }

  @override
  Future<Either<AuthFailure, Goal>> adjust(Goal goal, BigInt currentMinor) {
    if (currentMinor < BigInt.zero) return Future.value(left(_invalid));
    return _repository.adjust(goal, currentMinor);
  }

  @override
  Future<Either<AuthFailure, List<GoalEntry>>> entries(String id) =>
      _repository.entries(id);

  @override
  Future<Either<AuthFailure, List<GoalPreset>>> presets() =>
      _repository.presets();

  @override
  Future<Either<AuthFailure, GoalPreview>> preview({
    required String currency,
    required BigInt targetMinor,
    required String targetDate,
  }) {
    if (targetMinor <= BigInt.zero || !_day.hasMatch(targetDate)) {
      return Future.value(left(_invalid));
    }
    return _repository.preview(
      currency: currency,
      targetMinor: targetMinor,
      targetDate: targetDate,
    );
  }

  @override
  Future<Either<AuthFailure, GoalForecast?>> forecast(String id) =>
      _repository.forecast(id);
}
