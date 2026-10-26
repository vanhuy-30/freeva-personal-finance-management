import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_icon_button.dart';

/// Frame of every account screen: optional back button and a top-right
/// action, a centred title, content, and a [footer] pinned to the bottom
/// (or after the content on short screens). Scrolls when the keyboard or a
/// large text size needs the room.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.children,
    this.title,
    this.onBack,
    this.trailing,
    this.footer,
    this.topGap = FreevaSpace.s4,
    this.narrow = false,
    this.bottomInset = 40,
    this.backIcon = LucideIcons.chevronLeft,
    this.backLabel,
    super.key,
  });

  final String? title;
  final List<Widget> children;
  final VoidCallback? onBack;
  final Widget? trailing;
  final Widget? footer;

  /// Gap under the back/action row, or under the top padding when the
  /// screen has neither (the row is then left out).
  final double topGap;

  /// 20 side margins instead of 24 (Setup, PIN, Forgot, Reset boards).
  final bool narrow;

  /// Distance from the screen's bottom edge to the footer as drawn on the
  /// board (32 or 40, home indicator included).
  final double bottomInset;

  /// Back glyph: chevron, or × on screens opened from a link.
  final IconData backIcon;

  /// Screen-reader label of the back button; "Quay lại" when null.
  final String? backLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final margin = context.screenMargin + (narrow ? 0 : 4);
    // SafeArea already keeps the home indicator clear; pad only the rest.
    final bottom = (bottomInset - MediaQuery.viewPaddingOf(context).bottom)
        .clamp(FreevaSpace.s2, bottomInset)
        .toDouble();
    final hasTopRow = onBack != null || trailing != null;
    return Scaffold(
      backgroundColor: c.bgCanvas,
      // Max width sits outside the scroll view: the fill-remaining sliver
      // measures its child at the scroll view's width.
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: FreevaLayout.maxContentWidth,
            ),
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      margin,
                      FreevaSpace.s2,
                      margin,
                      bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (hasTopRow)
                          SizedBox(
                            height: FreevaSize.iconButton,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (onBack != null)
                                  FreevaIconButton(
                                    icon: backIcon,
                                    label: backLabel ?? S.of(context).authBack,
                                    iconSize: 18,
                                    onPressed: onBack,
                                  )
                                else
                                  const SizedBox.shrink(),
                                if (trailing != null) trailing!,
                              ],
                            ),
                          ),
                        SizedBox(height: topGap),
                        if (title != null) AuthTitle(title!),
                        ...children,
                        if (footer != null) ...[
                          const Spacer(),
                          const SizedBox(height: FreevaSpace.s6),
                          footer!,
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 28/34 screen title, centred or left-aligned ([start]), with an optional
/// subtitle 15/22 below it.
class AuthTitle extends StatelessWidget {
  const AuthTitle(
    this.text, {
    this.subtitle,
    this.start = false,
    this.style,
    this.subtitleGap = FreevaSpace.s2,
    this.subtitleMaxWidth,
    super.key,
  });

  final String text;
  final String? subtitle;

  /// Left-aligned (Setup, Forgot, Reset boards) instead of centred.
  final bool start;

  /// Overrides the 28 title style (PIN boards use 26/32).
  final TextStyle? style;
  final double subtitleGap;

  /// Narrower subtitle column, as some boards wrap it (290, 300, 320).
  final double? subtitleMaxWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final align = start ? TextAlign.start : TextAlign.center;
    Widget sub = Text(
      subtitle ?? '',
      textAlign: align,
      style: FreevaTypography.body.copyWith(
        height: 22 / 15,
        color: c.textSecondary,
      ),
    );
    if (subtitleMaxWidth != null) {
      sub = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: subtitleMaxWidth!),
        child: sub,
      );
    }
    return Column(
      crossAxisAlignment: start
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Semantics(
          header: true,
          child: Text(
            text,
            textAlign: align,
            style: (style ?? FreevaTypography.titleXl.copyWith(height: 34 / 28))
                .copyWith(color: c.textPrimary),
          ),
        ),
        if (subtitle != null) ...[SizedBox(height: subtitleGap), sub],
      ],
    );
  }
}

/// "Chưa có tài khoản? Đăng ký" at the foot of the sign-in screens.
class AuthSwitchLink extends StatelessWidget {
  const AuthSwitchLink({
    required this.prompt,
    required this.action,
    required this.onTap,
    this.actionColor,
    super.key,
  });

  final String prompt;
  final String action;
  final VoidCallback? onTap;

  /// Colour of [action]; text primary when null.
  final Color? actionColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            prompt,
            textAlign: TextAlign.end,
            style: FreevaTypography.body.copyWith(color: c.textSecondary),
          ),
        ),
        const SizedBox(width: FreevaSpace.s1),
        Flexible(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(FreevaRadius.sm),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: FreevaSize.touch),
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: 1,
                child: Text(
                  action,
                  style: FreevaTypography.titleM.copyWith(
                    fontSize: 15,
                    color: actionColor ?? c.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
