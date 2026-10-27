import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../categories/presentation/widgets/category_badge.dart';
import '../../domain/category_detail.dart';
import '../../domain/report_breakdown.dart';

/// Icon tile, the slice total and "38% tổng chi · 42 giao dịch".
class CategoryHeader extends StatelessWidget {
  const CategoryHeader({
    required this.args,
    required this.detail,
    required this.count,
    this.iconToken,
    super.key,
  });

  final CategoryDetailArgs args;
  final CategoryDetail detail;

  /// Known once the transaction list has loaded.
  final int? count;
  final String? iconToken;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final share = args.kind == BreakdownKind.expense
        ? s.reportShareExpense('${detail.percent}')
        : s.reportShareIncome('${detail.percent}');
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: c.tintBlue,
              borderRadius: BorderRadius.circular(FreevaRadius.md),
            ),
            child: ExcludeSemantics(
              child: Icon(
                categoryIcon(iconToken),
                size: FreevaSize.icon,
                color: c.tintBlueFg,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MoneyDisplay(
                  minor: detail.total,
                  currency: args.currency,
                  minorDigits: args.digits,
                  style: FreevaTypography.moneyL,
                ),
                Text(
                  count == null ? share : s.reportShareCount(share, count!),
                  style: FreevaTypography.bodyS.copyWith(
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
