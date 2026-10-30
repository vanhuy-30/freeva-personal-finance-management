class Profile {
  const Profile({
    required this.locale,
    required this.currency,
    required this.timezone,
    required this.fiscalDay,
    required this.version,
    this.displayName,
    this.goals = const [],
    this.habit,
    this.cadence,
    this.budgetMinor,
    this.displayCurrency,
  });

  /// Greeting name; null until the user sets one (Hồ sơ).
  final String? displayName;

  /// Goals picked at first run (at most 2); empty when skipped or when the
  /// server does not send them.
  final List<String> goals;

  /// Other first-run answers; null until answered.
  final String? habit;
  final String? cadence;

  /// First monthly budget in minor units of the currency at that time. Kept
  /// as typed when the profile currency changes; null until typed.
  final BigInt? budgetMinor;

  /// Currency the Overview converts into, saved on the account. Null means
  /// [currency]. Not part of the PUT body; see `saveDisplayCurrency`.
  final String? displayCurrency;
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
    habit: habit,
    cadence: cadence,
    budgetMinor: budgetMinor,
    displayCurrency: displayCurrency,
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
    habit: habit,
    cadence: cadence,
    budgetMinor: budgetMinor,
    displayCurrency: code,
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
