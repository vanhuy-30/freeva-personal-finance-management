import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button_style.dart';
import '../../../../core/widgets/press_scale.dart';
import '../../../../core/widgets/freeva_icon_button.dart';

/// Frame of the three question screens: back button, progress bar with
/// "1/3", a left-aligned title, content, and "Để sau" with "Tiếp tục" at the
/// foot. [pinned] sits between the content and the foot (the keypad).
class OnboardingFrame extends StatelessWidget {
  const OnboardingFrame({
    required this.step,
    required this.title,
    required this.children,
    required this.skipLabel,
    required this.onSkip,
    required this.onNext,
    this.onBack,
    this.pinned,
    this.titleGap = FreevaSpace.s8,
    super.key,
  });

  static const total = 3;

  final int step;
  final String title;
  final List<Widget> children;
  final String skipLabel;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final Widget? pinned;

  /// Space between the progress row and the title: 32, or 28 on the budget
  /// board.
  final double titleGap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = S.of(context);
    final margin = context.screenMargin;
    // Boards keep the footer 40 above the screen edge, home indicator
    // included; SafeArea covers the indicator.
    final bottom = (40 - MediaQuery.viewPaddingOf(context).bottom)
        .clamp(FreevaSpace.s2, 40)
        .toDouble();
    return Scaffold(
      backgroundColor: c.bgCanvas,
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
                        _ProgressRow(step: step, onBack: onBack),
                        SizedBox(height: titleGap),
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            style: FreevaTypography.titleXl.copyWith(
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                        ...children,
                        const Spacer(),
                        if (pinned != null) pinned!,
                        const SizedBox(height: FreevaSpace.s3),
                        Row(
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: OnboardingSkipLink(
                                  label: skipLabel,
                                  onPressed: onSkip,
                                ),
                              ),
                            ),
                            _NextButton(
                              label: s.authContinue,
                              onPressed: onNext,
                            ),
                          ],
                        ),
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

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.step, this.onBack});

  final int step;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = S.of(context);
    final row = Row(
      children: [
        if (onBack != null) ...[
          FreevaIconButton(
            icon: LucideIcons.chevronLeft,
            label: s.authBack,
            iconSize: 18,
            onPressed: onBack,
          ),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Semantics(
            label: s.onbProgress(step, OnboardingFrame.total),
            child: ExcludeSemantics(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(FreevaRadius.full),
                child: LinearProgressIndicator(
                  value: step / OnboardingFrame.total,
                  minHeight: 6,
                  color: c.actionPrimary,
                  backgroundColor: c.borderDefault,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        ExcludeSemantics(
          child: Text(
            s.onbProgress(step, OnboardingFrame.total),
            style: FreevaTypography.bodyS.copyWith(
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
        ),
      ],
    );
    // Without a back button the row is only as tall as the bar and "1/3".
    return onBack == null
        ? row
        : SizedBox(height: FreevaSize.iconButton, child: row);
  }
}

/// "Để sau" / "Bỏ qua" text link of the setup screens: 15/600 secondary,
/// 4 px side padding, 44 touch height.
class OnboardingSkipLink extends StatelessWidget {
  const OnboardingSkipLink({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: FreevaSpace.s1),
        minimumSize: const Size(FreevaSize.touch, FreevaSize.touch),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: c.textSecondary,
      ),
      child: Text(
        label,
        style: FreevaTypography.titleM.copyWith(color: c.textSecondary),
      ),
    );
  }
}

/// Ink "Tiếp tục": 52 high, 16/600, 32 side padding.
class _NextButton extends StatelessWidget {
  const _NextButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final style =
        freevaButtonStyle(
          context.colors,
          FreevaButtonVariant.ink,
          FreevaButtonSize.m,
        ).copyWith(
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: FreevaSpace.s8),
          ),
          textStyle: WidgetStatePropertyAll(
            FreevaTypography.titleM.copyWith(fontSize: 16),
          ),
        );
    return PressScale(
      child: TextButton(
        onPressed: onPressed,
        style: style,
        child: Text(label, maxLines: 1),
      ),
    );
  }
}
