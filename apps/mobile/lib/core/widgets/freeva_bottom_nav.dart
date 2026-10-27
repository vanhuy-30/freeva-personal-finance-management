import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';
import 'freeva_nav_parts.dart';
import 'nav_notch_painter.dart';

class FreevaNavItem {
  const FreevaNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Floating pill nav: 4 icon-only tabs and the + button in the middle,
/// centred in the bar then lifted 26 into a notch that leaves a 6 px ring all
/// round. Only on the 4 tab roots.
class FreevaBottomNav extends StatelessWidget {
  const FreevaBottomNav({
    required this.items,
    required this.currentIndex,
    required this.onSelect,
    required this.onAdd,
    required this.addLabel,
    super.key,
  }) : assert(items.length == 4);

  final List<FreevaNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;
  final String addLabel;

  /// Height the nav occupies above the safe area, + button included (86):
  /// the button pokes 22 above the bar.
  static const double extent =
      FreevaComponent.navHeight / 2 +
      FreevaComponent.navFabLift +
      FreevaComponent.navFabSize / 2;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const fab = FreevaComponent.navFabSize;
    const lift = FreevaComponent.navFabLift;
    const barHeight = FreevaComponent.navHeight;
    const fabCenterY = barHeight / 2 - lift;
    Widget tab(int i) => NavTab(
      item: items[i],
      selected: i == currentIndex,
      onTap: () => onSelect(i),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        FreevaLayout.screenMargin,
        0,
        FreevaLayout.screenMargin,
        FreevaLayout.navOffsetBottom + MediaQuery.paddingOf(context).bottom,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: FreevaLayout.maxContentWidth,
        ),
        child: SizedBox(
          height: extent,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: barHeight,
                child: CustomPaint(
                  painter: NavNotchPainter(
                    color: c.navBg,
                    shadows: FreevaElevation.s2,
                    notchCenterY: fabCenterY,
                    notchRadius: fab / 2 + FreevaComponent.navFabNotch,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: FreevaSpace.s2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        tab(0),
                        tab(1),
                        const SizedBox(width: fab),
                        tab(2),
                        tab(3),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: NavAddButton(label: addLabel, onTap: onAdd),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
