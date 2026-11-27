import 'package:flutter/material.dart';

import '../theme/tokens.g.dart';

/// Flat total card (PA1): surface fill, default border, elevation 1. Used by
/// the Investments and Reports total cards, which sit apart from the washed
/// balance card on Tổng quan.
BoxDecoration totalCardDecoration(FreevaColors c) => BoxDecoration(
  color: c.bgSurface,
  border: Border.all(color: c.borderDefault),
  borderRadius: BorderRadius.circular(FreevaRadius.xl),
  boxShadow: FreevaElevation.s1,
);

/// The stats row under the figure: a divider above, no box.
BoxDecoration totalCardStatsDecoration(FreevaColors c) => BoxDecoration(
  border: Border(top: BorderSide(color: c.borderDivider)),
);

/// Space between the divider and the stats.
const EdgeInsets totalCardStatsPadding = EdgeInsets.only(top: 12);

/// 36 square tint tile with a 18 icon, at the start of a total card's label.
class TotalCardIcon extends StatelessWidget {
  const TotalCardIcon({
    required this.icon,
    required this.background,
    required this.foreground,
    super.key,
  });

  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(FreevaRadius.sm),
      ),
      child: SizedBox.square(
        dimension: 36,
        child: Icon(icon, size: FreevaSize.iconSm, color: foreground),
      ),
    );
  }
}
