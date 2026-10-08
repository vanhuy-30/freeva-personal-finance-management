import 'package:dartz/dartz.dart';

import '../../auth/domain/auth_repository.dart';
import 'profile.dart';

abstract class ProfileRepository {
  Future<Either<AuthFailure, Profile>> load();
  Future<Either<AuthFailure, ProfileOptions>> options();
  Future<Either<AuthFailure, Profile>> save(Profile profile);
}
