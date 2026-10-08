import '../../../../core/money/money_text.dart';
import '../../domain/wallet.dart';

BigInt? parseWalletMoney(String text, WalletCurrency currency, String locale) =>
    parseMoneyText(text, currency.minorDigits, locale);

String walletMoney(
  BigInt minor,
  WalletCurrency currency,
  String locale, {
  bool grouped = true,
}) => formatMoneyText(minor, currency.minorDigits, locale, grouped: grouped);
