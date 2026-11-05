import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';

/// Action card of the expense detail sheet (board `TxDetail3`): "Ghi hoàn
/// tiền · Đổi trả, hoàn một phần" (green tile) and "Chuyển thành trả góp ·
/// Chia nhiều kỳ trên thẻ" (violet tile), 56 rows with a hairline between.
/// A null callback drops its row.
class ExpenseActionCard extends StatelessWidget {
  const ExpenseActionCard({this.onRefund, this.onInstallment, super.key})
    : assert(onRefund != null || onInstallment != null);

  final VoidCallback? onRefund;
  final VoidCallback? onInstallment;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final refund = onRefund;
    final installment = onInstallment;
    return FreevaCard(
      list: true,
      padding: const EdgeInsets.symmetric(horizontal: FreevaSpace.s4),
      child: Column(
        children: [
          if (refund != null)
            _ActionRow(
              icon: LucideIcons.rotateCcw,
              background: c.tintGreen,
              foreground: c.tintGreenFg,
              title: s.refundAction,
              subtitle: s.refundActionSub,
              onTap: refund,
            ),
          if (refund != null && installment != null)
            Divider(height: 1, color: c.listDivider),
          if (installment != null)
            _ActionRow(
              icon: LucideIcons.layers,
              background: c.tintViolet,
              foreground: c.tintVioletFg,
              title: s.installmentAction,
              subtitle: s.installmentActionSub,
              onTap: installment,
            ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      container: true,
      excludeSemantics: true,
      label: '$title, $subtitle',
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: FreevaSpace.s2),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(FreevaRadius.xs),
                  ),
                  child: Icon(icon, size: 17, color: foreground),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FreevaTypography.body.copyWith(
                          fontWeight: FontWeight.w500,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
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
    );
  }
}
