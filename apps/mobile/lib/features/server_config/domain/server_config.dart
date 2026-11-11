import '../../../core/money/currency_catalog.dart';

/// MOB-P5-E08: feature flags and product config served by `GET /api/v1/app-config`
/// (BE-P5-E08). The server is the source of truth; typed getters return null when a key
/// is missing or has another type, so a caller never guesses a number.
class ServerConfig {
  const ServerConfig({
    required this.version,
    required this.flags,
    required this.values,
    this.currencies = const [],
  });

  /// Goes up on every staff edit; a new number means the cached copy is stale.
  final int version;
  final Map<String, bool> flags;
  final Map<String, Object> values;

  /// Currency catalog (`/profile/options`), loaded with the signed-in config;
  /// empty for the public config.
  final List<CurrencyInfo> currencies;

  bool flag(String key) => flags[key] ?? false;

  int? integer(String key) {
    final value = values[key];
    return value is int ? value : null;
  }

  List<int>? integers(String key) {
    final value = values[key];
    return value is List<int> ? value : null;
  }

  /// Money lists come as minor-unit strings, never as doubles.
  List<BigInt>? moneyMinor(String key) {
    final value = values[key];
    if (value is! List<String>) return null;
    final parsed = value.map(BigInt.tryParse).toList();
    return parsed.contains(null)
        ? null
        : List.unmodifiable(parsed.cast<BigInt>());
  }

  String? text(String key) {
    final value = values[key];
    return value is String ? value : null;
  }

  List<String>? texts(String key) {
    final value = values[key];
    return value is List<String> ? value : null;
  }

  /// Parses the API body (also the cached copy). Throws [FormatException] on a bad shape.
  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    final flags = json['flags'];
    final config = json['config'];
    if (version is! int || flags is! Map || config is! Map) {
      throw const FormatException('app-config shape');
    }
    final values = <String, Object>{};
    config.forEach((key, value) {
      final parsed = _value(value);
      if (key is String && parsed != null) values[key] = parsed;
    });
    return ServerConfig(
      version: version,
      flags: Map.unmodifiable({
        for (final entry in flags.entries)
          if (entry.key is String && entry.value is bool)
            entry.key as String: entry.value as bool,
      }),
      values: Map.unmodifiable(values),
      currencies: List.unmodifiable([
        for (final raw in (json['currencies'] as List? ?? const []))
          if (raw is Map) CurrencyInfo.fromJson(Map<String, dynamic>.from(raw)),
      ]),
    );
  }

  Map<String, Object> toJson() => {
    'version': version,
    'flags': flags,
    'config': values,
    'currencies': [for (final c in currencies) c.toJson()],
  };

  /// int, String, list of ints or list of strings; anything else is dropped.
  static Object? _value(Object? value) {
    if (value is int || value is String) return value;
    if (value is List) {
      if (value.every((item) => item is int)) {
        return List<int>.unmodifiable(value.cast<int>());
      }
      if (value.every((item) => item is String)) {
        return List<String>.unmodifiable(value.cast<String>());
      }
    }
    return null;
  }
}

/// Flag keys known to this app build (registry: backend `app-config-registry.ts`).
abstract final class FeatureFlags {
  static const categorySuggest = 'category_suggest';
  static const insights = 'insights';
  static const forecast = 'forecast';
  static const googleSignIn = 'google_sign_in';
  static const appleSignIn = 'apple_sign_in';
  static const profileEdit = 'profile_edit';
}
