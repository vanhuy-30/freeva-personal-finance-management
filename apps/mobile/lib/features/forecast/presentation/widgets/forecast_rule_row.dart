import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_switch.dart';
import '../../../categories/domain/finance_category.dart';
import '../../../categories/presentation/widgets/category_icon_tile.dart';
import '../../../recurring/domain/recurring_calendar.dart';
import '../../../recurring/domain/recurring_rule.dart';
import '../../../recurring/presentation/widgets/recurring_labels.dart';
import 'forecast_labels.dart';

/// One recurring item or bill the forecast counts, with its own switch. A
/// switched-off item keeps its row; the amount is muted and struck through.
class ForecastRuleRow extends StatelessWidget {
  const ForecastRuleRow({
    required this.rule,
    required this.counted,
    required this.digits,
    this.category,
    required this.onChanged,
    super.key,
  });

  final RecurringRule rule;
  final bool counted;
  final FinanceCategory? category;
  final int digits;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final income = rule.type == 'income';
    final title = ruleTitle(s, rule, null);
    final amount = signedMoney(
      income ? rule.amountMinor.abs() : -rule.amountMinor.abs(),
      digits,
      locale,
    );
    final amountColor = !counted
        ? c.textDisabled
        : income
        ? c.moneyIncome
        : c.textPrimary;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 54),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: Row(
          children: [
            _Tile(rule: rule, category: category, muted: !counted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FreevaTypography.body.copyWith(
                      fontWeight: FontWeight.w500,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle(s),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: FreevaTypography.label.copyWith(
                      fontWeight: FontWeight.w400,
                      color: c.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              amount,
              style: FreevaTypography.bodyM.copyWith(
                fontWeight: FontWeight.w600,
                color: amountColor,
                decoration: counted ? null : TextDecoration.lineThrough,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 8),
            FreevaSwitch(
              value: counted,
              label: s.forecastRuleToggle(title),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle(S s) {
    if (rule.isOneOff) {
      return s.forecastOneOff(dayMonth(rule.nextExecutionDate));
    }
    if (rule.amountKind != 'estimated') return scheduleLabel(s, rule);
    final monthly = rule.unit == 'month' && rule.interval == 1;
    return monthly
        ? s.forecastDayEstimated(anchorDay(rule.startDate))
        : s.forecastEstimated(scheduleLabel(s, rule));
  }
}

/// 32 icon tile: the category's own icon and colour, else a plain one by type.
class _Tile extends StatelessWidget {
  const _Tile({
    required this.rule,
    required this.category,
    required this.muted,
  });

  final RecurringRule rule;
  final FinanceCategory? category;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final income = rule.type == 'income';
    final known = category;
    if (known != null) {
      return CategoryIconTile(
        iconToken: known.iconToken,
        colorToken: known.colorToken,
        size: 32,
        muted: muted,
      );
    }
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: income ? c.tintGreen : c.tintBlue,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        income ? LucideIcons.arrowDownToLine : LucideIcons.receipt,
        size: 17,
        color: income ? c.tintGreenFg : c.tintBlueFg,
      ),
    );
  }
}
