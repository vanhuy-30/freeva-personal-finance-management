import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../auth/presentation/widgets/auth_gate.dart';
import '../../domain/wallet.dart';
import '../viewmodels/wallet_view_model.dart';
import 'wallet_editor_form.dart';

class WalletEditor extends StatefulWidget {
  const WalletEditor({required this.model, this.wallet, super.key});
  final WalletViewModel model;
  final Wallet? wallet;
  @override
  State<WalletEditor> createState() => _WalletEditorState();
}

class _WalletEditorState extends State<WalletEditor> {
  @override
  void initState() {
    super.initState();
    widget.model.addListener(_changed);
  }

  void _changed() {
    // Lock/sign-out clears currencies. Discard the editor and its captured
    // wallet/version so another session cannot submit the previous draft.
    if (widget.model.currencies.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ModalRoute.of(context)?.isCurrent == true) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  void dispose() {
    widget.model.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthGate(
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.wallet == null
              ? S.of(context).walletAdd
              : S.of(context).walletEdit,
        ),
      ),
      body: WalletEditorForm(model: widget.model, wallet: widget.wallet),
    ),
  );
}
