import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../domain/wallet.dart';
import '../wallet_type_icon.dart';

/// 64-high white row in "Sắp xếp ví": grip, icon, name, up / down arrows.
/// [lifted] is the copy that follows the finger.
class WalletSortRow extends StatelessWidget {
  const WalletSortRow({
    required this.wallet,
    required this.index,
    required this.onUp,
    required this.onDown,
    this.lifted = false,
    super.key,
  });

  final Wallet wallet;

  /// Position, for the drag listener.
  final int index;

  /// Null at the top / bottom of the list.
  final VoidCallback? onUp;
  final VoidCallback? onDown;
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final name = wallet.draft.name;
    Widget arrow(IconData icon, String label, VoidCallback? onPressed) =>
        IconButton(
          tooltip: label,
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          color: c.textOnWash,
          disabledColor: c.textDisabled,
          constraints: const BoxConstraints.tightFor(
            width: FreevaSize.buttonXs,
            height: FreevaSize.buttonXs,
          ),
          padding: EdgeInsets.zero,
        );
    return Container(
      height: 64,
      padding: const EdgeInsets.only(
        left: FreevaSpace.s3,
        right: FreevaSpace.s2,
      ),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(FreevaRadius.md),
        border: lifted
            ? Border.all(color: c.actionPrimary, width: FreevaBorder.selected)
            : null,
        boxShadow: lifted ? FreevaElevation.s2 : FreevaElevation.s1,
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: Semantics(
              excludeSemantics: true,
              child: SizedBox(
                width: 24,
                height: 64,
                child: Icon(
                  LucideIcons.gripVertical,
                  size: 18,
                  color: lifted ? c.actionPrimary : c.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: FreevaSpace.s3),
          WalletTypeIcon(type: wallet.draft.type),
          const SizedBox(width: FreevaSpace.s3),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: FreevaTypography.body.copyWith(
                fontWeight: FontWeight.w500,
                color: c.textPrimary,
              ),
            ),
          ),
          arrow(LucideIcons.chevronUp, s.walletMoveUpNamed(name), onUp),
          arrow(LucideIcons.chevronDown, s.walletMoveDownNamed(name), onDown),
        ],
      ),
    );
  }
}
