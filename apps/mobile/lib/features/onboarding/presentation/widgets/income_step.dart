import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/amount_keypad.dart';
import '../../../../core/widgets/freeva_chip.dart';
import '../viewmodels/onboarding_view_model.dart';
import 'onboarding_frame.dart';

/// Question 2 (board ObIncome): monthly income. A big underlined number with
/// quick amounts; the keypad below types into it.
class IncomeStep extends StatelessWidget {
  const IncomeStep({
    required this.model,
    required this.onNext,
    required this.onSkip,
    super.key,
  });

  final OnboardingViewModel model;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final empty = model.income == BigInt.zero;
        final amount = empty ? '0' : formatMoneyText(model.income, 0, locale);
        final symbol = model.currency == 'VND' ? '₫' : model.currency;
        return OnboardingFrame(
          step: 2,
          title: s.onbIncomeTitle,
          skipLabel: s.authLaterLink,
          onSkip: onSkip,
          onNext: onNext,
          pinned: AmountKeypad(
            filled: false,
            keyHeight: 50,
            gap: 4,
            radius: FreevaRadius.smd,
            digitSize: 22,
            tripleZeroSize: 17,
            deleteIconSize: 22,
            onDigits: model.typeIncome,
            onDelete: model.deleteIncomeDigit,
          ),
          children: [
            const SizedBox(height: FreevaSpace.s2),
            Text(
              s.onbIncomeSub,
              style: FreevaTypography.body.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: FreevaSpace.s4),
            Semantics(
              label: '${s.onbIncomeAmount}: $amount $symbol',
              child: ExcludeSemantics(
                child: Container(
                  padding: const EdgeInsets.only(top: 28, bottom: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: c.actionPrimary, width: 2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          amount,
                          style: FreevaTypography.moneyDisplay.copyWith(
                            color: empty ? c.textDisabled : c.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        symbol,
                        style: FreevaTypography.titleS.copyWith(
                          fontWeight: FontWeight.w500,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (model.currency == 'VND') ...[
              const SizedBox(height: FreevaSpace.s4),
              Wrap(
                spacing: FreevaSpace.s2,
                runSpacing: FreevaSpace.s2,
                children: [
                  for (final value in model.incomeSuggestions)
                    FreevaChip(
                      label: s.onbIncomeChip(
                        '${value ~/ BigInt.from(1000000)}',
                      ),
                      selected: model.income == value,
                      onTap: () => model.setIncome(value.toInt()),
                    ),
                ],
              ),
            ],
            const SizedBox(height: FreevaSpace.s4),
            Text(
              s.onbIncomeHint,
              style: FreevaTypography.bodyS.copyWith(
                height: 18 / 13,
                color: c.textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }
}
