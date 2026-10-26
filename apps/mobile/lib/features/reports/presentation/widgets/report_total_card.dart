import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/money_display.dart';
import '../../domain/report_summary.dart';
import '../../../wallets/presentation/widgets/editor/form_pair.dart';

/// Thu, Chi (with the % against the previous period), average per day and
/// what is left. Two columns when they fit, one stacked column otherwise.
class ReportTotalCard extends StatelessWidget {
  const ReportTotalCard({
    required this.summary,
    required this.currency,
    required this.digits,
    required this.versus,
    super.key,
  });

  final ReportSummary summary;
  final String currency;
  final int digits;

  /// "so với T9": the words after the % change.
  final String versus;

  Widget _money(BigInt minor, MoneyTone tone, double size) => MoneyDisplay(
    minor: minor,
    currency: currency,
    minorDigits: digits,
    tone: tone,
    showCurrency: false,
    style: FreevaTypography.titleL.copyWith(
      fontSize: size,
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final left = summary.remaining;
    final cells = [
      _Cell(s.reportIncome, _money(summary.income, MoneyTone.income, 20)),
      _Cell(
        s.reportExpense,
        _money(summary.expense, MoneyTone.expense, 20),
        note: summary.expenseChange == null
            ? null
            : _Change(summary.expenseChange!, versus),
      ),
      _Cell(
        s.reportAverageDay,
        summary.averagePerDay == null
            ? const SizedBox.shrink()
            : _money(summary.averagePerDay!, MoneyTone.plain, 16),
      ),
      _Cell(
        s.reportRemaining,
        _money(
          left,
          left.isNegative ? MoneyTone.expense : MoneyTone.income,
          16,
        ),
      ),
    ];
    return FreevaCard(
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, box) {
          if (!fitsSideBySide(context, box.maxWidth + 2 * 18 + 40)) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final cell in cells) ...[
                  cell,
                  if (cell != cells.last) const SizedBox(height: 14),
                ],
              ],
            );
          }
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cells[0]),
                  Expanded(child: cells[1]),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cells[2]),
                  Expanded(child: cells[3]),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.label, this.value, {this.note});

  final String label;
  final Widget value;
  final Widget? note;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: FreevaTypography.label.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: 2),
        value,
        if (note != null) note!,
      ],
    );
  }
}

class _Change extends StatelessWidget {
  const _Change(this.percent, this.versus);

  final int percent;
  final String versus;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = S.of(context);
    final style = FreevaTypography.label.copyWith(color: c.textSecondary);
    return Row(
      children: [
        if (percent != 0)
          Icon(
            percent > 0 ? LucideIcons.arrowUp : LucideIcons.arrowDown,
            size: 12,
            color: c.textSecondary,
          ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(s.reportChange('${percent.abs()}', versus), style: style),
        ),
      ],
    );
  }
}
