import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../viewmodels/onboarding_view_model.dart';
import '../../../../core/money/currency_catalog.dart';

/// Budget suggestion after the questions (board ObBudgetSuggest): income
/// minus the goal's monthly saving, or minus 20% without a goal. "Dùng mức
/// này" creates this month's budget; "Để sau" creates nothing.
class BudgetSuggestStep extends StatelessWidget {
  const BudgetSuggestStep({
    required this.suggestion,
    required this.digits,
    required this.currency,
    required this.goalName,
    required this.onUse,
    required this.onSkip,
    required this.savingsSharePercent,
    super.key,
  });

  final BudgetSuggestion suggestion;
  final int digits;
  final String currency;

  /// Label of the saving goal; null when the 20% rule is used.
  final String? goalName;
  final VoidCallback onUse;
  final VoidCallback onSkip;

  /// Server `onboarding.savingsSharePercent`, for the no-goal line.
  final int savingsSharePercent;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final margin = context.screenMargin;
    String money(BigInt v) => formatMoneyText(v, digits, locale);
    final symbol = CurrencyCatalog.current.symbol(currency);
    final fromGoal = suggestion.fromGoal && goalName != null;
    final bottom = (32 - MediaQuery.viewPaddingOf(context).bottom)
        .clamp(FreevaSpace.s2, 32)
        .toDouble();
    // Board rows use the browser's normal line height (17 at 14).
    final row = FreevaTypography.bodyM.copyWith(height: 17 / 14);
    Widget line(String label, String value, {Color? dot, bool strong = false}) {
      return Row(
        children: [
          if (dot != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              label,
              style: row.copyWith(
                color: strong ? c.textPrimary : c.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: row.copyWith(
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      );
    }

    // Bar widths follow the real split; flex needs ints, so scale to 1000.
    final spendFlex =
        (suggestion.spending * BigInt.from(1000) ~/ suggestion.income)
            .toInt()
            .clamp(1, 999);
    return Scaffold(
      backgroundColor: c.bgCanvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: FreevaLayout.maxContentWidth,
            ),
            child: CustomScrollView(
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
                        const SizedBox(height: 6 + 14 + 16),
                        Semantics(
                          header: true,
                          child: Text(
                            s.onbSuggestTitle,
                            style: FreevaTypography.titleXl.copyWith(
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        FreevaCard(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Flexible(
                                    child: Text(
                                      money(suggestion.spending),
                                      style: FreevaTypography.moneyDisplay
                                          .copyWith(
                                            fontSize: 36,
                                            height: 40 / 36,
                                            letterSpacing: -1.1,
                                            color: c.textPrimary,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    symbol,
                                    style: FreevaTypography.titleL.copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: c.textOnWash,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              ExcludeSemantics(
                                child: SizedBox(
                                  height: 12,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        flex: spendFlex,
                                        child: _Bar(color: c.actionPrimary),
                                      ),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        flex: 1000 - spendFlex,
                                        child: _Bar(color: c.dataSaving),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              line(
                                s.onbSuggestIncome,
                                money(suggestion.income),
                              ),
                              const SizedBox(height: 8),
                              line(
                                fromGoal
                                    ? s.onbSuggestSaveFor(goalName!)
                                    : s.onbSuggestSaveDefault(
                                        savingsSharePercent,
                                      ),
                                '−${money(suggestion.saving)}',
                                dot: c.dataSaving,
                              ),
                              const SizedBox(height: 8),
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: c.borderDivider,
                              ),
                              const SizedBox(height: 8),
                              line(
                                s.onbSuggestSpend,
                                money(suggestion.spending),
                                dot: c.actionPrimary,
                                strong: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            fromGoal
                                ? s.onbSuggestHint
                                : '${s.onbSuggestNoGoal(savingsSharePercent)} ${s.onbSuggestHint}',
                            style: FreevaTypography.bodyS.copyWith(
                              height: 18 / 13,
                              color: c.textSecondary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(height: 14),
                        FreevaButton(
                          label: s.onbSuggestUse,
                          size: FreevaButtonSize.l,
                          expand: true,
                          onPressed: onUse,
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton(
                            onPressed: onSkip,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(0, FreevaSize.touch),
                              padding: const EdgeInsets.symmetric(
                                horizontal: FreevaSpace.s4,
                              ),
                              foregroundColor: c.textLink,
                            ),
                            child: Text(
                              s.authLaterLink,
                              style: FreevaTypography.titleM.copyWith(
                                color: c.textLink,
                              ),
                            ),
                          ),
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

class _Bar extends StatelessWidget {
  const _Bar({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(FreevaRadius.full),
    ),
  );
}
