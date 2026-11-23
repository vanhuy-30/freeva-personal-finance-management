import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../domain/report.dart';
import '../../domain/report_period.dart';
import '../../domain/report_trend.dart';
import '../viewmodels/report_view_model.dart';
import 'trend_bars.dart';
import 'trend_labels.dart';

/// "Xu hướng chi" follows the Tuần · Tháng · Năm filter above it: bars for 8 weeks, 6 months or the years with data, plus
/// their average. Hidden when the trend cannot be loaded; the totals above it
/// do not depend on it.
class ReportTrendCard extends StatelessWidget {
  const ReportTrendCard({
    required this.model,
    required this.currency,
    required this.digits,
    required this.today,
    super.key,
  });

  final ReportViewModel model;
  final String currency;
  final int digits;

  /// Device calendar date: the last bar is still running when it ends later.
  final String today;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final trend = model.trend;
    if (trend == null && model.trendFailed) return const SizedBox.shrink();
    final locale = Localizations.localeOf(context).toString();
    final series = trend == null ? null : trendSeries(trend, currency);
    final partial = series == null ? null : _partial(series.bars.last, today);
    return FreevaCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.reportTrendTitle,
                  style: FreevaTypography.titleM.copyWith(color: c.textPrimary),
                ),
              ),
              if (partial != null) ...[
                const SizedBox(width: FreevaSpace.s2),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.tintBlue,
                    borderRadius: BorderRadius.circular(FreevaRadius.full),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    child: Text(
                      s.reportTrendOngoing,
                      style: FreevaTypography.label.copyWith(
                        fontWeight: FontWeight.w600,
                        color: c.tintBlueFg,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          if (series == null)
            const SkeletonBox(height: 164, radius: 12)
          else ...[
            TrendBars(
              series: series,
              kind: model.trendKind,
              currency: currency,
              digits: digits,
              markLast: partial != null,
            ),
            if (partial != null) ...[
              const SizedBox(height: FreevaSpace.s2),
              Text(
                switch (model.trendKind) {
                  ReportPeriodKind.week => s.reportTrendPartialWeek(
                    partial.elapsed,
                    partial.total,
                  ),
                  ReportPeriodKind.year => s.reportTrendPartialYear(
                    '${DateTime.parse(series.bars.last.from).year}',
                    partial.elapsed,
                    partial.total,
                  ),
                  _ => s.reportTrendPartialMonth(
                    '${trendBarMonth(series.bars.last)}',
                    partial.elapsed,
                    partial.total,
                  ),
                },
                style: FreevaTypography.label.copyWith(
                  fontWeight: FontWeight.w400,
                  color: c.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text:
                        '${trendAverageLabel(s, model.trendKind, series.bars.length)}: ',
                  ),
                  TextSpan(
                    text: formatMoneyText(series.average, digits, locale),
                    style: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              style: FreevaTypography.bodyS.copyWith(
                color: c.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// How far a bar that is still running has got: days so far and in all, or
/// null when the bar has ended (or has not begun) as of [today].
({int elapsed, int total})? _partial(TrendBar bar, String today) {
  final untilEnd = daysApart(today, bar.to);
  final sinceStart = daysApart(bar.from, today);
  final total = periodDays(bar.from, bar.to);
  if (untilEnd == null || sinceStart == null || total == null) return null;
  if (untilEnd <= 0 || sinceStart < 0) return null;
  return (elapsed: sinceStart + 1, total: total);
}
