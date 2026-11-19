import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_input_formatter.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_picker_field.dart';
import '../../../../core/widgets/freeva_text_field.dart';
import '../../../goals/presentation/widgets/goal_date_sheet.dart';
import '../../../goals/presentation/widgets/goal_kind_chip.dart';
import '../../../goals/presentation/widgets/goal_look.dart';
import '../../../wallets/presentation/widgets/editor/form_pair.dart';
import '../viewmodels/onboarding_view_model.dart';
import 'onboarding_frame.dart';

/// Question 3 (boards ObSaving, ObSavingOther): which goal, how much and by
/// when. "Khác" asks for a name first.
class SavingStep extends StatefulWidget {
  const SavingStep({
    required this.model,
    required this.onNext,
    required this.onSkip,
    super.key,
  });

  final OnboardingViewModel model;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  State<SavingStep> createState() => _SavingStepState();
}

class _SavingStepState extends State<SavingStep> {
  final _target = TextEditingController();
  final _name = TextEditingController();

  OnboardingViewModel get model => widget.model;

  @override
  void dispose() {
    _target.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showGoalDateSheet(
      context,
      firstDate: model.firstDate,
      current: model.savingDate,
    );
    if (picked == null || !mounted) return;
    model.pickDate(picked.isEmpty ? null : picked);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final date = model.savingDate;
        return OnboardingFrame(
          step: 3,
          title: s.onbSavingTitle,
          skipLabel: s.authLaterLink,
          onSkip: widget.onSkip,
          onNext: widget.onNext,
          titleGap: 30,
          children: [
            const SizedBox(height: FreevaSpace.s2),
            Text(
              s.onbSavingSub,
              style: FreevaTypography.body.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: FreevaSpace.s2,
              runSpacing: FreevaSpace.s2,
              children: [
                for (final kind in model.savingKinds)
                  GoalKindChip(
                    kind: kind,
                    label: goalKindLabel(s, kind),
                    selected: model.savingKind == kind,
                    tileSize: 24,
                    onTap: () => model.pickKind(kind),
                  ),
              ],
            ),
            if (model.isCustom) ...[
              const SizedBox(height: 14),
              FreevaTextField(
                label: s.onbSavingName,
                controller: _name,
                maxLength: model.goalNameMaxLength,
                textInputAction: TextInputAction.next,
                onChanged: model.setCustomName,
              ),
            ],
            const SizedBox(height: 14),
            _FieldPair(
              first: FreevaTextField(
                label: s.onbSavingTarget,
                controller: _target,
                tabular: true,
                keyboardType: TextInputType.numberWithOptions(
                  decimal: model.digits > 0,
                ),
                inputFormatters: [
                  MoneyInputFormatter(
                    minorDigits: model.digits,
                    locale: locale,
                  ),
                  LengthLimitingTextInputFormatter(20),
                ],
                onChanged: (text) => model.setTargetMinor(
                  parseGroupedMoney(text, model.digits, locale),
                ),
              ),
              second: PickerField(
                label: s.onbSavingDate,
                value: date == null
                    ? s.goalDateNone
                    : goalMonthLabel(date, locale),
                placeholder: date == null,
                chevron: false,
                leading: FieldIconTile(
                  icon: LucideIcons.calendar,
                  background: c.bgSubtle,
                  foreground: c.textOnWash,
                ),
                onTap: _pickDate,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// "Số tiền" and "Thời hạn" side by side, stacked when large text on a narrow
/// screen would not fit two (no LayoutBuilder: the frame measures
/// intrinsics). Width = screen minus the margins, capped at the frame's max.
class _FieldPair extends StatelessWidget {
  const _FieldPair({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context).width;
    final width =
        (screen < FreevaLayout.maxContentWidth
            ? screen
            : FreevaLayout.maxContentWidth) -
        2 * context.screenMargin;
    if (!fitsSideBySide(context, width)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          first,
          const SizedBox(height: FreevaSpace.s2),
          second,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        const SizedBox(width: FreevaSpace.s2),
        Expanded(child: second),
      ],
    );
  }
}
