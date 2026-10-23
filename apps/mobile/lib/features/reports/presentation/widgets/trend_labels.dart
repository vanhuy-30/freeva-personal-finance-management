import 'package:intl/intl.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/report.dart';
import '../../domain/report_trend.dart';

/// Axis label under a bar: "T10" for a month, "05/10" for a week, "2026" for
/// a year. Months use the bar's start, so a fiscal month shows where it starts.
String trendBarLabel(S s, ReportPeriodKind kind, TrendBar bar, String locale) {
  final from = DateTime.parse(bar.from);
  return switch (kind) {
    ReportPeriodKind.year => '${from.year}',
    ReportPeriodKind.week => DateFormat(
      s.reportShortDatePattern,
      locale,
    ).format(from),
    _ => s.reportMonthShort('${_monthOf(bar)}'),
  };
}

int _monthOf(TrendBar bar) {
  final from = DateTime.parse(bar.from);
  return from.day == 1 ? from.month : DateTime.parse(bar.to).month;
}

/// Unit of the average line: weeks, months or years.
String trendAverageLabel(S s, ReportPeriodKind kind, int count) =>
    switch (kind) {
      ReportPeriodKind.week => s.reportTrendAverageWeeks(count),
      ReportPeriodKind.year => s.reportTrendAverageYears(count),
      _ => s.reportTrendAverageMonths(count),
    };
