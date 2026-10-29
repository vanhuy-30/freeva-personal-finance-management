import 'package:flutter/foundation.dart';

import '../../../../core/money/money_input_formatter.dart';
import '../../../../core/money/money_text.dart';
import '../../domain/wallet.dart';

enum WalletFormError { name, amount, limit, minimum }

/// State of the add / edit wallet form (D, màn 5–8). Amounts stay text until
/// [build] parses them into minor units. A credit card's debt is typed as a
/// positive number and stored as a negative starting balance.
class WalletForm extends ChangeNotifier {
  WalletForm({
    required this.currencies,
    required this.clientId,
    required String mainCurrency,
    this.wallet,
  }) {
    final draft = wallet?.draft;
    type = draft?.type ?? WalletType.bank;
    currency =
        draft?.currency ??
        (currencies.any((c) => c.code == mainCurrency)
            ? mainCurrency
            : currencies.first.code);
    closeDay = draft?.closeDay;
    dueDay = draft?.dueDay;
  }

  final List<WalletCurrency> currencies;

  /// Kept for the whole form, so a retried create is not duplicated.
  final String clientId;

  /// Null when adding.
  final Wallet? wallet;
  late WalletType type;
  late String currency;
  int? closeDay;
  int? dueDay;
  Set<WalletFormError> errors = const {};

  bool get isNew => wallet == null;

  /// Type and currency cannot change once the wallet has transactions.
  bool get locked => wallet?.hasTransactions ?? false;
  bool get credit => type == WalletType.credit;
  int get minorDigits =>
      currencies.where((c) => c.code == currency).firstOrNull?.minorDigits ?? 0;

  void setType(WalletType value) {
    if (locked || type == value) return;
    type = value;
    notifyListeners();
  }

  void setCurrency(String value) {
    if (locked || currency == value) return;
    currency = value;
    notifyListeners();
  }

  void setCloseDay(int? value) {
    closeDay = value;
    notifyListeners();
  }

  void setDueDay(int? value) {
    dueDay = value;
    notifyListeners();
  }

  /// Text for the amount field: balance, or debt for a card. Empty when new.
  String amountText(String locale) {
    final initial = wallet?.draft.initialBalance;
    if (initial == null) return '';
    final shown = wallet!.draft.type == WalletType.credit ? -initial : initial;
    return formatMoneyText(shown, minorDigits, locale);
  }

  String limitText(String locale) {
    final limit = wallet?.draft.creditLimit;
    return limit == null ? '' : formatMoneyText(limit, minorDigits, locale);
  }

  String minimumText(String locale) {
    final value = wallet?.draft.minimumPayment;
    return value == null ? '' : formatMoneyText(value, minorDigits, locale);
  }

  /// The draft to save, or null after marking what is wrong in [errors].
  /// Empty amount = 0; empty limit / minimum = none.
  WalletDraft? build({
    required String name,
    required String amount,
    required String limit,
    required String locale,
    String minimum = '',
  }) {
    final typed = amount.trim().isEmpty
        ? BigInt.zero
        : parseGroupedMoney(amount, minorDigits, locale);
    final cap = limit.trim().isEmpty
        ? null
        : parseGroupedMoney(limit, minorDigits, locale);
    final minPay = minimum.trim().isEmpty
        ? null
        : parseGroupedMoney(minimum, minorDigits, locale);
    errors = {
      if (name.trim().isEmpty) WalletFormError.name,
      if (typed == null) WalletFormError.amount,
      if (credit && limit.trim().isNotEmpty && (cap == null || cap.isNegative))
        WalletFormError.limit,
      if (credit &&
          minimum.trim().isNotEmpty &&
          (minPay == null || minPay.isNegative))
        WalletFormError.minimum,
    };
    notifyListeners();
    if (errors.isNotEmpty) return null;
    return WalletDraft(
      name: name.trim(),
      type: type,
      currency: currency,
      initialBalance: credit ? -typed! : typed!,
      creditLimit: credit ? cap : null,
      closeDay: credit ? closeDay : null,
      dueDay: credit ? dueDay : null,
      minimumPayment: credit ? minPay : null,
    );
  }
}
