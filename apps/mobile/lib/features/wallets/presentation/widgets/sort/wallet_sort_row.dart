import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

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
    // Board: 40 arrow buttons 12 apart, 12 after the name, 8 from the edge.
    // Each keeps a 44 touch box, so the gaps around them are 2 smaller.
    Widget arrow(IconData icon, String label, VoidCallback? onPressed) =>
        IconButton(
          tooltip: label,
          onPressed: onPressed,
          icon: Icon(icon, size: FreevaSize.iconSm),
          color: c.textOnWash,
          disabledColor: c.borderStrong,
          constraints: const BoxConstraints.tightFor(
            width: FreevaSize.touch,
            height: FreevaSize.touch,
          ),
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          padding: EdgeInsets.zero,
        );
    return Transform.translate(
      offset: Offset(lifted ? 6 : 0, 0),
      child: Container(
        height: 64,
        padding: const EdgeInsets.only(left: FreevaSpace.s3, right: 6),
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(FreevaRadius.md),
          border: lifted
              ? Border.all(color: c.actionPrimary, width: FreevaBorder.selected)
              : null,
          boxShadow: lifted ? FreevaElevation.drag : FreevaElevation.tile,
        ),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Semantics(
                excludeSemantics: true,
                child: SizedBox(
                  width: FreevaSize.iconSm,
                  height: 64,
                  child: Center(
                    child: _Grip(color: lifted ? c.actionPrimary : c.textMuted),
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
            const SizedBox(width: 10),
            arrow(LucideIcons.chevronUp, s.walletMoveUpNamed(name), onUp),
            const SizedBox(width: FreevaSpace.s2),
            arrow(LucideIcons.chevronDown, s.walletMoveDownNamed(name), onDown),
          ],
        ),
      ),
    );
  }
}

/// Six-dot drag handle, 18 square (board: dots r1.5 on the 24 grid).
class _Grip extends StatelessWidget {
  const _Grip({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size.square(FreevaSize.iconSm),
    painter: _GripPainter(color),
  );
}

class _GripPainter extends CustomPainter {
  const _GripPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final paint = Paint()..color = color;
    for (final x in const [9.0, 15.0]) {
      for (final y in const [6.0, 12.0, 18.0]) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_GripPainter old) => old.color != color;
}
