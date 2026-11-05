import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';

/// Action card of the expense detail sheet (board `TxDetail3`): green 32
/// tile with the refund glyph, "Ghi hoàn tiền" + "Đổi trả, hoàn một phần",
/// chevron. The "Chuyển thành trả góp" row comes with `MOB-P3-009`.
class RefundActionCard extends StatelessWidget {
  const RefundActionCard({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return FreevaCard(
      list: true,
      padding: EdgeInsets.zero,
      child: Semantics(
        button: true,
        container: true,
        excludeSemantics: true,
        label: '${s.refundAction}, ${s.refundActionSub}',
        onTap: onTap,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FreevaSpace.s4,
                vertical: FreevaSpace.s2,
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c.tintGreen,
                      borderRadius: BorderRadius.circular(FreevaRadius.xs),
                    ),
                    child: Icon(
                      LucideIcons.rotateCcw,
                      size: 17,
                      color: c.tintGreenFg,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.refundAction,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FreevaTypography.body.copyWith(
                            fontWeight: FontWeight.w500,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.refundActionSub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FreevaTypography.label.copyWith(
                            fontWeight: FontWeight.w400,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: c.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
