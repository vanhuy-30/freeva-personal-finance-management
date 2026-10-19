import 'dart:convert';

import 'package:dartz/dartz.dart';

import 'app_preferences.dart';

abstract class SettingsRepository {
  Future<Either<SettingsFailure, AppPreferences>> load();
  Future<Either<SettingsFailure, AppPreferences>> save(AppPreferences value);
}

const _preferenceKeys = {
  'theme',
  'onboardingCompleted',
  'balancesHidden',
  'sessionAlertsEnabled',
  'notificationPrompted',
  'notificationsOptInTracked',
};

AppPreferences decodePreferences(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is! Map) throw const FormatException('preferences');
  final json = Map<String, dynamic>.from(decoded);
  if (json.keys.any((key) => !_preferenceKeys.contains(key))) {
    throw const FormatException('preferences');
  }
  final themeName = json['theme'];
  final completed = json['onboardingCompleted'];
  final theme = AppThemePreference.values.where(
    (item) => item.name == themeName,
  );
  if (theme.length != 1 || completed is! bool) {
    throw const FormatException('preferences');
  }
  return AppPreferences(
    theme: theme.single,
    onboardingCompleted: completed,
    balancesHidden: _preferenceFlag(json, 'balancesHidden', false),
    sessionAlertsEnabled: _preferenceFlag(json, 'sessionAlertsEnabled', true),
    notificationPrompted: _preferenceFlag(json, 'notificationPrompted', false),
    notificationsOptInTracked: _preferenceFlag(
      json,
      'notificationsOptInTracked',
      false,
    ),
  );
}

bool _preferenceFlag(Map<String, dynamic> json, String key, bool fallback) {
  if (!json.containsKey(key)) return fallback;
  final value = json[key];
  if (value is! bool) throw const FormatException('preferences');
  return value;
}

String encodePreferences(AppPreferences value) => jsonEncode({
  'theme': value.theme.name,
  'onboardingCompleted': value.onboardingCompleted,
  'balancesHidden': value.balancesHidden,
  'sessionAlertsEnabled': value.sessionAlertsEnabled,
  'notificationPrompted': value.notificationPrompted,
  'notificationsOptInTracked': value.notificationsOptInTracked,
});
