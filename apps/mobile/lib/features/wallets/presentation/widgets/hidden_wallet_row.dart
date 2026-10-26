import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/money_display.dart';
import '../../domain/wallet.dart';
import 'wallet_labels.dart';
import 'wallet_type_icon.dart';

/// A hidden wallet: muted icon, name, "Tiền mặt · 0 ₫", "Khôi phục".
class HiddenWalletRow extends StatelessWidget {
  const HiddenWalletRow({
    required this.wallet,
    required this.minorDigits,
    required this.hidden,
    required this.busy,
    required this.onRestore,
    super.key,
  });

  final Wallet wallet;
  final int minorDigits;
  final bool hidden;
  final bool busy;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final currency = wallet.draft.currency;
    final balance = hidden
        ? '••••••'
        : formatMoneyText(wallet.balance, minorDigits, locale);
    final name = wallet.draft.name;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FreevaSpace.s3),
      child: Row(
        children: [
          WalletTypeIcon(type: wallet.draft.type, muted: true),
          const SizedBox(width: FreevaSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FreevaTypography.body.copyWith(
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                  ),
                ),
                Text(
                  '${walletTypeLabel(s, wallet.draft.type)} · $balance '
                  '${MoneyDisplay.symbolFor(currency)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FreevaTypography.label.copyWith(
                    fontWeight: FontWeight.w400,
                    color: c.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: FreevaSpace.s2),
          Semantics(
            container: true,
            button: true,
            label: s.walletRestoreNamed(name),
            excludeSemantics: true,
            child: OutlinedButton.icon(
              onPressed: busy ? null : onRestore,
              icon: const Icon(LucideIcons.rotateCcw, size: 14),
              label: Text(s.walletRestoreShort),
              style: OutlinedButton.styleFrom(
                foregroundColor: c.actionPrimary,
                side: BorderSide(color: c.borderDefault),
                minimumSize: const Size(0, FreevaSize.touch),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: const StadiumBorder(),
                textStyle: FreevaTypography.bodyS.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
