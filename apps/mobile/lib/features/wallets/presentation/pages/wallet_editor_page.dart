import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../auth/presentation/widgets/auth_gate.dart';
import '../../domain/wallet.dart';
import '../viewmodels/wallet_form.dart';
import '../viewmodels/wallet_view_model.dart';
import '../widgets/editor/wallet_form_body.dart';
import '../widgets/wallet_labels.dart';

enum WalletEditResult { saved, hidden }

/// Opens "Thêm ví" ([wallet] null) or "Sửa ví" as a modal.
Future<WalletEditResult?> openWalletEditor(
  BuildContext context,
  WalletViewModel model, {
  Wallet? wallet,
}) {
  if (model.busy || model.needsReload || model.currencies.isEmpty) {
    return Future.value();
  }
  return Navigator.of(context).push<WalletEditResult>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => WalletEditorPage(model: model, wallet: wallet),
    ),
  );
}

/// Thêm ví / Sửa ví (D, màn 5, 6, 8). Locking or signing out closes it and
/// drops the draft.
class WalletEditorPage extends StatefulWidget {
  const WalletEditorPage({required this.model, this.wallet, super.key});

  final WalletViewModel model;
  final Wallet? wallet;

  @override
  State<WalletEditorPage> createState() => _WalletEditorPageState();
}

class _WalletEditorPageState extends State<WalletEditorPage> {
  WalletViewModel get model => widget.model;
  late final WalletForm form = WalletForm(
    currencies: model.currencies,
    clientId: model.newClientId(),
    mainCurrency: model.mainCurrency,
    wallet: widget.wallet,
  );
  final name = TextEditingController();
  final amount = TextEditingController();
  final limit = TextEditingController();
  bool _filled = false;

  /// Errors from earlier screens are not this form's; show only after Lưu.
  bool _tried = false;

  @override
  void initState() {
    super.initState();
    model.addListener(_changed);
    name.text = widget.wallet?.draft.name ?? '';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_filled) return;
    _filled = true;
    final locale = Localizations.localeOf(context).toString();
    amount.text = form.amountText(locale);
    limit.text = form.limitText(locale);
  }

  void _changed() {
    // Lock / sign-out clears currencies: drop the draft and its version.
    if (model.currencies.isNotEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        Navigator.of(context).pop();
      }
    });
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
    final ok = await model.save(draft, form.clientId, wallet: widget.wallet);
    if (ok && mounted) Navigator.of(context).pop(WalletEditResult.saved);
  }

  Future<void> _hide() async {
    final wallet = widget.wallet;
    if (wallet == null) return;
    setState(() => _tried = true);
    final ok = await model.archive(wallet);
    if (ok && mounted) Navigator.of(context).pop(WalletEditResult.hidden);
  }

  @override
  void dispose() {
    model.removeListener(_changed);
    form.dispose();
    for (final c in [name, amount, limit]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final margin = context.screenMargin;
    return AuthGate(
      child: ListenableBuilder(
        listenable: Listenable.merge([model, form]),
        builder: (context, _) {
          final editing = widget.wallet != null;
          final credit =
              (widget.wallet?.draft.type ?? form.type) == WalletType.credit;
          final failure = _tried ? model.failure : null;
          // "Thêm ví" board spaces its groups 18; card and edit boards 16.
          final roomy = !editing && !form.credit;
          final bottom = math.max(28.0, MediaQuery.paddingOf(context).bottom);
          return Scaffold(
            appBar: FreevaTopBar(
              title: !editing
                  ? s.walletAdd
                  : credit
                  ? s.walletEditCard
                  : s.walletEdit,
              kind: FreevaTopBarKind.modal,
            ),
            body: ListView(
              padding: EdgeInsets.fromLTRB(
                margin,
                roomy ? 10 : FreevaSpace.s2,
                margin,
                FreevaSpace.s6,
              ),
              children: [
                WalletFormBody(
                  form: form,
                  name: name,
                  amount: amount,
                  limit: limit,
                  onHide: editing && !model.busy ? _hide : null,
                  gap: roomy ? 18 : FreevaSpace.s4,
                ),
              ],
            ),
            // Board: the button sits 28 from the bottom edge (or on the
            // home-indicator inset when that is larger).
            bottomNavigationBar: Padding(
              padding: EdgeInsets.fromLTRB(
                margin,
                FreevaSpace.s2,
                margin,
                bottom,
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
                    label: editing
                        ? s.walletSaveChanges
                        : form.credit
                        ? s.creditSave
                        : s.walletSave,
                    size: FreevaButtonSize.l,
                    expand: true,
                    loading: model.busy,
                    onPressed: model.busy || model.needsReload ? null : _save,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
