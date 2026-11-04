import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../debts/presentation/widgets/debt_parts.dart';
import '../../../recurring/presentation/widgets/rec_tag.dart';
import '../../domain/loan.dart';

/// One period of the plan: date (+ "Kỳ tới"), "Gốc … · lãi …", payment.
/// 58 high.
class LoanScheduleRowTile extends StatelessWidget {
  const LoanScheduleRowTile({
    required this.row,
    required this.digits,
    this.next = false,
    super.key,
  });

  final LoanScheduleRow row;
  final int digits;
  final bool next;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    String money(BigInt v) => formatMoneyText(v, digits, locale);
    final due = row.dueDate;
    return MergeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 58),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            due == null
                                ? s.loanPeriod(row.index)
                                : debtDay(due),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FreevaTypography.body.copyWith(
                              fontWeight: FontWeight.w500,
                              color: c.textPrimary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                        if (next) ...[
                          const SizedBox(width: 8),
                          RecTag(
                            s.loanNextTag,
                            background: c.tintBlue,
                            color: c.tintBlueFg,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.loanSplit(
                        money(row.principalMinor),
                        money(row.interestMinor),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FreevaTypography.label.copyWith(
                        fontWeight: FontWeight.w400,
                        color: c.textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                money(row.paymentMinor),
                maxLines: 1,
                style: FreevaTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
