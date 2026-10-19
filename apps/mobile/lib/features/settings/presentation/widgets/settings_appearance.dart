import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/app_preferences.dart';
import '../viewmodels/settings_view_model.dart';

class SettingsAppearance extends StatelessWidget {
  const SettingsAppearance({required this.model, super.key});

  final SettingsViewModel model;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          s.settingsAppearance,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        RadioGroup<AppThemePreference>(
          groupValue: model.theme,
          onChanged: (value) {
            if (value != null) model.setTheme(value);
          },
          child: Column(
            children: [
              RadioListTile<AppThemePreference>(
                title: Text(s.settingsThemeLight),
                value: AppThemePreference.light,
              ),
              RadioListTile<AppThemePreference>(
                title: Text(s.settingsThemeDark),
                value: AppThemePreference.dark,
              ),
              RadioListTile<AppThemePreference>(
                title: Text(s.settingsThemeSystem),
                value: AppThemePreference.system,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
