import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../categories/presentation/widgets/category_badge.dart';
import '../../domain/category_detail.dart';
import '../../domain/report_breakdown.dart';
import 'report_period_labels.dart';

/// Icon tile, the period, the slice total and "38% tổng chi · 42 giao dịch".
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
    final period = periodTitle(
      s,
      args.report.period,
      Localizations.localeOf(context).toString(),
    );
    final share = args.kind == BreakdownKind.expense
        ? s.reportShareExpense('${detail.percent}')
        : s.reportShareIncome('${detail.percent}');
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: c.bgSubtle,
            borderRadius: BorderRadius.circular(FreevaRadius.sm),
          ),
          child: ExcludeSemantics(
            child: Icon(
              categoryIcon(iconToken),
              size: FreevaSize.iconInline,
              color: c.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: FreevaSpace.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                period.title,
                style: FreevaTypography.label.copyWith(color: c.textSecondary),
              ),
              MoneyDisplay(
                minor: detail.total,
                currency: args.currency,
                minorDigits: args.digits,
                style: FreevaTypography.moneyL,
              ),
              Text(
                count == null ? share : s.reportShareCount(share, count!),
                style: FreevaTypography.bodyS.copyWith(color: c.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
