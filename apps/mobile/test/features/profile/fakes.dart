import 'package:dartz/dartz.dart';
import 'package:mobile/features/auth/data/authorized_api.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/onboarding/domain/onboarding_answers.dart';
import 'package:mobile/features/profile/domain/account_export_use_case.dart';
import 'package:mobile/features/profile/domain/account_file_sharer.dart';
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
  final List<OnboardingAnswers> onboarding = [];
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
  final List<String?> displayCurrencies = [];
  @override
  Future<Either<AuthFailure, Unit>> saveDisplayCurrency(String? code) async {
    if (failure != null) return left(failure!);
    displayCurrencies.add(code);
    return right(unit);
  }

  @override
  Future<Either<AuthFailure, Unit>> saveOnboarding(
    OnboardingAnswers answers,
  ) async {
    if (failure != null) return left(failure!);
    onboarding.add(answers);
    return right(unit);
  }

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
      displayName: profile.displayName,
    );
    return right(value);
  }
}

class Transport implements AuthorizedApi {
  Map<String, dynamic> response = {};
  Map<String, dynamic>? body;
  String? method;
  String? path;
  AuthFailure? failure;
  @override
  Future<Either<AuthFailure, Map<String, dynamic>>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    this.body = body;
    this.method = method;
    this.path = path;
    return failure == null ? right(response) : left(failure!);
  }
}

class FakeSharer implements AccountFileSharer {
  String? name;
  String? content;
  bool result = true;
  bool fail = false;
  @override
  Future<bool> share(String fileName, String content) async {
    if (fail) throw StateError('share');
    name = fileName;
    this.content = content;
    return result;
  }
}

AccountExportUseCase exportCase(AuthRepository auth, [FakeSharer? sharer]) =>
    AccountExportUseCase(auth, sharer ?? FakeSharer());
