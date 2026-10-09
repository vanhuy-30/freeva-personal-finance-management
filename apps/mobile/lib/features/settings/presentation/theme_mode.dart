import 'package:flutter/material.dart';

import '../domain/app_preferences.dart';

ThemeMode themeModeFor(AppThemePreference preference) => switch (preference) {
  AppThemePreference.light => ThemeMode.light,
  AppThemePreference.dark => ThemeMode.dark,
  AppThemePreference.system => ThemeMode.system,
};
