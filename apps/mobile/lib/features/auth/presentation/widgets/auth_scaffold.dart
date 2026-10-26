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
    super.key,
  });

  final String? title;
  final List<Widget> children;
  final VoidCallback? onBack;
  final Widget? trailing;
  final Widget? footer;
  final double topGap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final margin = context.screenMargin + 4;
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
                      FreevaSpace.s6,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: FreevaSize.iconButton,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (onBack != null)
                                FreevaIconButton(
                                  icon: LucideIcons.chevronLeft,
                                  label: S.of(context).authBack,
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

/// Centred 28 pt screen title.
class AuthTitle extends StatelessWidget {
  const AuthTitle(this.text, {this.subtitle, super.key});

  final String text;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        Semantics(
          header: true,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: FreevaTypography.headline.copyWith(color: c.textPrimary),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: FreevaSpace.s2),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: FreevaTypography.body.copyWith(color: c.textSecondary),
          ),
        ],
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
