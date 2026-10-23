import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/freeva_chip.dart';
import '../../../../core/widgets/freeva_text_field.dart';
import '../../domain/feedback.dart';
import '../viewmodels/feedback_view_model.dart';

/// Kind cards, topic chips, the message box with its counter, and the
/// "reply by email" switch.
class FeedbackForm extends StatelessWidget {
  const FeedbackForm({required this.model, required this.message, super.key});

  final FeedbackViewModel model;
  final TextEditingController message;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final kinds = {
      FeedbackKind.bug: (s.fbKindBug, LucideIcons.bug),
      FeedbackKind.idea: (s.fbKindIdea, LucideIcons.lightbulb),
      FeedbackKind.praise: (s.fbKindPraise, LucideIcons.heart),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            s.fbHeading,
            style: FreevaTypography.headline.copyWith(color: c.textPrimary),
          ),
        ),
        const SizedBox(height: FreevaSpace.s4),
        Row(
          children: [
            for (final (i, e) in kinds.entries.indexed) ...[
              if (i > 0) const SizedBox(width: FreevaSpace.s2),
              Expanded(
                child: _KindCard(
                  label: e.value.$1,
                  icon: e.value.$2,
                  selected: model.kind == e.key,
                  onTap: () => model.edit(kind: e.key),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: FreevaSpace.s5),
        Text(
          s.fbAbout,
          style: FreevaTypography.label.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: FreevaSpace.s2),
        Wrap(
          spacing: FreevaSpace.s2,
          runSpacing: FreevaSpace.s2,
          children: [
            for (final e in topics.entries)
              FreevaChip(
                label: e.value,
                selected: model.topic == e.key,
                onTap: () => model.edit(topic: e.key),
              ),
          ],
        ),
        const SizedBox(height: FreevaSpace.s5),
        FreevaTextField(
          label: label,
          controller: message,
          maxLines: 5,
          onChanged: (value) => model.edit(message: value),
        ),
        Padding(
          padding: const EdgeInsets.only(top: FreevaSpace.s1, right: 4),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              s.fbCount(model.message.length),
              style: FreevaTypography.label.copyWith(
                color: model.message.length > feedbackMaxLength
                    ? c.statusDanger
                    : c.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        const SizedBox(height: FreevaSpace.s3),
        FreevaCard(
          list: true,
          padding: const EdgeInsets.symmetric(
            horizontal: FreevaSpace.s4,
            vertical: FreevaSpace.s1,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  s.fbReply,
                  style: FreevaTypography.body.copyWith(color: c.textPrimary),
                ),
              ),
              Switch(
                value: model.allowReply,
                onChanged: (value) => model.edit(allowReply: value),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Icon over a one-line label, so three of them fit a narrow row.
class _KindCard extends StatelessWidget {
  const _KindCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
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
          padding: const EdgeInsets.symmetric(
            vertical: FreevaSpace.s3,
            horizontal: FreevaSpace.s1,
          ),
          decoration: BoxDecoration(
            color: selected ? c.tintBlue : c.bgSurface,
            borderRadius: BorderRadius.circular(FreevaRadius.md),
            border: Border.all(
              color: selected ? c.borderSelected : c.borderDefault,
              width: selected
                  ? FreevaBorder.selected
                  : FreevaBorder.defaultValue,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: FreevaSize.iconInline,
                color: selected ? c.actionPrimary : c.textSecondary,
              ),
              const SizedBox(height: FreevaSpace.s1),
              Text(
                label,
                textAlign: TextAlign.center,
                style: FreevaTypography.bodyS.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
