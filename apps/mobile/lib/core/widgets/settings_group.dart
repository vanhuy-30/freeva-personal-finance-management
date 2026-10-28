import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';
import 'freeva_card.dart';

/// Group title. Default: upper-case 12/600, letter-spacing 1.4 ("ỨNG DỤNG");
/// [SectionHeader.sentence]: sentence case 13/600 (sheet and form labels).
/// Padding 16 above, 8 below, 4 at the sides.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key}) : sentence = false;

  /// Sentence-case label, 13/600, no letter-spacing ("Loại ví").
  const SectionHeader.sentence(this.title, {super.key}) : sentence = true;

  final String title;

  /// Whether the title keeps its case and uses the 13/600 style.
  final bool sentence;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.textSecondary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, FreevaSpace.s4, 4, FreevaSpace.s2),
      child: Semantics(
        header: true,
        child: Text(
          sentence ? title : title.toUpperCase(),
          style: sentence
              ? FreevaTypography.bodyS.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                )
              : FreevaTypography.sectionLabel.copyWith(color: color),
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
