import 'package:dartz/dartz.dart';
import 'package:mobile/features/auth/data/authorized_api.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/profile/domain/profile.dart';
import 'package:mobile/features/profile/domain/profile_repository.dart';

const initial = Profile(
  locale: 'vi',
  currency: 'VND',
  timezone: 'Asia/Ho_Chi_Minh',
  fiscalDay: 1,
  version: 1,
);

class MemoryProfiles implements ProfileRepository {
  Profile value = initial;
  AuthFailure? failure;
  Future<void>? pending;
  int saves = 0;
  @override
  Future<Either<AuthFailure, Profile>> load() async {
    if (pending != null) await pending;
    return failure == null ? right(value) : left(failure!);
  }

  @override
  Future<Either<AuthFailure, ProfileOptions>> options() async => right(
    ProfileOptions(
      currencies: ['VND', 'USD'],
      timezones: ['Asia/Ho_Chi_Minh', 'America/New_York', 'UTC'],
    ),
  );
  @override
  Future<Either<AuthFailure, Profile>> save(Profile profile) async {
    saves++;
    if (pending != null) await pending;
    if (failure != null) return left(failure!);
    value = Profile(
      locale: profile.locale,
      currency: profile.currency,
      timezone: profile.timezone,
      fiscalDay: profile.fiscalDay,
      version: profile.version + 1,
    );
    return right(value);
  }
}

class Transport implements AuthorizedApi {
  Map<String, dynamic> response = {};
  Map<String, dynamic>? body;
  AuthFailure? failure;
  @override
  Future<Either<AuthFailure, Map<String, dynamic>>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    this.body = body;
    return failure == null ? right(response) : left(failure!);
  }
}
