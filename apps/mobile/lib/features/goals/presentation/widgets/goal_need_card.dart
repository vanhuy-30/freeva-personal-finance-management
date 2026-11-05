import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';

/// Blue note under the new-goal form: "Cần góp 8.000.000 mỗi tháng, khoảng
/// 32% thu nhập." with the amount in bold. The share is dropped without income.
class GoalNeedCard extends StatelessWidget {
  const GoalNeedCard({required this.amount, this.percent, super.key});

  final String amount;
  final int? percent;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final text = percent == null
        ? s.goalNeedLine(amount)
        : s.goalNeedLineShare(amount, '$percent');
    final at = text.indexOf(amount);
    final style = FreevaTypography.bodyM.copyWith(color: c.textPrimary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.tintBlue,
        borderRadius: BorderRadius.circular(FreevaRadius.md),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.info, size: 18, color: c.tintBlueFg),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: style,
                children: at < 0
                    ? [TextSpan(text: text)]
                    : [
                        TextSpan(text: text.substring(0, at)),
                        TextSpan(
                          text: amount,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: text.substring(at + amount.length)),
                      ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
