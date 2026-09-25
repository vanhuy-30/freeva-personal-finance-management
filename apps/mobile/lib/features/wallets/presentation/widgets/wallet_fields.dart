import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/wallet.dart';
import 'wallet_labels.dart';

class WalletFields extends StatelessWidget {
  const WalletFields({
    required this.name,
    required this.balance,
    required this.limit,
    required this.closeDay,
    required this.dueDay,
    required this.type,
    required this.currency,
    required this.currencies,
    required this.onType,
    required this.onCurrency,
    super.key,
  });
  final TextEditingController name, balance, limit, closeDay, dueDay;
  final WalletType type;
  final String currency;
  final List<WalletCurrency> currencies;
  final ValueChanged<WalletType> onType;
  final ValueChanged<String> onCurrency;
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    Widget field(
      TextEditingController controller,
      String label, {
      bool money = false,
    }) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: money
            ? const TextInputType.numberWithOptions(decimal: true, signed: true)
            : TextInputType.text,
        decoration: InputDecoration(labelText: label),
        maxLength: controller == name ? 100 : null,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        field(name, s.walletName),
        DropdownButtonFormField<WalletType>(
          isExpanded: true,
          initialValue: type,
          decoration: InputDecoration(labelText: s.walletType),
          items: WalletType.values
              .map(
                (t) => DropdownMenuItem(
                  value: t,
                  child: Text(
                    walletTypeLabel(s, t),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onType(v);
          },
        ),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: currency,
          decoration: InputDecoration(labelText: s.profileCurrency),
          items: currencies
              .map((c) => DropdownMenuItem(value: c.code, child: Text(c.code)))
              .toList(),
          onChanged: (v) {
            if (v != null) onCurrency(v);
          },
        ),
        field(balance, s.walletInitialBalance, money: true),
        Text(s.walletMoneyHint),
        if (type == WalletType.credit) ...[
          field(limit, s.walletCreditLimit, money: true),
          field(closeDay, s.walletCloseDay),
          field(dueDay, s.walletDueDay),
        ],
        Text(s.walletEditHint),
      ],
    );
  }
}
