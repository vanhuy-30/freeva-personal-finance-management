import 'package:dartz/dartz.dart';

import '../../auth/domain/auth_repository.dart';
import '../../onboarding/domain/onboarding_answers.dart';
import 'profile.dart';

abstract class ProfileRepository {
  Future<Either<AuthFailure, Profile>> load();
  Future<Either<AuthFailure, ProfileOptions>> options();
  Future<Either<AuthFailure, Profile>> save(Profile profile);

  /// Saves the Overview display currency; null goes back to the default.
  Future<Either<AuthFailure, Unit>> saveDisplayCurrency(String? code);

  /// Stores first-run answers; only the parts that are set.
  Future<Either<AuthFailure, Unit>> saveOnboarding(OnboardingAnswers answers);
}
