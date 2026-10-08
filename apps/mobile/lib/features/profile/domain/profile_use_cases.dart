import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/domain/auth_repository.dart';
import 'profile.dart';
import 'profile_repository.dart';

@injectable
class ProfileUseCases {
  ProfileUseCases(this._repository);
  final ProfileRepository _repository;
  Future<Either<AuthFailure, Profile>> load() => _repository.load();
  Future<Either<AuthFailure, ProfileOptions>> options() =>
      _repository.options();
  Future<Either<AuthFailure, Profile>> save(
    Profile profile,
    ProfileOptions options,
  ) {
    if (!['vi', 'en'].contains(profile.locale) ||
        !options.currencies.contains(profile.currency) ||
        !options.timezones.contains(profile.timezone) ||
        profile.fiscalDay < 1 ||
        profile.fiscalDay > 28 ||
        profile.version < 1) {
      return Future.value(left(const AuthFailure(AuthError.invalidInput)));
    }
    return _repository.save(profile);
  }
}
