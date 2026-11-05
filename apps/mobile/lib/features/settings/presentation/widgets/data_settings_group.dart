import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/settings_group.dart';
import '../../../../core/widgets/settings_row.dart';

/// DỮ LIỆU: bring transactions in from another app, or take a copy out.
class DataSettingsGroup extends StatelessWidget {
  const DataSettingsGroup({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const rowHeight = 54.0;
    return SettingsGroup(
      title: s.meGroupData,
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
      ],
    );
  }
}
