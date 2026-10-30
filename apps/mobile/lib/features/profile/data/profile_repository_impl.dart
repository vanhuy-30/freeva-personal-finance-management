import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/data/authorized_api.dart';
import '../../auth/domain/auth_repository.dart';
import '../../onboarding/domain/onboarding_answers.dart';
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
      displayName: _name(json['displayName']),
      goals: [
        if (json['goals'] case final List<dynamic> goals)
          for (final goal in goals)
            if (goal is String) goal,
      ],
      habit: _text(json['trackingHabit']),
      cadence: _text(json['reviewCadence']),
      budgetMinor: _minor(json['onboardingBudgetMinor']),
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
  Future<Either<AuthFailure, Unit>> saveOnboarding(OnboardingAnswers answers) =>
      _request(
        'PATCH',
        'profile/onboarding',
        (_) => unit,
        body: answers.toJson(),
      );
  @override
  Future<Either<AuthFailure, Profile>> save(Profile profile) => _request(
    'PUT',
    'profile',
    _profile,
    body: {
      'displayName': profile.displayName,
      'locale': profile.locale,
      'defaultCurrencyCode': profile.currency,
      'timezone': profile.timezone,
      'fiscalMonthStartDay': profile.fiscalDay,
      'version': profile.version,
    },
  );
}

String? _name(Object? value) {
  final name = value is String ? value.trim() : '';
  return name.isEmpty ? null : name;
}

String? _text(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

BigInt? _minor(Object? value) {
  final minor = value is String ? BigInt.tryParse(value) : null;
  return minor != null && minor > BigInt.zero ? minor : null;
}
