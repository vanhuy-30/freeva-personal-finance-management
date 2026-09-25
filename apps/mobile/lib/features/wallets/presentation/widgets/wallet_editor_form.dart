import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/wallet.dart';
import '../viewmodels/wallet_view_model.dart';
import 'wallet_fields.dart';
import 'wallet_labels.dart';
import 'wallet_money.dart';

class WalletEditorForm extends StatefulWidget {
  const WalletEditorForm({required this.model, this.wallet, super.key});
  final WalletViewModel model;
  final Wallet? wallet;
  @override
  State<WalletEditorForm> createState() => _WalletEditorFormState();
}

class _WalletEditorFormState extends State<WalletEditorForm> {
  final name = TextEditingController(),
      balance = TextEditingController(),
      limit = TextEditingController();
  final closeDay = TextEditingController(), dueDay = TextEditingController();
  late WalletType type;
  late String currency, clientId;
  bool initialized = false, invalid = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) return;
    initialized = true;
    final d = widget.wallet?.draft;
    type = d?.type ?? WalletType.cash;
    currency = d?.currency ?? widget.model.currencies.first.code;
    clientId = widget.model.newClientId();
    name.text = d?.name ?? '';
    final c = widget.model.currencies.firstWhere((c) => c.code == currency);
    final locale = Localizations.localeOf(context).toString();
    balance.text = walletMoney(
      d?.initialBalance ?? BigInt.zero,
      c,
      locale,
      grouped: false,
    );
    limit.text = d?.creditLimit == null
        ? ''
        : walletMoney(d!.creditLimit!, c, locale, grouped: false);
    closeDay.text = d?.closeDay?.toString() ?? '';
    dueDay.text = d?.dueDay?.toString() ?? '';
  }

  Future<void> save() async {
    final c = widget.model.currencies.firstWhere((c) => c.code == currency);
    final locale = Localizations.localeOf(context).toString();
    final amount = parseWalletMoney(balance.text, c, locale);
    final credit = limit.text.trim().isEmpty
        ? null
        : parseWalletMoney(limit.text, c, locale);
    final close = int.tryParse(closeDay.text.trim()),
        due = int.tryParse(dueDay.text.trim());
    if (amount == null ||
        (type == WalletType.credit &&
            ((limit.text.trim().isNotEmpty && credit == null) ||
                (closeDay.text.trim().isNotEmpty && close == null) ||
                (dueDay.text.trim().isNotEmpty && due == null)))) {
      setState(() => invalid = true);
      return;
    }
    setState(() => invalid = false);
    final ok = await widget.model.save(
      WalletDraft(
        name: name.text,
        type: type,
        currency: currency,
        initialBalance: amount,
        creditLimit: type == WalletType.credit ? credit : null,
        closeDay: type == WalletType.credit ? close : null,
        dueDay: type == WalletType.credit ? due : null,
      ),
      clientId,
      wallet: widget.wallet,
    );
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.model,
    builder: (context, _) {
      final s = S.of(context), model = widget.model;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (model.busy) const LinearProgressIndicator(),
            AbsorbPointer(
              absorbing: model.busy || model.needsReload,
              child: WalletFields(
                name: name,
                balance: balance,
                limit: limit,
                closeDay: closeDay,
                dueDay: dueDay,
                type: type,
                currency: currency,
                currencies: model.currencies,
                onType: (v) => setState(() => type = v),
                onCurrency: (v) => setState(() => currency = v),
              ),
            ),
            if (invalid || model.failure != null)
              Semantics(
                liveRegion: true,
                child: Text(
                  invalid ? s.walletInvalid : walletError(s, model.failure!),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (model.needsReload) Text(s.walletReloadRequired),
            FilledButton(
              onPressed: model.busy || model.needsReload ? null : save,
              child: Text(s.profileSave),
            ),
          ],
        ),
      );
    },
  );
  @override
  void dispose() {
    for (final c in [name, balance, limit, closeDay, dueDay]) {
      c.dispose();
    }
    super.dispose();
  }
}
