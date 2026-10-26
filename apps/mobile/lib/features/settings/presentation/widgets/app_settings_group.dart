import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/settings_group.dart';
import '../../../../core/widgets/settings_row.dart';
import '../../../profile/presentation/viewmodels/profile_view_model.dart';
import '../../domain/account_labels.dart';
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
    final theme = switch (settings.theme) {
      AppThemePreference.light => s.meThemeLight,
      AppThemePreference.dark => s.meThemeDark,
      AppThemePreference.system => s.meThemeSystem,
    };
    return SettingsGroup(
      title: s.meGroupApp,
      children: [
        SettingsRow(
          icon: LucideIcons.palette,
          title: s.meTheme,
          value: theme,
          onTap: () => showThemeSheet(context, settings),
        ),
        SettingsRow(
          icon: LucideIcons.languages,
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
          icon: LucideIcons.clock,
          title: s.meTimezone,
          value: saved == null
              ? null
              : gmtLabel(saved.timezone, DateTime.now()),
          onTap: saved == null || profile.options == null
              ? null
              : () async {
                  final picked = await showChoiceSheet<String>(
                    context,
                    title: s.meTimezone,
                    selected: saved.timezone,
                    searchHint: s.profileSearch,
                    options: [
                      for (final zone in profile.options!.timezones)
                        Choice(
                          zone,
                          '${gmtLabel(zone, DateTime.now())} · $zone',
                        ),
                    ],
                  );
                  if (picked == null || picked == saved.timezone) return;
                  if (!context.mounted) return;
                  await applyProfile(
                    context,
                    profile,
                    (p) => p.copyWith(timezone: picked),
                  );
                },
        ),
        SettingsRow(
          icon: LucideIcons.bell,
          title: s.meNotifications,
          onTap: () => context.push('/me/notifications'),
        ),
        SettingsRow.toggle(
          icon: LucideIcons.eyeOff,
          title: s.meHideBalances,
          on: settings.balancesHidden,
          onChanged: (value) {
            if (!settings.loading) settings.setBalancesHidden(value);
          },
        ),
        SettingsRow(
          icon: LucideIcons.shieldCheck,
          title: s.meSecurity,
          value: settings.biometricEnabled
              ? s.meSecurityValueBiometric
              : s.meSecurityValuePin,
          onTap: () => context.push('/me/security'),
        ),
      ],
    );
  }
}
