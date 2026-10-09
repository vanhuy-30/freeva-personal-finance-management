import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/generated/app_localizations.dart';

class SettingsProfileLink extends StatelessWidget {
  const SettingsProfileLink({required this.locale, super.key});

  final String locale;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final language = locale == 'en' ? s.profileEnglish : s.profileVietnamese;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.translate),
      title: Text(s.settingsProfile),
      subtitle: Text(language),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.go('/profile'),
    );
  }
}
