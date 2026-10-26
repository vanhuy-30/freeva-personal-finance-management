import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
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
      height: 1.2,
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
        _Remaining(minor: left, currency: currency, digits: digits),
      ),
    ];
    return FreevaCard(
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, box) {
          if (!fitsSideBySide(context, box.maxWidth + 2 * 18 + 40)) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                cells[0],
                const SizedBox(height: 14),
                cells[1],
                const SizedBox(height: 14),
                _Divided(child: cells[2]),
                const SizedBox(height: 14),
                _Divided(child: cells[3]),
              ],
            );
          }
          Widget row(Widget a, Widget b) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: a),
              const SizedBox(width: FreevaSpace.s3),
              Expanded(child: b),
            ],
          );
          return Column(
            children: [
              row(cells[0], cells[1]),
              const SizedBox(height: 14),
              row(_Divided(child: cells[2]), _Divided(child: cells[3])),
            ],
          );
        },
      ),
    );
  }
}

/// "Còn lại": ink like the board, always signed (+ or −).
class _Remaining extends StatelessWidget {
  const _Remaining({
    required this.minor,
    required this.currency,
    required this.digits,
  });

  final BigInt minor;
  final String currency;
  final int digits;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final text =
        '${minor.isNegative ? '−' : '+'}'
        '${formatMoneyText(minor.abs(), digits, locale)}';
    return Semantics(
      container: true,
      label: '$text ${MoneyDisplay.symbolFor(currency)}',
      excludeSemantics: true,
      child: Text(
        text,
        softWrap: false,
        style: FreevaTypography.titleL.copyWith(
          fontSize: 16,
          height: 1.2,
          color: context.colors.textPrimary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// Second-row cell: hairline on top, 12 below it.
class _Divided extends StatelessWidget {
  const _Divided({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.only(top: FreevaSpace.s3),
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: context.colors.borderDivider)),
    ),
    child: child,
  );
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
          style: FreevaTypography.label.copyWith(
            fontWeight: FontWeight.w400,
            color: c.textSecondary,
          ),
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
    final style = FreevaTypography.label.copyWith(
      fontWeight: FontWeight.w400,
      color: c.textSecondary,
    );
    return Row(
      children: [
        if (percent != 0) ...[
          Icon(
            percent > 0 ? LucideIcons.arrowUp : LucideIcons.arrowDown,
            size: 12,
            color: c.textSecondary,
          ),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(s.reportChange('${percent.abs()}', versus), style: style),
        ),
      ],
    );
  }
}
