import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_chip.dart';
import '../../../../core/widgets/freeva_switch.dart';
import '../../../../core/widgets/freeva_text_field.dart';
import '../../domain/feedback.dart';
import '../viewmodels/feedback_view_model.dart';

/// Kind cards, topic chips, the message box with its counter, and the
/// "reply by email" switch. 14 between blocks.
class FeedbackForm extends StatelessWidget {
  const FeedbackForm({required this.model, required this.message, super.key});

  final FeedbackViewModel model;
  final TextEditingController message;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final kinds = {
      FeedbackKind.bug: (
        s.fbKindBug,
        LucideIcons.circleAlert,
        (c.statusDangerBg, c.statusDanger),
      ),
      FeedbackKind.idea: (
        s.fbKindIdea,
        LucideIcons.lightbulb,
        (c.statusWarningBg, c.statusWarning),
      ),
      FeedbackKind.praise: (
        s.fbKindPraise,
        LucideIcons.heart,
        (c.tintViolet, c.tintVioletFg),
      ),
    };
    final topics = {
      FeedbackTopic.record: s.fbTopicRecord,
      FeedbackTopic.reports: s.fbTopicReports,
      FeedbackTopic.wallets: s.fbTopicWallets,
      FeedbackTopic.categories: s.fbTopicCategories,
      FeedbackTopic.appearance: s.fbTopicAppearance,
      FeedbackTopic.other: s.fbTopicOther,
    };
    final label = switch (model.kind) {
      FeedbackKind.bug => s.fbLabelBug,
      FeedbackKind.idea => s.fbLabelIdea,
      FeedbackKind.praise => s.fbLabelPraise,
    };
    const gap = SizedBox(height: 14);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            s.fbHeading,
            style: FreevaTypography.headlineCompact.copyWith(
              letterSpacing: -0.3,
              color: c.textPrimary,
            ),
          ),
        ),
        gap,
        LayoutBuilder(
          builder: (context, box) {
            // Narrow screens or large text: tile above the label, so a word
            // never breaks in the middle.
            final stacked =
                (box.maxWidth - 2 * FreevaSpace.s2) / 3 < 100 ||
                MediaQuery.textScalerOf(context).scale(14) > 17;
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, e) in kinds.entries.indexed) ...[
                    if (i > 0) const SizedBox(width: FreevaSpace.s2),
                    Expanded(
                      child: _KindCard(
                        label: e.value.$1,
                        icon: e.value.$2,
                        tint: e.value.$3,
                        selected: model.kind == e.key,
                        stacked: stacked,
                        onTap: () => model.edit(kind: e.key),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        gap,
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4),
          child: Text(
            s.fbAbout,
            style: FreevaTypography.bodyS.copyWith(
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: FreevaSpace.s2),
        Wrap(
          spacing: FreevaSpace.s2,
          runSpacing: FreevaSpace.s2,
          children: [
            for (final e in topics.entries)
              FreevaChip(
                label: e.value,
                size: FreevaChipSize.compact,
                selected: model.topic == e.key,
                onTap: () => model.edit(topic: e.key),
              ),
          ],
        ),
        gap,
        FreevaTextField(
          label: label,
          controller: message,
          maxLines: 3,
          maxLength: feedbackMaxLength,
          showCounter: true,
          onChanged: (value) => model.edit(message: value),
        ),
        gap,
        DecoratedBox(
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(FreevaRadius.md),
            boxShadow: FreevaElevation.tile,
          ),
          child: InkWell(
            onTap: () => model.edit(allowReply: !model.allowReply),
            borderRadius: BorderRadius.circular(FreevaRadius.md),
            splashFactory: NoSplash.splashFactory,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      s.fbReply,
                      style: FreevaTypography.body.copyWith(
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: FreevaSpace.s3),
                  FreevaSwitch(
                    value: model.allowReply,
                    label: s.fbReply,
                    onChanged: (value) => model.edit(allowReply: value),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Tinted 30 tile and a label side by side, 56 high.
class _KindCard extends StatelessWidget {
  const _KindCard({
    required this.label,
    required this.icon,
    required this.tint,
    required this.selected,
    required this.onTap,
    required this.stacked,
  });

  final String label;
  final IconData icon;
  final (Color, Color) tint;

  /// Tile above the label (narrow screens, large text).
  final bool stacked;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      excludeSemantics: true,
      label: label,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: FreevaMotion.fast,
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? c.tintBlue : c.bgSurface,
            borderRadius: BorderRadius.circular(FreevaRadius.mlg),
            border: Border.all(
              color: selected ? c.borderFocus : c.borderDefault,
              width: selected
                  ? FreevaBorder.selected
                  : FreevaBorder.defaultValue,
            ),
          ),
          child: Builder(
            builder: (context) {
              final tile = Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  // On the selected (blue) card the tile turns white.
                  color: selected ? c.bgSurface : tint.$1,
                  borderRadius: BorderRadius.circular(FreevaRadius.xs),
                ),
                child: Icon(icon, size: FreevaSize.iconChip, color: tint.$2),
              );
              final style = FreevaTypography.titleM.copyWith(
                fontSize: 14,
                height: 1.25,
                color: c.textPrimary,
              );
              if (stacked) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    tile,
                    const SizedBox(height: FreevaSpace.s1),
                    Text(label, textAlign: TextAlign.center, style: style),
                  ],
                );
              }
              return Row(
                children: [
                  tile,
                  const SizedBox(width: FreevaSpace.s2),
                  Expanded(child: Text(label, style: style)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
