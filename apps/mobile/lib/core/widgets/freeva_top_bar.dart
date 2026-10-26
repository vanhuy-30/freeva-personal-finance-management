import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';
import 'freeva_icon_button.dart';

enum FreevaTopBarKind {
  /// Tab root: large left title, up to one action.
  largeTitle,

  /// Pushed screen: back on the left, centred title, at most one action.
  push,

  /// Data entry: close on the left, centred title.
  modal,
}

class FreevaTopBar extends StatelessWidget implements PreferredSizeWidget {
  const FreevaTopBar({
    required this.title,
    this.kind = FreevaTopBarKind.push,
    this.action,
    this.onLeading,
    this.showLeading = true,
    super.key,
  });

  final String title;
  final FreevaTopBarKind kind;

  /// Usually a [FreevaIconButton].
  final Widget? action;

  /// Back or close. Defaults to popping the route.
  final VoidCallback? onLeading;

  /// False for screens that leave only through their action ("Xong").
  final bool showLeading;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = S.of(context);
    final margin = context.screenMargin - 4;
    final large = kind == FreevaTopBarKind.largeTitle;
    final leading = large
        ? null
        : !showLeading
        ? const SizedBox(width: FreevaSize.touch)
        : FreevaIconButton(
            icon: kind == FreevaTopBarKind.modal
                ? LucideIcons.x
                : LucideIcons.chevronLeft,
            label: kind == FreevaTopBarKind.modal ? s.commonClose : s.authBack,
            onPressed: onLeading ?? () => Navigator.of(context).maybePop(),
          );
    final style = large
        ? (context.isCompactScreen
              ? FreevaTypography.titleXlCompact
              : FreevaTypography.titleXl)
        : FreevaTypography.titleL;
    return Material(
      color: c.bgCanvas,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: preferredSize.height,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: margin),
            child: Row(
              children: [
                if (leading != null) leading,
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: large ? 4 : 0),
                    child: Semantics(
                      header: true,
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: large ? TextAlign.start : TextAlign.center,
                        style: style.copyWith(color: c.textPrimary),
                      ),
                    ),
                  ),
                ),
                if (action != null)
                  action!
                else if (!large)
                  const SizedBox(width: FreevaSize.touch),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
