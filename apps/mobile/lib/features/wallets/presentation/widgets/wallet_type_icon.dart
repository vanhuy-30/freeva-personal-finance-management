import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../domain/wallet.dart';
import 'wallet_type_glyph.dart';

/// Two-tone tile per wallet type: bank blue, cash cyan, e-wallet violet,
/// credit card subtle + ink. [muted] greys it out (hidden wallets).
class WalletTypeIcon extends StatelessWidget {
  const WalletTypeIcon({
    required this.type,
    this.size = 40,
    this.iconSize,
    this.muted = false,
    super.key,
  });

  final WalletType type;
  final double size;

  /// Glyph size; 20 on a 40 tile, 16 on smaller ones by default.
  final double? iconSize;
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
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(
            size >= 40 ? FreevaRadius.sm : FreevaRadius.xs,
          ),
        ),
        child: WalletTypeGlyph(
          type: type,
          size: iconSize ?? (size >= 40 ? FreevaSize.iconInline : 16),
          color: fg,
        ),
      ),
    );
  }
}
