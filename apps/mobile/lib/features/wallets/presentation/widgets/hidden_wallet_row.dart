import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

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
    final restore = busy ? null : onRestore;
    // Row is 64 like the board: the 44 touch box of the 36 pill sets the
    // height, so the vertical padding is 10 (40 icon stays 12 from the edge).
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
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
                    height: 1.2,
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
                    height: 1.2,
                    color: c.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: FreevaSpace.s3),
          Semantics(
            container: true,
            button: true,
            enabled: restore != null,
            label: s.walletRestoreNamed(name),
            onTap: restore,
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: restore,
              child: SizedBox(
                height: FreevaSize.touch,
                child: Center(
                  child: OutlinedButton(
                    onPressed: restore,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.actionPrimary,
                      backgroundColor: c.bgSurface,
                      side: BorderSide(color: c.borderDefault),
                      minimumSize: const Size(0, FreevaSize.buttonCompact),
                      fixedSize: const Size.fromHeight(
                        FreevaSize.buttonCompact,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: const StadiumBorder(),
                      textStyle: FreevaTypography.bodyS.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.rotateCcw,
                          size: FreevaSize.iconXs,
                        ),
                        const SizedBox(width: 6),
                        Text(s.walletRestoreShort),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
