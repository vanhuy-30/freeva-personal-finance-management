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
    this.monthlyIncomeMinor,
    this.autoSuggestEnabled = true,
  });

  /// Greeting name; null until the user sets one (Hồ sơ).
  final String? displayName;

  /// Goals picked at first run (at most 2); empty when skipped or when the
  /// server does not send them.
  final List<String> goals;

  /// Currency the Overview converts into, saved on the account. Null means
  /// [currency]. Not part of the PUT body; see `saveDisplayCurrency`.
  final String? displayCurrency;

  /// Monthly income the user stated, in minor units of [currency]; null when
  /// not given. Used for the first budget suggestion and to show a goal's
  /// monthly saving as a share of it.
  final BigInt? monthlyIncomeMinor;

  /// Gợi ý tự động (category suggestions, insights, forecast). Read-only here:
  /// saved with its own call, never part of the PUT body. Default on.
  final bool autoSuggestEnabled;
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
    monthlyIncomeMinor: monthlyIncomeMinor,
    autoSuggestEnabled: autoSuggestEnabled,
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
    monthlyIncomeMinor: monthlyIncomeMinor,
    autoSuggestEnabled: autoSuggestEnabled,
  );

  Profile withMonthlyIncome(BigInt? minor) => Profile(
    locale: locale,
    currency: currency,
    timezone: timezone,
    fiscalDay: fiscalDay,
    version: version,
    displayName: displayName,
    goals: goals,
    displayCurrency: displayCurrency,
    monthlyIncomeMinor: minor,
    autoSuggestEnabled: autoSuggestEnabled,
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
