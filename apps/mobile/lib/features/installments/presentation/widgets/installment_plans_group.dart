import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../debts/presentation/widgets/debt_parts.dart';
import '../../../recurring/presentation/widgets/recurring_labels.dart';
import '../../../transactions/presentation/widgets/transaction_naming.dart';
import '../../domain/card_installment.dart';
import 'installment_parts.dart';

/// "TRẢ GÓP" on the card detail (board `WCredit3`): one row per active plan,
/// violet 36 tile, name, "Kỳ 2/6 · 25/12 · 4.000.000", opens the schedule.
class InstallmentPlansGroup extends StatelessWidget {
  const InstallmentPlansGroup({
    required this.plans,
    required this.naming,
    required this.digitsOf,
    required this.onOpen,
    super.key,
  });

  final List<CardInstallment> plans;
  final TransactionNaming naming;
  final int Function(String currency) digitsOf;
  final ValueChanged<CardInstallment> onOpen;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    return DebtGroup(
      label: s.installmentTitle,
      children: [
        for (final plan in plans)
          Semantics(
            button: true,
            container: true,
            child: InkWell(
              onTap: () => onOpen(plan),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 54),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.tintViolet,
                        ),
                        child: Icon(
                          installmentIcon(naming, plan),
                          size: 17,
                          color: c.tintVioletFg,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              installmentName(s, naming, plan),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: FreevaTypography.body.copyWith(
                                fontWeight: FontWeight.w500,
                                color: c.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _sub(s, plan, locale),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: FreevaTypography.label.copyWith(
                                fontWeight: FontWeight.w400,
                                color: c.textSecondary,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
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
      ],
    );
  }

  String _sub(S s, CardInstallment plan, String locale) {
    final index = plan.nextIndex;
    final on = plan.nextDueOn;
    final amount = plan.nextAmountMinor;
    if (index == null || on == null || amount == null) {
      return s.installmentClosedTag;
    }
    return s.installmentRowSub(
      index,
      plan.installmentCount,
      dayMonth(on),
      formatMoneyText(amount, digitsOf(plan.currencyCode), locale),
    );
  }
}
