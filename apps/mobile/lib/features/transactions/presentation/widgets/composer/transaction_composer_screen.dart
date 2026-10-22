import 'package:flutter/material.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../../../core/widgets/amount_keypad.dart';
import '../../../../../core/widgets/freeva_button.dart';
import '../../../domain/transaction.dart';
import '../../viewmodels/transaction_composer.dart';
import '../../viewmodels/transaction_view_model.dart';
import 'amount_header.dart';
import 'composer_body.dart';
import 'composer_actions.dart';
import 'composer_top_bar.dart';

/// Ghi chi / thu / chuyển (C2.1, C2.3, C2.5). A new transaction opens on
/// the keypad; "Ghi chú, cửa hàng, nhãn" and editing open the details view.
/// Saving closes the screen with a toast; a new one can be undone.
class TransactionComposerScreen extends StatefulWidget {
  const TransactionComposerScreen({
    required this.model,
    this.existing,
    this.copy = false,
    this.initialType,
    super.key,
  });

  final TransactionViewModel model;
  final TransactionBundle? existing;
  final bool copy;
  final TransactionType? initialType;

  @override
  State<TransactionComposerScreen> createState() => _ComposerScreenState();
}

class _ComposerScreenState extends State<TransactionComposerScreen>
    with ComposerActions {
  @override
  late final TransactionComposer composer = TransactionComposer(
    widget.model,
    existing: widget.existing,
    copy: widget.copy,
    initialType: widget.initialType,
  );
  late final merchant = TextEditingController(text: composer.merchant);
  late final notes = TextEditingController(text: composer.notes);
  late bool details = !composer.isNew;

  @override
  void dispose() {
    composer.dispose();
    merchant.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: composer,
    builder: (context, _) {
      final s = S.of(context);
      final margin = context.screenMargin;
      final keypad = !details;
      return PopScope(
        canPop: !composer.dirty,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) close();
        },
        child: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                margin,
                FreevaSpace.s2,
                margin,
                FreevaSpace.s4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ComposerTopBar(composer: composer, onClose: close),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(top: 18),
                      children: [
                        AmountHeader(
                          minor: composer.amount,
                          digits: composer.digits,
                          currency: composer.currency,
                          label: composer.transfer
                              ? s.txTransferAmountLabel
                              : s.txAmountLabel,
                          compact: details,
                          onTap: details
                              ? () => setState(() => details = false)
                              : null,
                        ),
                        const SizedBox(height: 18),
                        ComposerBody(
                          composer: composer,
                          details: details,
                          merchant: merchant,
                          notes: notes,
                          onMore: () => setState(() => details = true),
                        ),
                      ],
                    ),
                  ),
                  if (keypad)
                    AmountKeypad(
                      filled: false,
                      onDigits: composer.typeKeys,
                      onDelete: composer.backspace,
                    ),
                  ComposerError(composer: composer),
                  const SizedBox(height: FreevaSpace.s2),
                  FreevaButton(
                    label: saveLabel(s),
                    size: FreevaButtonSize.l,
                    expand: true,
                    loading: composer.saving,
                    onPressed: save,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
