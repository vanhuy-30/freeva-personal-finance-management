import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/app_preferences.dart';

class SettingsHelpSection extends StatelessWidget {
  const SettingsHelpSection({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(s.settingsHelp, style: Theme.of(context).textTheme.titleMedium),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.quiz_outlined),
          title: Text(s.settingsFaq),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go('/help/faq'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.feedback_outlined),
          title: Text(s.settingsFeedback),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go('/help/feedback'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.gavel_outlined),
          title: Text(s.settingsTerms),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go('/help/legal?doc=terms'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.privacy_tip_outlined),
          title: Text(s.settingsPrivacy),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go('/help/legal?doc=privacy'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(s.settingsVersion(appVersionLabel)),
        ),
      ],
    );
  }
}
