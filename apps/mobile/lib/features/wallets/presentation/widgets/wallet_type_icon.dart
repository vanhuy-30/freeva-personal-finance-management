import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../domain/wallet.dart';

IconData walletTypeIconData(WalletType type) => switch (type) {
  WalletType.bank => LucideIcons.landmark,
  WalletType.cash => LucideIcons.banknote,
  WalletType.ewallet => LucideIcons.smartphone,
  WalletType.credit => LucideIcons.creditCard,
};

/// Two-tone tile per wallet type: bank blue, cash cyan, e-wallet violet,
/// credit card subtle + ink. [muted] greys it out (hidden wallets).
class WalletTypeIcon extends StatelessWidget {
  const WalletTypeIcon({
    required this.type,
    this.size = 40,
    this.muted = false,
    super.key,
  });

  final WalletType type;
  final double size;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg) = muted
        ? (c.bgSubtle, c.textSecondary)
        : switch (type) {
            WalletType.bank => (c.tintBlue, c.tintBlueFg),
            WalletType.cash => (c.tintCyan, c.tintCyanFg),
            WalletType.ewallet => (c.tintViolet, c.tintVioletFg),
            WalletType.credit => (c.bgSubtle, c.textPrimary),
          };
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(
            size >= 40 ? FreevaRadius.sm : 10,
          ),
        ),
        child: Icon(
          walletTypeIconData(type),
          size: size >= 40 ? FreevaSize.iconInline : 16,
          color: fg,
        ),
      ),
    );
  }
}
