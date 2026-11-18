import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/settings_group.dart';
import '../../../../core/widgets/settings_row.dart';
import '../../../profile/presentation/viewmodels/profile_view_model.dart';
import '../../domain/app_preferences.dart';
import '../viewmodels/settings_view_model.dart';
import 'choice_sheet.dart';
import 'profile_actions.dart';
import 'theme_sheet.dart';

/// ỨNG DỤNG: how the app runs on this phone. Toggles and picks take effect at
/// once.
class AppSettingsGroup extends StatelessWidget {
  const AppSettingsGroup({
    required this.settings,
    required this.profile,
    super.key,
  });

  final SettingsViewModel settings;
  final ProfileViewModel profile;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final saved = profile.saved;
    final face = Theme.of(context).platform == TargetPlatform.iOS;
    const rowHeight = 54.0;
    final theme = switch (settings.theme) {
      AppThemePreference.light => s.meThemeLight,
      AppThemePreference.dark => s.meThemeDark,
      AppThemePreference.system => s.meThemeSystem,
    };
    return SettingsGroup(
      title: s.meGroupApp,
      children: [
        SettingsRow(
          minHeight: rowHeight,
          icon: LucideIcons.sun,
          title: s.meTheme,
          value: theme,
          onTap: () => showThemeSheet(context, settings),
        ),
        SettingsRow(
          minHeight: rowHeight,
          icon: LucideIcons.globe,
          title: s.meLanguage,
          value: saved == null
              ? null
              : saved.locale == 'en'
              ? s.profileEnglish
              : s.profileVietnamese,
          onTap: saved == null
              ? null
              : () async {
                  final picked = await showChoiceSheet<String>(
                    context,
                    title: s.meLanguage,
                    selected: saved.locale,
                    options: [
                      Choice('vi', s.profileVietnamese),
                      Choice('en', s.profileEnglish),
                    ],
                  );
                  if (picked == null || picked == saved.locale) return;
                  if (!context.mounted) return;
                  await applyProfile(
                    context,
                    profile,
                    (p) => p.copyWith(locale: picked),
                  );
                },
        ),
        SettingsRow(
          icon: LucideIcons.bell,
          title: s.meNotifications,
          minHeight: rowHeight,
          value: settings.sessionAlertsEnabled ? s.meNotifyOnCount(1) : null,
          onTap: () => context.push('/me/notifications'),
        ),
        SettingsRow(
          minHeight: rowHeight,
          icon: LucideIcons.lock,
          title: s.meSecurity,
          value: settings.biometricEnabled
              ? (face ? s.meSecurityValueFaceId : s.meSecurityValueBiometric)
              : s.meSecurityValuePin,
          onTap: () => context.push('/me/security'),
        ),
      ],
    );
  }
}
