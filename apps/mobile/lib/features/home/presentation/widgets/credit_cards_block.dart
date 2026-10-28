import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../domain/overview.dart';
import 'credit_card_row.dart';

/// Credit cards: name + due chip, limit bar, "Đã dùng … · Hạn mức …".
/// Limits and used amounts are not balances, so hiding balances keeps them.
/// Tapping opens the wallet list.
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
      onTap: () => context.push('/wallets'),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.homeCreditTitle,
                  style: FreevaTypography.titleM.copyWith(
                    height: 1.2,
                    color: c.textPrimary,
                  ),
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: FreevaSize.iconChip,
                color: c.textSecondary,
              ),
            ],
          ),
          for (final (i, card) in cards.indexed) ...[
            const SizedBox(height: FreevaSpace.s3),
            if (i > 0) ...[
              Divider(height: 1, thickness: 1, color: c.listDivider),
              const SizedBox(height: 14),
            ],
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
