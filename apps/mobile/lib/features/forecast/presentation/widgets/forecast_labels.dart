import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';

/// "T11" for `2026-11`.
String forecastMonthShort(S s, String month) =>
    s.reportMonthShort('${int.parse(month.substring(5, 7))}');

/// Month number of `yyyy-MM`.
int forecastMonthNumber(String month) => int.parse(month.substring(5, 7));

/// "+40.950.000" or "−6.000.000"; zero has no sign.
String signedMoney(BigInt minor, int digits, String locale) {
  final sign = minor.isNegative ? '−' : (minor == BigInt.zero ? '' : '+');
  return '$sign${formatMoneyText(minor.abs(), digits, locale)}';
}
