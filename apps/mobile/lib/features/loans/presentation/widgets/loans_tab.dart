import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/error_retry.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../../core/widgets/progress_bar.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../debts/presentation/widgets/debt_parts.dart';
import '../../../debts/presentation/widgets/debts_empty.dart';
import '../../../goals/presentation/widgets/goal_mini_tile.dart';
import '../../domain/loan.dart';
import '../viewmodels/loan_view_model.dart';
import 'loan_labels.dart';

/// Khoản vay (LoanList): what is still owed, principal paid, what falls due
/// this month, then one card per loan.
class LoansTab extends StatelessWidget {
  const LoansTab({required this.model, super.key});

  final LoanViewModel model;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (!model.loaded && model.failure != null) {
      return ErrorRetry(
        title: s.loansLoadError,
        message: s.homeErrorBody,
        onRetry: model.load,
      );
    }
    if (!model.loaded) return const SkeletonRows(count: 3);
    if (model.isEmpty) {
      return DebtsEmpty(
        icon: LucideIcons.landmark,
        title: s.loansEmptyTitle,
        body: s.loansEmptyBody,
        action: s.loansAdd,
        onAction: () => context.push('/me/debts/loans/new'),
      );
    }
    final children = <Widget>[
      _Summary(model: model),
      for (final loan in model.loans)
        LoanCard(
          loan: loan,
          digits: model.digitsOf(loan.currencyCode),
          today: model.today,
          onTap: () => context.push('/me/debts/loans/${loan.id}'),
        ),
    ];
    return RefreshIndicator(
      onRefresh: model.load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.model});

  final LoanViewModel model;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final currency = model.totalCurrency;
    final digits = model.digitsOf(currency);
    final total = model.total;
    final principal = total?.principalMinor ?? BigInt.zero;
    final paid = total?.paidMinor ?? BigInt.zero;
    final progress = principal <= BigInt.zero
        ? 0.0
        : (paid * BigInt.from(10000) ~/ principal).toInt() / 10000;
    return FreevaCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.loansOwed,
            style: FreevaTypography.label.copyWith(
              fontWeight: FontWeight.w400,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          MoneyDisplay(
            minor: total?.outstandingMinor ?? BigInt.zero,
            currency: currency,
            minorDigits: digits,
            style: FreevaTypography.moneyL.copyWith(
              fontSize: 30,
              height: 34 / 30,
              letterSpacing: -0.9,
            ),
            currencySize: 15,
            currencyColor: c.textOnWash,
          ),
          const SizedBox(height: 12),
          FreevaProgressBar(
            value: progress,
            color: c.actionPrimary,
            semanticsLabel: s.loansPaidPrincipal,
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: GoalMiniTile(
                    label: s.loansPaidPrincipal,
                    value: formatMoneyText(paid, digits, locale),
                  ),
                ),
                const SizedBox(width: FreevaSpace.s2),
                Expanded(
                  child: GoalMiniTile(
                    label: s.loansDueThisMonth,
                    value: formatMoneyText(
                      total?.dueThisMonthMinor ?? BigInt.zero,
                      digits,
                      locale,
                    ),
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

/// One loan: kind tile, name, "12%/năm · kỳ tới 25/10", still owed, due
/// tag and a 6 high progress bar.
class LoanCard extends StatelessWidget {
  const LoanCard({
    required this.loan,
    required this.digits,
    required this.today,
    required this.onTap,
    super.key,
  });

  final Loan loan;
  final int digits;
  final String today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final next = loan.nextDueDate;
    final subtitle = loan.paidOff
        ? s.loanPaidOff
        : [
            s.loanRateYear(loanRate(context, loan.interestRateBps)),
            if (next != null) s.loanNextOn(debtDay(next)),
          ].join(' · ');
    final tag = loan.paidOff ? null : dueTag(context, today, next);
    return Semantics(
      container: true,
      button: true,
      child: FreevaCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FreevaRadius.xl),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    LoanKindTile(kind: loan.kind),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loan.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FreevaTypography.body.copyWith(
                              fontWeight: FontWeight.w600,
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
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatMoneyText(
                            loan.outstandingMinor,
                            digits,
                            locale,
                          ),
                          maxLines: 1,
                          style: FreevaTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        if (tag != null) ...[const SizedBox(height: 4), tag],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FreevaProgressBar(
                  value: loan.progress,
                  color: c.actionPrimary,
                  height: 6,
                  semanticsLabel: loan.name,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
