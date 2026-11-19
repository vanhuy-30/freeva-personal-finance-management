import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/domain/auth_repository.dart';
import '../../onboarding/domain/onboarding_answers.dart';
import 'declared_income.dart';
import 'profile.dart';
import 'profile_repository.dart';
import '../../server_config/domain/app_limits.dart';

@injectable
class ProfileUseCases {
  ProfileUseCases(this._repository, this._limits);

  /// Server limits (MOB-P5-001).
  final AppLimitsSource _limits;
  final ProfileRepository _repository;
  Future<Either<AuthFailure, Profile>> load() => _repository.load();
  Future<Either<AuthFailure, ProfileOptions>> options() =>
      _repository.options();
  Future<Either<AuthFailure, Unit>> saveOnboarding(OnboardingAnswers answers) {
    if ((answers.goals?.length ?? 0) >
            _limits.requireLimits.onboardingMaxGoals ||
        (answers.goals?.toSet().length ?? 0) != (answers.goals?.length ?? 0)) {
      return Future.value(left(const AuthFailure(AuthError.invalidInput)));
    }
    if (!_validIncome(answers.declaredIncome)) {
      return Future.value(left(const AuthFailure(AuthError.invalidInput)));
    }
    if (answers.isEmpty) return Future.value(right(unit));
    return _repository.saveOnboarding(answers);
  }

  Future<Either<AuthFailure, Unit>> saveDeclaredIncome(DeclaredIncome? income) {
    if (!_validIncome(income)) {
      return Future.value(left(const AuthFailure(AuthError.invalidInput)));
    }
    return _repository.saveDeclaredIncome(income);
  }

  /// Null (not shared) is valid; a band needs min ≥ 0, max ≥ min, and a
  /// positive floor when it is open-ended.
  static bool _validIncome(DeclaredIncome? income) {
    if (income == null) return true;
    final max = income.maxMinor;
    if (income.minMinor < BigInt.zero) return false;
    return max == null ? income.minMinor > BigInt.zero : max >= income.minMinor;
  }

  Future<Either<AuthFailure, Unit>> saveDisplayCurrency(
    String? code,
    ProfileOptions options,
  ) {
    if (code != null && !options.currencies.contains(code)) {
      return Future.value(left(const AuthFailure(AuthError.invalidInput)));
    }
    return _repository.saveDisplayCurrency(code);
  }

  Future<Either<AuthFailure, Profile>> save(
    Profile profile,
    ProfileOptions options,
  ) {
    if (!['vi', 'en'].contains(profile.locale) ||
        !options.currencies.contains(profile.currency) ||
        !options.timezones.contains(profile.timezone) ||
        profile.fiscalDay < 1 ||
        profile.fiscalDay > _limits.requireLimits.periodStartDayMax ||
        profile.version < 1) {
      return Future.value(left(const AuthFailure(AuthError.invalidInput)));
    }
    return _repository.save(profile);
  }
}
