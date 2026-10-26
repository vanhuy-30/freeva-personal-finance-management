import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/compact_money.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/freeva_segmented.dart';
import '../../domain/category_detail.dart';
import '../../domain/report.dart';
import '../../domain/report_breakdown.dart';
import 'breakdown_rows.dart';
import 'donut_chart.dart';
import 'report_wallet_rows.dart';

enum _View { expense, income, wallets }

/// "Phân tích": Chi · Thu as a ring with a list of categories, or Ví with
/// what moved through each wallet. The tab is screen state, not data.
class ReportBreakdownCard extends StatefulWidget {
  const ReportBreakdownCard({
    required this.report,
    required this.currency,
    required this.digits,
    super.key,
  });

  final CashflowReport report;
  final String currency;
  final int digits;

  @override
  State<ReportBreakdownCard> createState() => _ReportBreakdownCardState();
}

class _ReportBreakdownCardState extends State<ReportBreakdownCard> {
  _View view = _View.expense;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return FreevaCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FreevaSegmented<_View>(
            compact: true,
            expand: true,
            selected: view,
            onChanged: (next) => setState(() => view = next),
            segments: [
              FreevaSegment(_View.expense, s.reportViewExpense),
              FreevaSegment(_View.income, s.reportViewIncome),
              FreevaSegment(_View.wallets, s.reportViewWallet),
            ],
          ),
          const SizedBox(height: FreevaSpace.s3),
          if (view == _View.wallets)
            ReportWalletRows(
              rows: [
                for (final row in widget.report.byAccount)
                  if (row.currency == widget.currency) row,
              ]..sort((a, b) => b.netMinor.abs().compareTo(a.netMinor.abs())),
              digits: widget.digits,
            )
          else
            _Categories(
              report: widget.report,
              kind: view == _View.expense
                  ? BreakdownKind.expense
                  : BreakdownKind.income,
              breakdown: reportBreakdown(
                widget.report,
                widget.currency,
                view == _View.expense
                    ? BreakdownKind.expense
                    : BreakdownKind.income,
              ),
              currency: widget.currency,
              digits: widget.digits,
            ),
        ],
      ),
    );
  }
}

class _Categories extends StatelessWidget {
  const _Categories({
    required this.report,
    required this.kind,
    required this.breakdown,
    required this.currency,
    required this.digits,
  });

  final CashflowReport report;
  final BreakdownKind kind;
  final Breakdown breakdown;
  final String currency;
  final int digits;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final slices = breakdown.slices;
    if (slices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: FreevaSpace.s4),
        child: Text(
          s.reportEmptyHint,
          textAlign: TextAlign.center,
          style: FreevaTypography.bodyS.copyWith(color: c.textSecondary),
        ),
      );
    }
    final units = CompactUnits(
      thousand: s.reportUnitThousand,
      million: s.reportUnitMillion,
      billion: s.reportUnitBillion,
    );
    final total = compactMoney(breakdown.total, digits, locale, units);
    return Column(
      children: [
        Semantics(
          container: true,
          label: s
              .reportDonutSemantics(
                '',
                total,
                currency,
                [
                  for (final slice in slices)
                    '${sliceName(s, slice)} ${slice.percent}%',
                ].join(', '),
              )
              .trim(),
          child: LayoutBuilder(
            builder: (context, box) {
              final ring = DonutChart(
                fractions: [for (final slice in slices) slice.percent / 100],
                colors: [
                  for (var i = 0; i < slices.length; i++)
                    sliceColor(context, i, slices[i]),
                ],
                center: total,
              );
              final legend = BreakdownLegend(slices: slices);
              // The legend needs about 110 pt beside the ring; large text or
              // a narrow phone puts it underneath instead.
              final scale = MediaQuery.textScalerOf(context).scale(1);
              final beside =
                  (box.maxWidth - 112 - FreevaSpace.s4) / scale >= 110;
              if (!beside) {
                return Column(
                  children: [ring, const SizedBox(height: 12), legend],
                );
              }
              return Row(
                children: [
                  ring,
                  const SizedBox(width: FreevaSpace.s4),
                  Expanded(child: legend),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: FreevaSpace.s2),
        BreakdownRows(
          slices: slices,
          currency: currency,
          digits: digits,
          onOpen: (slice) => context.push(
            '/reports/category',
            extra: CategoryDetailArgs(
              report: report,
              currency: currency,
              digits: digits,
              kind: kind,
              slice: slice,
            ),
          ),
        ),
      ],
    );
  }
}
