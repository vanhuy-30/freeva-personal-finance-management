import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_dialog.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../../core/widgets/settings_group.dart';
import '../../../../core/widgets/settings_row.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../auth/presentation/widgets/session_alert_banner.dart';
import '../../../profile/presentation/viewmodels/profile_view_model.dart';
import '../../domain/app_preferences.dart';
import '../viewmodels/settings_view_model.dart';
import '../widgets/app_settings_group.dart';
import '../widgets/help_settings_group.dart';
import '../widgets/money_setup_group.dart';
import '../widgets/profile_card.dart';

/// Cá nhân: the tab root. Profile card, three groups, log out and version.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final SettingsViewModel settings = getIt<SettingsViewModel>();
  late final ProfileViewModel profile = getIt<ProfileViewModel>();

  @override
  void initState() {
    super.initState();
    settings.refreshAccount();
    settings.refreshBiometrics();
  }

  Future<void> _logout() async {
    final s = S.of(context);
    final ok = await showFreevaConfirm(
      context: context,
      title: s.meLogoutTitle,
      message: s.meLogoutBody,
      cancelLabel: s.commonCancel,
      confirmLabel: s.meLogout,
      destructive: true,
    );
    if (ok) await getIt<AuthViewModel>().logout();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([settings, profile]),
    builder: (context, _) {
      final s = S.of(context);
      final c = context.colors;
      final margin = context.screenMargin;
      return Scaffold(
        appBar: FreevaTopBar(
          title: s.meTitle,
          kind: FreevaTopBarKind.largeTitle,
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            margin,
            FreevaSpace.s2,
            margin,
            FreevaLayout.navReserve,
          ),
          children: [
            SessionAlertBanner(onReview: () => context.push('/me/sessions')),
            ProfileCard(
              name: profile.saved?.displayName,
              email: settings.email,
            ),
            MoneySetupGroup(profile: profile),
            AppSettingsGroup(settings: settings, profile: profile),
            const HelpSettingsGroup(),
            const SizedBox(height: FreevaSpace.s5),
            SettingsGroup(
              children: [
                SettingsRow(
                  icon: LucideIcons.logOut,
                  title: s.meLogout,
                  destructive: true,
                  onTap: _logout,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: FreevaSpace.s4),
              child: Text(
                s.settingsVersion(appVersionLabel),
                textAlign: TextAlign.center,
                style: FreevaTypography.label.copyWith(color: c.textSecondary),
              ),
            ),
          ],
        ),
      );
    },
  );
}
