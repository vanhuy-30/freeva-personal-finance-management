import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
          leading: const Icon(LucideIcons.circleQuestionMark),
          title: Text(s.settingsFaq),
          trailing: const Icon(LucideIcons.chevronRight),
          onTap: () => context.push('/help/faq'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(LucideIcons.messageSquare),
          title: Text(s.settingsFeedback),
          trailing: const Icon(LucideIcons.chevronRight),
          onTap: () => context.push('/help/feedback'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(LucideIcons.scale),
          title: Text(s.settingsTerms),
          trailing: const Icon(LucideIcons.chevronRight),
          onTap: () => context.push('/help/legal?doc=terms'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(LucideIcons.shieldCheck),
          title: Text(s.settingsPrivacy),
          trailing: const Icon(LucideIcons.chevronRight),
          onTap: () => context.push('/help/legal?doc=privacy'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(s.settingsVersion(appVersionLabel)),
        ),
      ],
    );
  }
}
