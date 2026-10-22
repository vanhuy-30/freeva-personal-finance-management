import 'package:flutter/material.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../viewmodels/transaction_composer.dart';
import '../transaction_labels.dart';
import 'details_fields.dart';
import 'quick_fields.dart';
import 'transfer_fields.dart';

/// What sits under the amount: transfer card, quick fields, or details.
class ComposerBody extends StatelessWidget {
  const ComposerBody({
    required this.composer,
    required this.details,
    required this.merchant,
    required this.notes,
    required this.onMore,
    super.key,
  });

  final TransactionComposer composer;
  final bool details;
  final TextEditingController merchant;
  final TextEditingController notes;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    if (details) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (composer.transfer) ...[
            TransferFields(composer: composer),
            const SizedBox(height: FreevaSpace.s4),
          ],
          DetailsFields(composer: composer, merchant: merchant, notes: notes),
        ],
      );
    }
    if (composer.transfer) return TransferFields(composer: composer);
    return QuickFields(composer: composer, onMore: onMore);
  }
}

/// Why saving did not work, in plain words.
class ComposerError extends StatelessWidget {
  const ComposerError({required this.composer, super.key});

  final TransactionComposer composer;

  @override
  Widget build(BuildContext context) {
    if (!composer.invalid) return const SizedBox.shrink();
    final s = S.of(context);
    final failure = composer.model.failure;
    final text = composer.amount <= BigInt.zero
        ? s.txAmountMissing
        : composer.transfer && composer.destination == null
        ? s.txPickDestination
        : composer.cross && composer.received == null
        ? s.txRateInvalid
        : failure != null
        ? transactionError(s, failure)
        : s.transactionInvalid;
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: FreevaSpace.s2),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: FreevaTypography.bodyS.copyWith(
            color: context.colors.statusDanger,
          ),
        ),
      ),
    );
  }
}
