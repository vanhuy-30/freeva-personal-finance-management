class Profile {
  const Profile({
    required this.locale,
    required this.currency,
    required this.timezone,
    required this.fiscalDay,
    required this.version,
  });
  final String locale;
  final String currency;
  final String timezone;
  final int fiscalDay;
  final int version;
  Profile copyWith({
    String? locale,
    String? currency,
    String? timezone,
    int? fiscalDay,
  }) => Profile(
    locale: locale ?? this.locale,
    currency: currency ?? this.currency,
    timezone: timezone ?? this.timezone,
    fiscalDay: fiscalDay ?? this.fiscalDay,
    version: version,
  );
  bool samePreferences(Profile other) =>
      locale == other.locale &&
      currency == other.currency &&
      timezone == other.timezone &&
      fiscalDay == other.fiscalDay;
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
