import '../../../../core/money/money_text.dart';
import '../../../wallets/domain/wallet.dart';

String? formatReportMoney(
  BigInt minor,
  String currency,
  List<WalletCurrency> currencies,
  String locale,
) {
  final match = currencies.where((item) => item.code == currency).firstOrNull;
  if (match == null) return null;
  return formatMoneyText(minor, match.minorDigits, locale);
}

String calendarDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
