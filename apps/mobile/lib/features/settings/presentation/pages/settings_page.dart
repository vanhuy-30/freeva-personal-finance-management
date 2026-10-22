import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../auth/presentation/widgets/session_alert_banner.dart';
import '../../../auth/presentation/widgets/session_controls.dart';
import '../../../profile/presentation/viewmodels/profile_view_model.dart';
import '../viewmodels/settings_view_model.dart';
import '../widgets/settings_appearance.dart';
import '../widgets/settings_biometric.dart';
import '../widgets/settings_help_section.dart';
import '../widgets/settings_privacy.dart';
import '../widgets/settings_profile_link.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // Sessions live here until the Security screen of group G.
  static final _sessions = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final model = getIt<SettingsViewModel>();
    final profile = getIt<ProfileViewModel>();
    return ListenableBuilder(
      listenable: Listenable.merge([model, profile]),
      builder: (context, _) {
        final s = S.of(context);
        return Scaffold(
          appBar: AppBar(
            title: Text(s.settingsTitle),
            automaticallyImplyLeading: false,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SettingsAppearance(model: model),
                      SettingsPrivacy(model: model),
                      SettingsProfileLink(locale: profile.locale),
                      SettingsBiometric(model: model),
                      const SettingsHelpSection(),
                      SessionAlertBanner(scrollTarget: _sessions),
                      SessionControls(key: _sessions),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
