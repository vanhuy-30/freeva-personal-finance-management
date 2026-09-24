import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/data/authorized_api.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/profile.dart';
import '../domain/profile_repository.dart';

@LazySingleton(as: ProfileRepository)
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._api);
  final AuthorizedApi _api;
  Profile _profile(Map<String, dynamic> json) {
    final value = Profile(
      locale: json['locale'] as String,
      currency: json['defaultCurrencyCode'] as String,
      timezone: json['timezone'] as String,
      fiscalDay: json['fiscalMonthStartDay'] as int,
      version: json['version'] as int,
    );
    if (!['vi', 'en'].contains(value.locale) ||
        !RegExp(r'^[A-Z]{3}$').hasMatch(value.currency) ||
        value.timezone.isEmpty ||
        value.fiscalDay < 1 ||
        value.fiscalDay > 28 ||
        value.version < 1) {
      throw const FormatException();
    }
    return value;
  }

  Future<Either<AuthFailure, T>> _request<T>(
    String method,
    String path,
    T Function(Map<String, dynamic>) parse, {
    Map<String, dynamic>? body,
  }) async {
    final result = await _api.request(method, path, body: body);
    return result.fold(left, (json) {
      try {
        return right(parse(json));
      } catch (_) {
        return left(const AuthFailure(AuthError.unavailable));
      }
    });
  }

  @override
  Future<Either<AuthFailure, Profile>> load() =>
      _request('GET', 'profile', _profile);
  @override
  Future<Either<AuthFailure, ProfileOptions>> options() => _request(
    'GET',
    'profile/options',
    (json) => ProfileOptions(
      currencies: (json['currencies'] as List)
          .map((c) => c['code'] as String)
          .toSet()
          .toList(),
      timezones: (json['timezones'] as List).cast<String>().toSet().toList(),
    ),
  );
  @override
  Future<Either<AuthFailure, Profile>> save(Profile profile) => _request(
    'PUT',
    'profile',
    _profile,
    body: {
      'locale': profile.locale,
      'defaultCurrencyCode': profile.currency,
      'timezone': profile.timezone,
      'fiscalMonthStartDay': profile.fiscalDay,
      'version': profile.version,
    },
  );
}
