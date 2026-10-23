import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../../core/widgets/settings_group.dart';
import '../../../../core/widgets/settings_row.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../viewmodels/settings_view_model.dart';

/// Bảo mật: how the app unlocks and how you sign in.
class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final SettingsViewModel settings = getIt<SettingsViewModel>();
  final AuthViewModel auth = getIt<AuthViewModel>();

  @override
  void initState() {
    super.initState();
    settings.refreshBiometrics();
    Future.microtask(auth.loadSessions);
  }

  Future<void> _biometric(bool value) async {
    final s = S.of(context);
    await settings.setBiometricEnabled(value, s.settingsBiometricReason);
    if (!mounted || settings.biometricFailure == null) return;
    showFreevaToast(context, message: s.settingsBiometricFailed);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([settings, auth]),
    builder: (context, _) {
      final s = S.of(context);
      final margin = context.screenMargin;
      final canToggle =
          !settings.biometricBusy &&
          (settings.biometricHardware || settings.biometricEnabled);
      return Scaffold(
        appBar: FreevaTopBar(
          title: s.meSecurity,
          onLeading: () => context.popOrGo('/me'),
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            margin,
            FreevaSpace.s2,
            margin,
            FreevaSpace.s8,
          ),
          children: [
            SettingsGroup(
              title: s.meSecUnlock,
              children: auth.hasPin
                  ? [
                      SettingsRow(
                        icon: LucideIcons.lockKeyhole,
                        title: s.meSecPin,
                        subtitle: s.meSecPinSub,
                        value: s.meSecAlways,
                        chevron: false,
                      ),
                      if (settings.biometricHardware ||
                          settings.biometricEnabled)
                        SettingsRow.toggle(
                          icon: LucideIcons.scanFace,
                          title: s.meSecBiometric,
                          on: settings.biometricEnabled,
                          onChanged: (value) {
                            if (canToggle) _biometric(value);
                          },
                        )
                      else
                        SettingsRow(
                          icon: LucideIcons.scanFace,
                          title: s.meSecBiometric,
                          subtitle: s.settingsBiometricUnavailable,
                          chevron: false,
                        ),
                      SettingsRow(
                        icon: LucideIcons.keyRound,
                        title: s.meSecChangePin,
                        onTap: () => context.push('/me/security/pin'),
                      ),
                    ]
                  : [
                      SettingsRow(
                        icon: LucideIcons.lockKeyhole,
                        title: s.meSecPinSetTitle,
                        subtitle: s.meSecPinSub,
                        value: s.meSecPinNone,
                        onTap: () => context.push('/me/security/pin-setup'),
                      ),
                    ],
            ),
            SettingsGroup(
              title: s.meSecLogin,
              children: [
                SettingsRow(
                  icon: LucideIcons.smartphone,
                  title: s.meSecSessions,
                  value: auth.sessions.isEmpty
                      ? null
                      : '${auth.sessions.length}',
                  onTap: () => context.push('/me/sessions'),
                ),
                SettingsRow(
                  icon: LucideIcons.lock,
                  title: s.meSecChangePassword,
                  onTap: () => context.push('/me/security/password'),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
