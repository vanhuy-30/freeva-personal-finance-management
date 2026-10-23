import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../wallets/domain/wallet.dart';
import '../../../wallets/presentation/viewmodels/wallet_form.dart';
import '../../../wallets/presentation/widgets/editor/wallet_form_body.dart';
import '../../../wallets/presentation/widgets/wallet_labels.dart';
import '../viewmodels/setup_wallets_view_model.dart';

/// Add-wallet form for first-run setup, opened from a type row: the type is
/// fixed, so the type cards are hidden. Pops `true` once the wallet is saved.
class SetupWalletFormPage extends StatefulWidget {
  const SetupWalletFormPage({
    required this.model,
    required this.type,
    super.key,
  });

  final SetupWalletsViewModel model;
  final WalletType type;

  @override
  State<SetupWalletFormPage> createState() => _SetupWalletFormPageState();
}

class _SetupWalletFormPageState extends State<SetupWalletFormPage> {
  late final WalletForm form = WalletForm(
    currencies: widget.model.currencies,
    clientId: widget.model.newClientId(),
    mainCurrency: SetupWalletsViewModel.mainCurrency,
  )..setType(widget.type);
  final name = TextEditingController();
  final amount = TextEditingController();
  final limit = TextEditingController();
  var _tried = false;

  @override
  void dispose() {
    form.dispose();
    for (final c in [name, amount, limit]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final draft = form.build(
      name: name.text,
      amount: amount.text,
      limit: limit.text,
      locale: Localizations.localeOf(context).toString(),
    );
    if (draft == null) return;
    setState(() => _tried = true);
    final ok = await widget.model.save(draft, form.clientId);
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final margin = context.screenMargin;
    return ListenableBuilder(
      listenable: Listenable.merge([widget.model, form]),
      builder: (context, _) {
        final failure = _tried ? widget.model.failure : null;
        return Scaffold(
          appBar: FreevaTopBar(
            title: s.walletAdd,
            kind: FreevaTopBarKind.modal,
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(
              margin,
              FreevaSpace.s2,
              margin,
              FreevaSpace.s6,
            ),
            children: [
              WalletFormBody(
                form: form,
                name: name,
                amount: amount,
                limit: limit,
                showTypes: false,
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                margin,
                FreevaSpace.s2,
                margin,
                FreevaSpace.s4,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (failure != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: FreevaSpace.s2),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          walletError(s, failure),
                          textAlign: TextAlign.center,
                          style: FreevaTypography.bodyS.copyWith(
                            color: c.statusDanger,
                          ),
                        ),
                      ),
                    ),
                  FreevaButton(
                    label: form.credit ? s.creditSave : s.walletSave,
                    size: FreevaButtonSize.l,
                    expand: true,
                    loading: widget.model.busy,
                    onPressed: widget.model.busy ? null : _save,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
