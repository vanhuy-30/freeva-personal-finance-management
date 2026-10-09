import 'dart:convert';

import 'package:dartz/dartz.dart';

import 'app_preferences.dart';

abstract class SettingsRepository {
  Future<Either<SettingsFailure, AppPreferences>> load();
  Future<Either<SettingsFailure, AppPreferences>> save(AppPreferences value);
}

AppPreferences decodePreferences(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is! Map) throw const FormatException('preferences');
  final json = Map<String, dynamic>.from(decoded);
  final themeName = json['theme'];
  final completed = json['onboardingCompleted'];
  final theme = AppThemePreference.values.where(
    (item) => item.name == themeName,
  );
  if (theme.length != 1 || completed is! bool || json.length != 2) {
    throw const FormatException('preferences');
  }
  return AppPreferences(theme: theme.single, onboardingCompleted: completed);
}

String encodePreferences(AppPreferences value) => jsonEncode({
  'theme': value.theme.name,
  'onboardingCompleted': value.onboardingCompleted,
});
