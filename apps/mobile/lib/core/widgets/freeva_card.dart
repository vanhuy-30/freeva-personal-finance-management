import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';

/// White card with elevation 1. `list` uses the list radius (20) for grouped
/// rows; the default card radius is 24.
class FreevaCard extends StatelessWidget {
  const FreevaCard({
    required this.child,
    this.padding = const EdgeInsets.all(FreevaSpace.s4),
    this.onTap,
    this.list = false,
    this.semanticsLabel,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool list;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(
      list ? FreevaComponent.listRadius : FreevaComponent.cardRadius,
    );
    return Semantics(
      label: semanticsLabel,
      button: onTap != null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: list ? c.listBg : c.cardBg,
          borderRadius: radius,
          boxShadow: FreevaElevation.s1,
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            splashFactory: NoSplash.splashFactory,
            highlightColor: c.bgSubtle,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
