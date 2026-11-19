import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../domain/declared_income.dart';

/// "Dưới 5 triệu", "10 – 20 triệu", "Trên 40 triệu"; an exact amount from
/// before bands shows as money. Bounds that are not whole millions also
/// show as money.
String incomeBandLabel(S s, DeclaredIncome band, int digits, String locale) {
  String money(BigInt minor) => formatMoneyText(minor, digits, locale);
  if (band.isExact) return money(band.minMinor);
  final million = BigInt.from(10).pow(digits) * BigInt.from(1000000);
  String? m(BigInt minor) =>
      minor % million == BigInt.zero ? '${minor ~/ million}' : null;
  final min = m(band.minMinor);
  final max = band.maxMinor == null ? null : m(band.maxMinor!);
  if (band.minMinor == BigInt.zero && max != null) {
    return s.incomeBandUnder(max);
  }
  if (band.maxMinor == null && min != null) return s.incomeBandOver(min);
  if (min != null && max != null) return s.incomeBandBetween(min, max);
  return band.maxMinor == null
      ? '≥ ${money(band.minMinor)}'
      : '${money(band.minMinor)} – ${money(band.maxMinor!)}';
}
