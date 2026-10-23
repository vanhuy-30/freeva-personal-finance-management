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

/// "so với T9", "so với tuần trước"… the grey words after the % change.
String versusLabel(S s, ReportPeriod period, CashflowReport? previous) {
  final before = previous?.period;
  switch (period.kind) {
    case ReportPeriodKind.week:
      return s.reportVsWeek;
    case ReportPeriodKind.year:
      final year = before == null ? null : DateTime.parse(before.from).year;
      return year == null ? s.reportVsPeriod : s.reportVsYear('$year');
    case ReportPeriodKind.month:
      final start = before == null ? null : DateTime.parse(before.from);
      return start == null || start.day != 1
          ? s.reportVsPeriod
          : s.reportVsMonth('${start.month}');
    case ReportPeriodKind.range:
      return s.reportVsPeriod;
  }
}

String backLabel(S s, ReportPeriodKind kind) => switch (kind) {
  ReportPeriodKind.week => s.reportBackWeek,
  ReportPeriodKind.year => s.reportBackYear,
  _ => s.reportBackMonth,
};
