import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/settings_group.dart';
import '../../../../core/widgets/settings_row.dart';

/// DỮ LIỆU VÀ HỖ TRỢ: bring transactions in or take a copy out, then FAQ,
/// feedback and the legal documents.
class DataSettingsGroup extends StatelessWidget {
  const DataSettingsGroup({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const rowHeight = 54.0;
    return SettingsGroup(
      title: s.meGroupDataHelp,
      children: [
        SettingsRow(
          minHeight: rowHeight,
          icon: LucideIcons.upload,
          title: s.meImportData,
          onTap: () => context.push('/me/import'),
        ),
        SettingsRow(
          minHeight: rowHeight,
          icon: LucideIcons.download,
          title: s.meExportData,
          onTap: () => context.push('/me/export'),
        ),
        SettingsRow(
          minHeight: rowHeight,
          icon: LucideIcons.circleQuestionMark,
          title: s.meFaq,
          onTap: () => context.push('/help/faq'),
        ),
        SettingsRow(
          minHeight: rowHeight,
          icon: LucideIcons.messageSquare,
          title: s.meFeedback,
          onTap: () => context.push('/help/feedback'),
        ),
        SettingsRow(
          minHeight: rowHeight,
          icon: LucideIcons.fileText,
          title: s.meLegal,
          onTap: () => context.push('/help/legal?doc=all'),
        ),
      ],
    );
  }
}
