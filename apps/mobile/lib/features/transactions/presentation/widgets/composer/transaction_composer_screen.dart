import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../../../core/widgets/amount_keypad.dart';
import '../../../../../core/widgets/freeva_button.dart';
import '../../../../category_suggest/presentation/viewmodels/category_suggest_view_model.dart';
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
    this.fromAccountId,
    this.toAccountId,
    super.key,
  });

  final TransactionViewModel model;
  final TransactionBundle? existing;
  final bool copy;
  final TransactionType? initialType;

  /// Preselected source / destination wallet (from wallet detail).
  final String? fromAccountId;
  final String? toAccountId;

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
    fromAccountId: widget.fromAccountId,
    toAccountId: widget.toAccountId,
  );
  late final merchant = TextEditingController(text: composer.merchant);
  late final notes = TextEditingController(text: composer.notes);
  late bool details = !composer.isNew;

  /// R.1: only while recording a new transaction.
  @override
  late final CategorySuggestViewModel? suggest =
      composer.isNew && getIt.isRegistered<CategorySuggestViewModel>()
      ? getIt<CategorySuggestViewModel>()
      : null;

  @override
  void initState() {
    super.initState();
    if (suggest == null) return;
    composer.addListener(_suggestQuery);
    merchant.addListener(_suggestQuery);
    notes.addListener(_suggestQuery);
    _suggestQuery();
  }

  void _suggestQuery() => suggest?.update(
    type: composer.type,
    merchant: merchant.text,
    note: notes.text,
    categoryId: composer.categoryId,
    fits: (id) => composer.fitting.any((c) => c.id == id),
  );

  @override
  void dispose() {
    if (suggest case final model?) {
      composer.removeListener(_suggestQuery);
      merchant.removeListener(_suggestQuery);
      notes.removeListener(_suggestQuery);
      model.dispose();
    }
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
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                margin,
                FreevaSpace.s2,
                margin,
                // Board: 28 under the button.
                math.max(28, MediaQuery.paddingOf(context).bottom),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ComposerTopBar(composer: composer, onClose: close),
                  Expanded(
                    child: ListView(
                      // Board gaps: keypad view 18 (+18 above the
                      // amount), transfer 16 (+6), details 16 (+8 in the
                      // compact amount).
                      padding: EdgeInsets.only(
                        top: details
                            ? FreevaSpace.s4
                            : composer.transfer
                            ? 22
                            : 36,
                      ),
                      children: [
                        AmountHeader(
                          minor: composer.amount,
                          digits: composer.digits,
                          currency: composer.currency,
                          label: composer.transfer
                              ? s.txTransferAmountLabel
                              : s.txAmountLabel,
                          compact: details,
                          transfer: composer.transfer,
                          onTap: details
                              ? () => setState(() => details = false)
                              : null,
                        ),
                        SizedBox(
                          height: details || composer.transfer
                              ? FreevaSpace.s4
                              : FreevaSpace.s5,
                        ),
                        ComposerBody(
                          composer: composer,
                          details: details,
                          merchant: merchant,
                          notes: notes,
                          suggest: suggest,
                          onMore: () => setState(() => details = true),
                        ),
                        const SizedBox(height: FreevaSpace.s4),
                      ],
                    ),
                  ),
                  if (keypad)
                    AmountKeypad(
                      filled: false,
                      keyHeight: composer.transfer ? 50 : 54,
                      onDigits: composer.typeKeys,
                      onDelete: composer.backspace,
                    ),
                  ComposerError(composer: composer),
                  SizedBox(height: composer.transfer ? FreevaSpace.s4 : 18),
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
