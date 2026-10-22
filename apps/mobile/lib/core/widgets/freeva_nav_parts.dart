import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';
import 'freeva_bottom_nav.dart';
import 'press_scale.dart';

class NavTab extends StatelessWidget {
  const NavTab({
    required this.item,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final FreevaNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: item.label,
      child: Semantics(
        label: item.label,
        selected: selected,
        button: true,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: FreevaMotion.fast,
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? c.navActiveBg : Colors.transparent,
            ),
            child: Icon(
              item.icon,
              size: FreevaSize.iconInline,
              color: selected ? c.navActiveFg : c.navItem,
            ),
          ),
        ),
      ),
    );
  }
}

class NavAddButton extends StatelessWidget {
  const NavAddButton({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        button: true,
        excludeSemantics: true,
        child: PressScale(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: Container(
              width: FreevaComponent.navFabSize,
              height: FreevaComponent.navFabSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.navFabBg,
                boxShadow: FreevaElevation.fab,
              ),
              child: Icon(
                LucideIcons.plus,
                size: FreevaSize.icon,
                color: c.textOnAction,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
