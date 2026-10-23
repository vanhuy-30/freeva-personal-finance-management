import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
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

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = S.of(context);
    final margin = context.screenMargin;
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
                      FreevaSpace.s4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProgressRow(step: step, onBack: onBack),
                        const SizedBox(height: FreevaSpace.s6),
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            style: FreevaTypography.headline.copyWith(
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
                                child: TextButton(
                                  onPressed: onSkip,
                                  child: Text(
                                    skipLabel,
                                    style: FreevaTypography.titleM.copyWith(
                                      fontSize: 15,
                                      color: c.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            FreevaButton(
                              label: s.authContinue,
                              variant: FreevaButtonVariant.ink,
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
    return SizedBox(
      height: FreevaSize.iconButton,
      child: Row(
        children: [
          if (onBack != null) ...[
            FreevaIconButton(
              icon: LucideIcons.chevronLeft,
              label: s.authBack,
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
              style: FreevaTypography.label.copyWith(color: c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
