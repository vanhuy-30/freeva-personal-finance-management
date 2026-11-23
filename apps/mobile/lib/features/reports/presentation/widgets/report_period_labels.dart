import 'package:intl/intl.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/report.dart';
import '../../domain/report_period.dart';

/// Title and optional second line of the period navigator, for example
/// "Tháng 10, 2026" over "01/10 – 31/10".
class PeriodTitle {
  const PeriodTitle(this.title, this.subtitle);

  final String title;
  final String? subtitle;
}

PeriodTitle periodTitle(S s, ReportPeriod period, String locale) {
  final from = DateTime.parse(period.from);
  final to = DateTime.parse(period.to);
  final short = DateFormat(s.reportShortDatePattern, locale);
  final span = s.reportPeriod(short.format(from), short.format(to));
  switch (period.kind) {
    case ReportPeriodKind.month:
      if (from.day != 1) return PeriodTitle(span, null);
      final name = DateFormat(s.reportMonthTitlePattern, locale).format(from);
      return PeriodTitle(name, span);
    case ReportPeriodKind.year:
      return PeriodTitle(s.reportYearTitle('${from.year}'), span);
    case ReportPeriodKind.week:
      return PeriodTitle(span, '${to.year}');
    case ReportPeriodKind.range:
      final days = (daysApart(period.from, period.to) ?? 0) + 1;
      return PeriodTitle(span, s.reportRangeDays(days));
  }
}

/// "so tháng trước", "so tuần trước", "so năm trước": the grey words after a
/// change. A custom range has no comparison, so it has no words either.
String? compareLabel(S s, ReportPeriodKind kind) => switch (kind) {
  ReportPeriodKind.week => s.reportCompareWeek,
  ReportPeriodKind.month => s.reportCompareMonth,
  ReportPeriodKind.year => s.reportCompareYear,
  ReportPeriodKind.range => null,
};

/// "Trong tháng 11", "Trong tuần", "Trong năm 2026": which period a card's
/// figures are about.
String inPeriodLabel(S s, ReportPeriod period) {
  final from = DateTime.parse(period.from);
  final to = DateTime.parse(period.to);
  return switch (period.kind) {
    ReportPeriodKind.week => s.reportInWeek,
    ReportPeriodKind.month => s.reportInMonth(
      '${from.day == 1 ? from.month : to.month}',
    ),
    ReportPeriodKind.year => s.reportInYear('${from.year}'),
    ReportPeriodKind.range => s.reportInRange,
  };
}

String backLabel(S s, ReportPeriodKind kind) => switch (kind) {
  ReportPeriodKind.week => s.reportBackWeek,
  ReportPeriodKind.year => s.reportBackYear,
  _ => s.reportBackMonth,
};
