import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';
import 'freeva_card.dart';

/// Upper-case group title ("ỨNG DỤNG").
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, FreevaSpace.s5, 4, FreevaSpace.s2),
      child: Semantics(
        header: true,
        child: Text(
          title.toUpperCase(),
          style: FreevaTypography.overline.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Rows in one white card, separated by hairline dividers.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({required this.children, this.title, super.key});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) SectionHeader(title!),
        FreevaCard(
          list: true,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) Divider(height: 1, color: c.listDivider),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
