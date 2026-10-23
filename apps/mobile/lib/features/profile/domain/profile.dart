class Profile {
  const Profile({
    required this.locale,
    required this.currency,
    required this.timezone,
    required this.fiscalDay,
    required this.version,
    this.displayName,
  });

  /// Greeting name; null until the user sets one (Hồ sơ).
  final String? displayName;
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
