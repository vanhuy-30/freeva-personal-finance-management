import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

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
import '../../../server_config/domain/app_limits.dart';
import '../../../../core/di/injection.dart';

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
    final c = context.colors;
    final kind = view == _View.income
        ? BreakdownKind.income
        : BreakdownKind.expense;
    return FreevaCard(
      // RepMonth: 18 all round; RepWallets: 8 under the last wallet row.
      padding: EdgeInsets.fromLTRB(18, 18, 18, view == _View.wallets ? 8 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                s.reportBreakdownTitle,
                style: FreevaTypography.titleM.copyWith(color: c.textPrimary),
              ),
              const SizedBox(width: FreevaSpace.s2),
              Expanded(
                child: Text(
                  switch (view) {
                    _View.expense => s.reportBreakdownSubExpense,
                    _View.income => s.reportBreakdownSubIncome,
                    _View.wallets => s.reportBreakdownSubWallets,
                  },
                  textAlign: TextAlign.end,
                  style: FreevaTypography.label.copyWith(
                    fontWeight: FontWeight.w400,
                    color: c.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: FreevaSpace.s3),
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
          SizedBox(
            height: view == _View.wallets ? FreevaSpace.s2 : FreevaSpace.s3,
          ),
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
                top: getIt<AppLimitsSource>().requireLimits.reportTopRows,
              ),
              currency: widget.currency,
              digits: widget.digits,
            ),
          if (view != _View.wallets) ...[
            const SizedBox(height: FreevaSpace.s3),
            _SeeAll(
              label: view == _View.expense
                  ? s.reportBreakdownAllExpense
                  : s.reportBreakdownAllIncome,
              onTap: () => context.push(
                '/reports/breakdown',
                extra: BreakdownPageArgs(
                  report: widget.report,
                  currency: widget.currency,
                  digits: widget.digits,
                  kind: kind,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Outlined full-width button under the list: opens the whole breakdown.
class _SeeAll extends StatelessWidget {
  const _SeeAll({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: c.bgSurface,
        shape: StadiumBorder(side: BorderSide(color: c.borderDivider)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: FreevaTypography.bodyS.copyWith(
                        fontWeight: FontWeight.w600,
                        color: c.textLink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(LucideIcons.chevronRight, size: 16, color: c.textLink),
                ],
              ),
            ),
          ),
        ),
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
                label: kind == BreakdownKind.expense
                    ? s.reportDonutTotalExpense
                    : s.reportDonutTotalIncome,
                center: total,
              );
              final legend = BreakdownLegend(slices: slices);
              // The legend needs about 110 pt beside the ring; large text or
              // a narrow phone puts it underneath instead.
              final scale = MediaQuery.textScalerOf(context).scale(1);
              final beside =
                  (box.maxWidth - 128 - FreevaSpace.s4) / scale >= 110;
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
        const SizedBox(height: FreevaSpace.s3),
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
