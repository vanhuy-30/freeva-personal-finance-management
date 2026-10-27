import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../../../core/widgets/freeva_card.dart';
import '../../viewmodels/transaction_composer.dart';
import 'composer_pickers.dart';
import 'rate_card.dart';
import 'wallet_row.dart';

/// C2.5: "Từ" / "Đến" in one card with the swap button on the divider, and
/// the rate card when the two wallets use different currencies.
class TransferFields extends StatelessWidget {
  const TransferFields({required this.composer, super.key});

  final TransactionComposer composer;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final pick = ComposerPickers(context, composer);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            FreevaCard(
              list: true,
              padding: const EdgeInsets.symmetric(horizontal: FreevaSpace.s4),
              child: Column(
                children: [
                  WalletRow(
                    label: s.txDetailFrom,
                    wallet: composer.source,
                    placeholder: s.txPickWallet,
                    iconBg: c.tintBlue,
                    iconFg: c.tintBlueFg,
                    onTap: pick.wallet,
                  ),
                  Divider(height: 1, color: c.listDivider),
                  WalletRow(
                    label: s.txDetailTo,
                    wallet: composer.destination,
                    placeholder: s.txPickWallet,
                    iconBg: c.tintGreen,
                    iconFg: c.tintGreenFg,
                    onTap: () => pick.wallet(counter: true),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 12,
              top: 40,
              child: Tooltip(
                message: s.txSwap,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: FreevaElevation.swap,
                  ),
                  child: Material(
                    color: c.bgSurface,
                    shape: CircleBorder(
                      side: BorderSide(color: c.borderDefault),
                    ),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: composer.destination == null
                          ? null
                          : composer.swap,
                      child: SizedBox.square(
                        dimension: 40,
                        child: Icon(
                          LucideIcons.arrowUpDown,
                          size: FreevaSize.iconSm,
                          color: c.textPrimary,
                          semanticLabel: s.txSwap,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (composer.cross) ...[
          const SizedBox(height: FreevaSpace.s4),
          RateCard(composer: composer, onEdit: pick.rate),
        ],
      ],
    );
  }
}
