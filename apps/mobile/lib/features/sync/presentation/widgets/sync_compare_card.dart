import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/press_scale.dart';

/// One side of the comparison: a radio card with a key–value list. Values
/// that differ from the other side sit on a warning wash.
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
              padding: const EdgeInsets.all(FreevaSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      ExcludeSemantics(
                        child: Icon(
                          selected
                              ? LucideIcons.circleCheck
                              : LucideIcons.circle,
                          size: 22,
                          color: selected ? c.actionPrimary : c.borderDefault,
                        ),
                      ),
                      const SizedBox(width: FreevaSpace.s3),
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
                              style: FreevaTypography.bodyS.copyWith(
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: FreevaSpace.s3),
                  for (final (label, value, differs) in rows)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: FreevaSpace.s3,
                        vertical: FreevaSpace.s2,
                      ),
                      decoration: BoxDecoration(
                        color: differs ? c.statusWarningBg : null,
                        borderRadius: BorderRadius.circular(FreevaRadius.sm),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              label,
                              style: FreevaTypography.bodyS.copyWith(
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              value,
                              textAlign: TextAlign.end,
                              style: FreevaTypography.body.copyWith(
                                fontWeight: differs
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: c.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
