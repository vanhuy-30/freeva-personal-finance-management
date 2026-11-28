import 'declared_income.dart';

class Profile {
  const Profile({
    required this.locale,
    required this.currency,
    required this.timezone,
    required this.fiscalDay,
    required this.version,
    this.displayName,
    this.goals = const [],
    this.displayCurrency,
    this.declaredIncome,
    this.autoSuggestEnabled = true,
    this.emailVerified,
  });

  /// Greeting name; null until the user sets one (Hồ sơ).
  final String? displayName;

  /// Goals picked at first run; empty when skipped or when the
  /// server does not send them.
  final List<String> goals;

  /// Currency the Overview converts into, saved on the account. Null means
  /// [currency]. Not part of the PUT body; see `saveDisplayCurrency`.
  final String? displayCurrency;

  /// Income band the user stated, in [currency]; null when not shared. Its
  /// midpoint feeds the budget suggestion and a goal's share of income.
  final DeclaredIncome? declaredIncome;

  /// Gợi ý tự động (category suggestions, insights, forecast). Read-only here:
  /// saved with its own call, never part of the PUT body. Default on.
  final bool autoSuggestEnabled;

  /// Whether the sign-in email was confirmed. Null when the server does not
  /// say (an older API): the screen then shows the plain "Email" label.
  /// Read-only: it changes only through the link in the email.
  final bool? emailVerified;
  final String locale;
  final String currency;
  final String timezone;
  final int fiscalDay;
  final int version;
  static const _keep = Object();

  Profile copyWith({
    String? locale,
    String? currency,
    String? timezone,
    int? fiscalDay,
    Object? displayName = _keep,
  }) => Profile(
    locale: locale ?? this.locale,
    currency: currency ?? this.currency,
    timezone: timezone ?? this.timezone,
    fiscalDay: fiscalDay ?? this.fiscalDay,
    version: version,
    displayName: identical(displayName, _keep)
        ? this.displayName
        : displayName as String?,
    goals: goals,
    displayCurrency: displayCurrency,
    declaredIncome: declaredIncome,
    autoSuggestEnabled: autoSuggestEnabled,
    emailVerified: emailVerified,
  );

  /// Currency the Overview shows totals in: the saved choice, else [currency].
  String get overviewCurrency => displayCurrency ?? currency;

  Profile withDisplayCurrency(String? code) => Profile(
    locale: locale,
    currency: currency,
    timezone: timezone,
    fiscalDay: fiscalDay,
    version: version,
    displayName: displayName,
    goals: goals,
    displayCurrency: code,
    declaredIncome: declaredIncome,
    autoSuggestEnabled: autoSuggestEnabled,
    emailVerified: emailVerified,
  );

  Profile withDeclaredIncome(DeclaredIncome? income) => Profile(
    locale: locale,
    currency: currency,
    timezone: timezone,
    fiscalDay: fiscalDay,
    version: version,
    displayName: displayName,
    goals: goals,
    displayCurrency: displayCurrency,
    declaredIncome: income,
    autoSuggestEnabled: autoSuggestEnabled,
    emailVerified: emailVerified,
  );

  bool samePreferences(Profile other) =>
      locale == other.locale &&
      currency == other.currency &&
      timezone == other.timezone &&
      fiscalDay == other.fiscalDay &&
      displayName == other.displayName;
}

class ProfileOptions {
  ProfileOptions({
    required List<String> currencies,
    required List<String> timezones,
  }) : currencies = List.unmodifiable(currencies),
       timezones = List.unmodifiable(timezones);
  final List<String> currencies;
  final List<String> timezones;
}
