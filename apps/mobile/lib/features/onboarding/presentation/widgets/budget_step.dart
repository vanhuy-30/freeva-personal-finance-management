import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/compact_money.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/amount_keypad.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/freeva_chip.dart';
import '../viewmodels/onboarding_view_model.dart';
import 'onboarding_frame.dart';

/// Question 3: monthly budget. The number is kept on the device until the
/// budget module exists; the currency is the account's (VND for now).
class BudgetStep extends StatelessWidget {
  const BudgetStep({
    required this.model,
    required this.onNext,
    required this.onSkip,
    required this.onBack,
    super.key,
  });

  final OnboardingViewModel model;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final units = CompactUnits(
      thousand: s.reportUnitThousand,
      million: s.reportUnitMillion,
      billion: s.reportUnitBillion,
    );
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final amount = model.budget == 0
            ? '0'
            : formatMoneyText(BigInt.from(model.budget), 0, locale);
        return OnboardingFrame(
          step: 3,
          title: s.onbBudgetTitle,
          skipLabel: s.onbBudgetLater,
          onSkip: onSkip,
          onNext: onNext,
          onBack: onBack,
          titleGap: 28,
          pinned: AmountKeypad(
            filled: false,
            keyHeight: 50,
            gap: 4,
            radius: FreevaRadius.smd,
            digitSize: 22,
            tripleZeroSize: 17,
            deleteIconSize: 22,
            onDigits: model.typeBudget,
            onDelete: model.deleteBudgetDigit,
          ),
          children: [
            const SizedBox(height: FreevaSpace.s5),
            FreevaCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Semantics(
                    label: '${s.onbBudgetAmount}: $amount ₫',
                    child: ExcludeSemantics(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              amount,
                              style: FreevaTypography.moneyDisplay.copyWith(
                                height: 44 / 40,
                                color: model.budget == 0
                                    ? c.textDisabled
                                    : c.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: FreevaSpace.s2),
                          // Caret: the keypad below types into this number.
                          Container(
                            width: 2,
                            height: 34,
                            decoration: BoxDecoration(
                              color: c.actionPrimary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: FreevaSpace.s3),
                  // Currency is fixed to VND until the budget module exists,
                  // so the pill shows the board's chevron without a picker.
                  Container(
                    height: FreevaSize.pill,
                    padding: const EdgeInsets.fromLTRB(12, 0, 10, 0),
                    decoration: BoxDecoration(
                      color: c.bgSubtle,
                      borderRadius: BorderRadius.circular(FreevaRadius.full),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'VND ₫',
                          style: FreevaTypography.bodyS.copyWith(
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(width: FreevaSpace.s1),
                        ExcludeSemantics(
                          child: Icon(
                            LucideIcons.chevronDown,
                            size: FreevaSize.iconXs,
                            color: c.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: FreevaSpace.s2,
              runSpacing: FreevaSpace.s2,
              children: [
                for (final value in OnboardingViewModel.budgetSuggestions)
                  FreevaChip(
                    label: compactMoney(BigInt.from(value), 0, locale, units),
                    selected: model.budget == value,
                    onTap: () => model.setBudget(value),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
