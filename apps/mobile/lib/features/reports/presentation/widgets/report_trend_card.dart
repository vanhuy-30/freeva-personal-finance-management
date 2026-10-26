import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/freeva_segmented.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../domain/report.dart';
import '../../domain/report_trend.dart';
import '../viewmodels/report_view_model.dart';
import 'trend_bars.dart';
import 'trend_labels.dart';

/// "Xu hướng chi": bars for 8 weeks, 6 months or the years with data, plus
/// their average. Hidden when the trend cannot be loaded; the totals above it
/// do not depend on it.
class ReportTrendCard extends StatelessWidget {
  const ReportTrendCard({
    required this.model,
    required this.currency,
    required this.digits,
    super.key,
  });

  final ReportViewModel model;
  final String currency;
  final int digits;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final trend = model.trend;
    if (trend == null && model.trendFailed) return const SizedBox.shrink();
    final locale = Localizations.localeOf(context).toString();
    final series = trend == null ? null : trendSeries(trend, currency);
    return FreevaCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(model: model),
          const SizedBox(height: 14),
          if (series == null)
            const SkeletonBox(height: 164, radius: 12)
          else ...[
            TrendBars(
              series: series,
              kind: model.trendKind,
              currency: currency,
              digits: digits,
            ),
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

/// Title with the Tuần · Tháng · Năm switch; the switch drops under the title
/// at large text so it never gets cut.
class _Header extends StatelessWidget {
  const _Header({required this.model});

  final ReportViewModel model;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final stack = MediaQuery.textScalerOf(context).scale(1) > 1.15;
    final title = Text(
      s.reportTrendTitle,
      style: FreevaTypography.titleM.copyWith(color: c.textPrimary),
    );
    final switcher = FreevaSegmented<ReportPeriodKind>(
      compact: true,
      expand: stack,
      selected: model.trendKind,
      onChanged: model.selectTrend,
      segments: [
        FreevaSegment(ReportPeriodKind.week, s.reportWeek),
        FreevaSegment(ReportPeriodKind.month, s.reportMonth),
        FreevaSegment(ReportPeriodKind.year, s.reportYear),
      ],
    );
    if (stack) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          const SizedBox(height: FreevaSpace.s2),
          switcher,
        ],
      );
    }
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: FreevaSpace.s2,
      children: [title, switcher],
    );
  }
}
