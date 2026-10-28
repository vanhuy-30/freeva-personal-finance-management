import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../../core/widgets/progress_bar.dart';
import '../../domain/credit_card_status.dart';
import '../../domain/wallet.dart';
import 'credit_level_color.dart';
import 'wallet_labels.dart';
import 'wallet_type_icon.dart';

/// One wallet in "Ví của tôi": type icon, name, type, balance. A credit card
/// adds "đến hạn dd/MM" and a 6-high limit bar.
class WalletListRow extends StatelessWidget {
  const WalletListRow({
    required this.wallet,
    required this.minorDigits,
    required this.today,
    required this.hidden,
    required this.onTap,
    super.key,
  });

  final Wallet wallet;
  final int minorDigits;
  final DateTime today;

  /// "Ẩn số dư" is on.
  final bool hidden;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final type = wallet.draft.type;
    final card = type == WalletType.credit
        ? CreditCardStatus.of(wallet, today)
        : null;
    final due = card?.nextDue;
    final locale = Localizations.localeOf(context).toString();
    final subtitle = [
      walletTypeLabel(s, type),
      if (due != null) s.walletDueOn(DateFormat('dd/MM', locale).format(due)),
    ].join(' · ');
    return Semantics(
      container: true,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: FreevaSpace.s3),
          child: Row(
            crossAxisAlignment: card == null
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              WalletTypeIcon(type: type),
              const SizedBox(width: FreevaSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      wallet.draft.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FreevaTypography.body.copyWith(
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: FreevaTypography.label.copyWith(
                        fontWeight: FontWeight.w400,
                        height: 1.2,
                        color: c.textSecondary,
                      ),
                    ),
                    if (card != null && card.limit != null) ...[
                      const SizedBox(height: FreevaSpace.s2),
                      FreevaProgressBar(
                        value: card.ratio,
                        height: 6,
                        color: creditLevelColor(context, card.level),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: FreevaSpace.s3),
              MoneyDisplay(
                minor: wallet.balance,
                currency: wallet.draft.currency,
                minorDigits: minorDigits,
                style: FreevaTypography.titleM,
                showCurrency: false,
                hidden: hidden,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
