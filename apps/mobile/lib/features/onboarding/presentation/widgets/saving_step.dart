import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_input_formatter.dart';
import '../../../../core/money/money_text.dart';
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

/// Question 3 (board ObSaving): what to save for, how much and by when. The
/// monthly amount comes from the server preview once both are filled.
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

  OnboardingViewModel get model => widget.model;

  @override
  void dispose() {
    _target.dispose();
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
        final need = model.preview?.requiredPerMonthMinor;
        return OnboardingFrame(
          step: 3,
          title: s.onbSavingTitle,
          skipLabel: s.authLaterLink,
          onSkip: widget.onSkip,
          onNext: widget.onNext,
          titleGap: 30,
          children: [
            const SizedBox(height: 22),
            Wrap(
              spacing: FreevaSpace.s2,
              runSpacing: FreevaSpace.s2,
              children: [
                for (final kind in OnboardingViewModel.savingKinds)
                  GoalKindChip(
                    kind: kind,
                    label: goalKindLabel(s, kind),
                    selected: model.savingKind == kind,
                    tileSize: 24,
                    onTap: () => model.pickKind(kind),
                  ),
              ],
            ),
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
            if (model.savingReady && need != null) ...[
              const SizedBox(height: 14),
              _NeedCard(
                amount: formatMoneyText(need, model.digits, locale),
                shareBps: model.preview?.incomeShareBps,
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Green card: "Mỗi tháng cần để dành" over the amount and, with income, the
/// share of it ("· 24% thu nhập").
class _NeedCard extends StatelessWidget {
  const _NeedCard({required this.amount, this.shareBps});

  final String amount;
  final int? shareBps;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final share = shareBps;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.tintGreen,
        borderRadius: BorderRadius.circular(FreevaRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.onbSavingNeed,
            style: FreevaTypography.bodyS.copyWith(
              height: 16 / 13,
              color: c.textOnWash,
            ),
          ),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              text: amount,
              style: FreevaTypography.titleS.copyWith(
                height: 24 / 20,
                fontWeight: FontWeight.w600,
                color: c.tintGreenFg,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              children: [
                if (share != null)
                  TextSpan(
                    text:
                        ' · ${s.onbSavingShare(percentFromBps(share, locale))}',
                    style: FreevaTypography.bodyM.copyWith(
                      fontWeight: FontWeight.w500,
                      color: c.textOnWash,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 2400 → "24", 2435 → "24,3" (vi) / "24.3" (en): one decimal at most,
/// rounded down, integer maths only.
String percentFromBps(int bps, String locale) {
  final whole = bps ~/ 100;
  final tenth = (bps % 100) ~/ 10;
  if (tenth == 0) return '$whole';
  return '$whole${locale.startsWith('vi') ? ',' : '.'}$tenth';
}

/// "Cần có" and "Đến khi" side by side, stacked when large text on a narrow
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
