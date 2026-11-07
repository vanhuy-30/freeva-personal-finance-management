import 'package:intl/intl.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/net_worth_history.dart';

/// "06/11" (board Q.1), or "06/11/2026" with [year], in the user's locale.
String netWorthDate(String asOf, String locale, {bool year = false}) {
  final date = DateTime.parse(asOf);
  if (locale.startsWith('vi')) {
    return DateFormat(year ? 'dd/MM/yyyy' : 'dd/MM').format(date);
  }
  return (year ? DateFormat.yMMMd(locale) : DateFormat.MMMd(locale)).format(
    date,
  );
}

/// Short x-axis label: "T11" for month windows, "6/11" for day windows, the
/// year for the whole history.
String netWorthAxisLabel(S s, NetWorthWindow window, String asOf) {
  final date = DateTime.parse(asOf);
  return switch (window) {
    NetWorthWindow.week || NetWorthWindow.month => '${date.day}/${date.month}',
    NetWorthWindow.all => '${date.year}',
    _ => s.reportMonthShort('${date.month}'),
  };
}

String netWorthRangeLabel(S s, NetWorthWindow window) =>
    s.netWorthRange(window.name);
