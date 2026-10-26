import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/check_mark.dart';
import '../../../../core/widgets/press_scale.dart';

/// One side of the comparison: a radio card with a key–value list. Values
/// that differ from the other side sit in a small warning pill.
class SyncCompareCard extends StatelessWidget {
  const SyncCompareCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.rows,
    super.key,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  /// (label, value, differs)
  final List<(String, String, bool)> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // 14 with the browser's normal line height: rows 27 apart, like the board.
    final key = FreevaTypography.bodyM.copyWith(
      height: 1.2,
      color: c.textSecondary,
    );
    final value = key.copyWith(color: c.textPrimary);
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: '$title, $subtitle',
      child: PressScale(
        child: AnimatedContainer(
          duration: FreevaMotion.fast,
          decoration: BoxDecoration(
            color: selected ? c.tintBlue : c.bgSurface,
            borderRadius: BorderRadius.circular(FreevaRadius.lg),
            border: Border.all(
              color: selected ? c.actionPrimary : c.borderDefault,
              width: selected
                  ? FreevaBorder.selected
                  : FreevaBorder.defaultValue,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(FreevaRadius.lg),
            splashFactory: NoSplash.splashFactory,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FreevaSpace.s4,
                vertical: 14,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      ExcludeSemantics(child: _Radio(selected: selected)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: FreevaTypography.titleM.copyWith(
                                color: c.textPrimary,
                              ),
                            ),
                            Text(
                              subtitle,
                              style: FreevaTypography.label.copyWith(
                                fontWeight: FontWeight.w400,
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  for (final (label, text, differs) in rows) ...[
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: key),
                        const SizedBox(width: FreevaSpace.s3),
                        Expanded(
                          child: Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: differs
                                ? SyncDiffMark(text: text, style: value)
                                : Text(
                                    text,
                                    textAlign: TextAlign.end,
                                    style: value,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Text that differs between the two copies: warning colours, radius 6.
class SyncDiffMark extends StatelessWidget {
  const SyncDiffMark({required this.text, required this.style, super.key});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: c.statusWarningBg,
        borderRadius: BorderRadius.circular(FreevaRadius.xxs),
      ),
      child: Text(
        text,
        textAlign: TextAlign.end,
        style: style.copyWith(
          color: c.statusWarning,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// 22 radio: grey ring, or a filled blue disc with a white tick.
class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedContainer(
      duration: FreevaMotion.fast,
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? c.actionPrimary : null,
        border: selected
            ? null
            : Border.all(color: c.borderStrong, width: FreevaBorder.selected),
      ),
      child: selected
          ? Center(child: CheckMark(color: c.textOnAction, strokeWidth: 3.5))
          : null,
    );
  }
}
