import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/compact_money.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/money/signed_money.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../domain/report.dart';
import '../../domain/report_flow.dart';
import 'cashflow_chart.dart';

/// "Dòng tiền trong tháng": income minus spending, added up point by point
/// through the period, the day with the most income and the day with the most
/// spending. A period with no income or spending says so instead of a chart.
class ReportCashflowCard extends StatelessWidget {
  const ReportCashflowCard({
    required this.flow,
    required this.currency,
    required this.digits,
    required this.today,
    super.key,
  });

  /// Null while it loads (a skeleton) -- the card is not built at all when
  /// loading failed, see the report body.
  final FlowReport? flow;
  final String currency;
  final int digits;

  /// Device calendar date, to say which end of the axis is "hôm nay".
  final String today;

  @override
  Widget build(BuildContext context) {
    final report = flow;
    if (report == null) return const SkeletonBox(height: 270, radius: 24);
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final series = flowSeries(report, currency);
    final title = switch (report.kind) {
      ReportPeriodKind.week => s.reportFlowTitleWeek,
      ReportPeriodKind.month => s.reportFlowTitleMonth,
      ReportPeriodKind.year => s.reportFlowTitleYear,
      ReportPeriodKind.range => s.reportFlowTitleRange,
    };
    final sub = series.isEmpty
        ? null
        : switch (series.granularity) {
            FlowGranularity.day => s.reportFlowSubDay,
            FlowGranularity.week => s.reportFlowSubWeek,
            FlowGranularity.month => s.reportFlowSubMonth,
          };
    // The line under the title when both do not fit side by side.
    final header = Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: FreevaSpace.s2,
      runSpacing: 2,
      children: [
        Text(
          title,
          style: FreevaTypography.titleM.copyWith(color: c.textPrimary),
        ),
        if (sub != null)
          Text(
            sub,
            style: FreevaTypography.label.copyWith(
              fontWeight: FontWeight.w400,
              color: c.textSecondary,
            ),
          ),
      ],
    );
    if (series.isEmpty) {
      return FreevaCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            const SizedBox(height: FreevaSpace.s5),
            Text(
              s.reportFlowEmpty,
              textAlign: TextAlign.center,
              style: FreevaTypography.titleM.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: FreevaSpace.s1),
            Text(
              s.reportFlowEmptyBody,
              textAlign: TextAlign.center,
              style: FreevaTypography.bodyS.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: FreevaSpace.s3),
          ],
        ),
      );
    }
    final units = CompactUnits(
      thousand: s.reportUnitThousand,
      million: s.reportUnitMillion,
      billion: s.reportUnitBillion,
    );
    String compact(BigInt v) => v == BigInt.zero
        ? '0'
        : '${v.isNegative ? '−' : '+'}${compactMoney(v.abs(), digits, locale, units)}';
    final short = DateFormat(s.reportShortDatePattern, locale);
    String label(FlowPoint p) => switch (series.granularity) {
      FlowGranularity.day => short.format(DateTime.parse(p.from)),
      FlowGranularity.week =>
        p.from == p.to
            ? short.format(DateTime.parse(p.from))
            : '${short.format(DateTime.parse(p.from))} – ${short.format(DateTime.parse(p.to))}',
      FlowGranularity.month => s.reportMonthShort(
        '${DateTime.parse(p.from).month}',
      ),
    };
    final points = series.points;
    final first = points.first;
    final end = points.last;
    final firstLabel = series.granularity == FlowGranularity.week
        ? short.format(DateTime.parse(first.from))
        : label(first);
    final lastLabel =
        series.granularity == FlowGranularity.day && end.to == today
        ? s.reportFlowToday(label(end))
        : label(end);
    final biggestIncome = series.biggestIncome;
    final biggestExpense = series.biggestExpense;
    final markerIndex = biggestIncome == null
        ? null
        : points.indexWhere((p) => p.from == biggestIncome.from);
    return FreevaCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: FreevaSpace.s3),
          CashflowChart(
            values: [for (final p in points) p.cumulative],
            highLabel: series.high > BigInt.zero && series.high != series.last
                ? compact(series.high)
                : null,
            lowLabel: series.low < BigInt.zero && series.low != series.last
                ? compact(series.low)
                : null,
            endLabel: compact(series.last),
            zeroLabel: s.reportFlowZero,
            firstLabel: firstLabel,
            lastLabel: lastLabel,
            markerIndex: markerIndex,
            semanticsLabel: s.reportFlowSemantics(
              signedMoney(series.last, digits, locale),
              signedMoney(series.high, digits, locale),
              signedMoney(series.low, digits, locale),
            ),
          ),
          const SizedBox(height: FreevaSpace.s3),
          LayoutBuilder(
            builder: (context, box) {
              final income = _Extreme(
                label: biggestIncome == null
                    ? s.reportFlowBiggestIncomeNone
                    : s.reportFlowBiggestIncome(label(biggestIncome)),
                value: biggestIncome == null
                    ? s.reportFlowNone
                    : '+${formatMoneyText(biggestIncome.income, digits, locale)}',
                tint: c.statusSuccessBg,
                ink: c.statusSuccess,
              );
              final spend = _Extreme(
                label: biggestExpense == null
                    ? s.reportFlowBiggestExpenseNone
                    : s.reportFlowBiggestExpense(label(biggestExpense)),
                value: biggestExpense == null
                    ? s.reportFlowNone
                    : '−${formatMoneyText(biggestExpense.expense, digits, locale)}',
                tint: c.bgSubtle,
                ink: c.textPrimary,
              );
              final scale = MediaQuery.textScalerOf(context).scale(1);
              if (box.maxWidth / scale < 300) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    income,
                    const SizedBox(height: FreevaSpace.s2),
                    spend,
                  ],
                );
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: income),
                    const SizedBox(width: FreevaSpace.s2),
                    Expanded(child: spend),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Extreme extends StatelessWidget {
  const _Extreme({
    required this.label,
    required this.value,
    required this.tint,
    required this.ink,
  });

  final String label;
  final String value;
  final Color tint;
  final Color ink;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: tint,
      borderRadius: BorderRadius.circular(FreevaRadius.md),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: FreevaTypography.label.copyWith(
            fontWeight: FontWeight.w400,
            color: ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          style: FreevaTypography.titleM.copyWith(
            color: ink,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    ),
  );
}
