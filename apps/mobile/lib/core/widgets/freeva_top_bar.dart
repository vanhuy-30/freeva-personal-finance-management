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

/// Screen header aligned to the 20 margin. The bar is 8 + row + 8 high
/// (row 44, or 34 for a large title without an action), so content that
/// starts with the usual 8 top padding sits 16 under the header row, as on
/// the boards.
class FreevaTopBar extends StatelessWidget implements PreferredSizeWidget {
  const FreevaTopBar({
    required this.title,
    this.kind = FreevaTopBarKind.push,
    this.action,
    this.onLeading,
    this.showLeading = true,
    this.subtitle,
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

  /// Small line centred under a push/modal title ("Tháng 10, 2026").
  final String? subtitle;

  static const double _inset = FreevaSpace.s2;
  static const double _largeRow = 34;

  bool get _large => kind == FreevaTopBarKind.largeTitle;

  double get _rowHeight =>
      _large && action == null ? _largeRow : FreevaSize.touch;

  @override
  Size get preferredSize => Size.fromHeight(_rowHeight + 2 * _inset);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = S.of(context);
    final large = _large;
    final modal = kind == FreevaTopBarKind.modal;
    final leading = large
        ? null
        : !showLeading
        ? const SizedBox(width: FreevaSize.touch)
        : FreevaIconButton(
            icon: modal ? LucideIcons.x : LucideIcons.chevronLeft,
            iconSize: modal ? FreevaSize.iconSm : null,
            label: modal ? s.commonClose : s.authBack,
            onPressed: onLeading ?? () => Navigator.of(context).maybePop(),
          );
    final style = large
        ? (context.isCompactScreen
              ? FreevaTypography.titleXlCompact
              : FreevaTypography.titleXl)
        : FreevaTypography.titleL;
    Widget heading = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: large ? TextAlign.start : TextAlign.center,
      style: style.copyWith(color: c.textPrimary),
    );
    if (!large && subtitle != null) {
      heading = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          heading,
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: FreevaTypography.label.copyWith(
              fontWeight: FontWeight.w400,
              color: c.textSecondary,
            ),
          ),
        ],
      );
    }
    return Material(
      color: c.bgCanvas,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.screenMargin,
            vertical: _inset,
          ),
          child: SizedBox(
            height: _rowHeight,
            child: Row(
              children: [
                if (leading != null) ...[
                  leading,
                  const SizedBox(width: FreevaSpace.s2),
                ],
                Expanded(
                  child: Semantics(
                    header: true,
                    // Large text may outgrow the row; it spills into the
                    // padding instead of being clipped.
                    child: OverflowBox(
                      maxHeight: double.infinity,
                      alignment: large
                          ? AlignmentDirectional.centerStart
                          : Alignment.center,
                      child: heading,
                    ),
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(width: FreevaSpace.s2),
                  action!,
                ] else if (!large) ...[
                  const SizedBox(width: FreevaSpace.s2),
                  const SizedBox(width: FreevaSize.touch),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
