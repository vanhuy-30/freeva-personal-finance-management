import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/settings_group.dart';

/// First group under a pushed top bar: same as [SettingsGroup] but without the
/// 16 above the title, so the title sits 16 under the header row as on the
/// boards.
class LeadSettingsGroup extends StatelessWidget {
  const LeadSettingsGroup({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, FreevaSpace.s2),
        child: Semantics(
          header: true,
          child: Text(
            title.toUpperCase(),
            style: FreevaTypography.sectionLabel.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ),
      ),
      SettingsGroup(children: children),
    ],
  );
}
