import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../recurring/presentation/widgets/rec_tag.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/presentation/widgets/transaction_naming.dart';
import '../../domain/card_installment.dart';

/// `dd/MM/yyyy` of a `yyyy-MM-dd` day.
String installmentDay(String day) =>
    '${day.substring(8, 10)}/${day.substring(5, 7)}/${day.substring(0, 4)}';

/// A plan is named like its purchase: merchant, else category.
String installmentName(S s, TransactionNaming naming, CardInstallment plan) {
  final merchant = plan.purchaseMerchant?.trim();
  if (merchant != null && merchant.isNotEmpty) return merchant;
  return naming.categoryName(plan.purchaseCategoryId) ?? s.homeUncategorized;
}

IconData installmentIcon(TransactionNaming naming, CardInstallment plan) =>
    naming.icon(TransactionType.expense, plan.purchaseCategoryId);

/// One period (boards `InstAdd`, `InstDetail`): 48 high, 16 lead, date 15
/// with "Kỳ tới", amount 15/600; a period already past or closed is 14 and
/// muted, a past one with a green tick in the lead.
class InstallmentPeriodTile extends StatelessWidget {
  const InstallmentPeriodTile({
    required this.period,
    required this.digits,
    this.next = false,
    super.key,
  });

  final InstallmentPeriod period;
  final int digits;
  final bool next;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final muted = period.state != InstallmentPeriodState.upcoming;
    const tabular = [FontFeature.tabularFigures()];
    final style = muted
        ? FreevaTypography.bodyM.copyWith(
            color: c.textDisabled,
            fontFeatures: tabular,
          )
        : FreevaTypography.body.copyWith(
            color: c.textPrimary,
            fontFeatures: tabular,
          );
    return MergeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                child: period.state == InstallmentPeriodState.past
                    ? Icon(LucideIcons.check, size: 16, color: c.statusSuccess)
                    : null,
              ),
              const SizedBox(width: 12),
              // Date and "Kỳ tới" wrap instead of cutting the date.
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(installmentDay(period.dueOn), style: style),
                    if (next)
                      RecTag(
                        s.loanNextTag,
                        background: c.tintBlue,
                        color: c.tintBlueFg,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                formatMoneyText(period.amountMinor, digits, locale),
                maxLines: 1,
                style: muted
                    ? style
                    : style.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// White list card (radius 20, 4 top/bottom) with hairlines between rows.
class InstallmentGroup extends StatelessWidget {
  const InstallmentGroup({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return FreevaCard(
      list: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: c.listDivider),
            children[i],
          ],
        ],
      ),
    );
  }
}
