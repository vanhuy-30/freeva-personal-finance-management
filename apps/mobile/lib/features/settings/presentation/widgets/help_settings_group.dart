import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/settings_group.dart';
import '../../../../core/widgets/settings_row.dart';

/// HỖ TRỢ: FAQ, feedback and the two legal documents.
class HelpSettingsGroup extends StatelessWidget {
  const HelpSettingsGroup({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SettingsGroup(
      title: s.meGroupHelp,
      children: [
        SettingsRow(
          icon: LucideIcons.circleQuestionMark,
          title: s.meFaq,
          onTap: () => context.push('/help/faq'),
        ),
        SettingsRow(
          icon: LucideIcons.messageSquare,
          title: s.meFeedback,
          onTap: () => context.push('/help/feedback'),
        ),
        SettingsRow(
          icon: LucideIcons.scale,
          title: s.meTerms,
          onTap: () => context.push('/help/legal?doc=terms'),
        ),
        SettingsRow(
          icon: LucideIcons.shield,
          title: s.mePrivacy,
          onTap: () => context.push('/help/legal?doc=privacy'),
        ),
      ],
    );
  }
}
