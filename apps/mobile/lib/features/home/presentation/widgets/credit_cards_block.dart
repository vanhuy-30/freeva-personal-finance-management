import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../domain/overview.dart';
import 'credit_card_row.dart';

/// Credit cards: name + due chip, limit bar, "Đã dùng … / Hạn mức …".
/// Limits and used amounts are not balances, so hiding balances keeps them.
class CreditCardsBlock extends StatelessWidget {
  const CreditCardsBlock({
    required this.cards,
    required this.today,
    required this.digitsOf,
    super.key,
  });

  final List<CreditCardStatus> cards;
  final DateTime today;
  final int Function(String) digitsOf;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return FreevaCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.homeCreditTitle,
            style: FreevaTypography.titleM.copyWith(color: c.textPrimary),
          ),
          for (final card in cards) ...[
            const SizedBox(height: FreevaSpace.s4),
            CreditCardRow(
              card: card,
              today: today,
              digits: digitsOf(card.wallet.draft.currency),
            ),
          ],
        ],
      ),
    );
  }
}
