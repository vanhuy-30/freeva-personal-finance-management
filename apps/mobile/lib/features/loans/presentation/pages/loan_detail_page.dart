import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/error_retry.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/freeva_icon_button.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../../core/widgets/progress_bar.dart';
import '../../../debts/presentation/widgets/debt_parts.dart';
import '../../domain/loan.dart';
import '../viewmodels/loan_view_model.dart';
import '../widgets/loan_labels.dart';
import '../widgets/loan_pay_sheet.dart';
import '../widgets/loan_schedule_row.dart';

/// One loan (LoanDetail): still owed of the amount borrowed, the next
/// period with "Ghi lần trả", how interest is counted and three periods of
/// the plan.
class LoanDetailPage extends StatefulWidget {
  const LoanDetailPage({required this.loanId, super.key});

  final String loanId;

  @override
  State<LoanDetailPage> createState() => _LoanDetailPageState();
}

class _LoanDetailPageState extends State<LoanDetailPage> {
  late final LoanViewModel model = getIt<LoanViewModel>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!model.loaded) await model.load();
      final loan = model.byId(widget.loanId);
      if (loan != null) await model.loadSchedule(loan);
    });
  }

  Future<void> _pay(Loan loan, LoanScheduleRow? next) async {
    final done = await showLoanPaySheet(context, model, loan, next);
    if (done == true) {
      final fresh = model.byId(loan.id);
      if (fresh != null) await model.loadSchedule(fresh);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final loan = model.byId(widget.loanId);
        if (loan == null) {
          return Scaffold(
            appBar: FreevaTopBar(
              title: s.meDebts,
              onLeading: () => context.popOrGo('/me/debts?tab=loans'),
            ),
            body: model.loaded || model.failure != null
                ? ErrorRetry(
                    title: s.loansLoadError,
                    message: s.homeErrorBody,
                    onRetry: model.load,
                  )
                : const SizedBox.shrink(),
          );
        }
        final schedule = model.scheduleOf(loan.id);
        if (schedule == null && model.failure == null && !model.loading) {
          // A payment or edit dropped the cached plan; fetch it again.
          Future.microtask(() => model.loadSchedule(loan));
        }
        return Scaffold(
          appBar: FreevaTopBar(
            title: loan.name,
            onLeading: () => context.popOrGo('/me/debts?tab=loans'),
            action: FreevaIconButton(
              icon: LucideIcons.penLine,
              iconSize: FreevaSize.iconSm,
              label: s.loanEdit,
              onPressed: () => context.push('/me/debts/loans/${loan.id}/edit'),
            ),
          ),
          body: _body(context, s, loan, schedule),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    S s,
    Loan loan,
    List<LoanScheduleRow>? schedule,
  ) {
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final digits = model.digitsOf(loan.currencyCode);
    String money(BigInt value) => formatMoneyText(value, digits, locale);
    final next = schedule?.firstOrNull;
    final lastDue = schedule?.lastOrNull?.dueDate;
    final percent = '${loan.percentBps ~/ 100}';
    final progressLine = [
      s.loanPaidPercent(percent),
      if (!loan.paidOff && lastDue != null) s.loanDoneBy(monthYear(lastDue)),
    ].join(' · ');
    final children = <Widget>[
      FreevaCard(
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
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  MoneyDisplay(
                    minor: loan.outstandingMinor,
                    currency: loan.currencyCode,
                    minorDigits: digits,
                    style: FreevaTypography.moneyL.copyWith(
                      fontSize: 30,
                      height: 34 / 30,
                      letterSpacing: -0.9,
                    ),
                    currencySize: 15,
                    currencyColor: c.textOnWash,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.debtOfPrincipal(money(loan.principalMinor)),
                    maxLines: 1,
                    style: FreevaTypography.bodyM.copyWith(
                      color: c.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FreevaProgressBar(
              value: loan.progress,
              color: c.actionPrimary,
              height: 10,
              semanticsLabel: loan.name,
            ),
            const SizedBox(height: 12),
            Text(
              progressLine,
              style: FreevaTypography.label.copyWith(
                fontWeight: FontWeight.w400,
                color: c.textSecondary,
              ),
            ),
          ],
        ),
      ),
      if (!loan.paidOff)
        _NextCard(
          loan: loan,
          next: next,
          money: money,
          onPay: () => _pay(loan, next),
        ),
      _HowCard(
        text: s.loanHowText(
          loanRate(context, loan.interestRateBps),
          loanFrequencyLabel(s, loan.frequency).toLowerCase(),
        ),
        onEdit: () => context.push('/me/debts/loans/${loan.id}/edit'),
      ),
      if (schedule != null && schedule.isNotEmpty) ...[
        DebtGroup(
          label: s.loanSchedule,
          children: [
            for (final row in schedule.take(3))
              LoanScheduleRowTile(
                row: row,
                digits: digits,
                next: row.index == 1,
              ),
          ],
        ),
      ],
    ];
    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.screenMargin,
        FreevaSpace.s2,
        context.screenMargin,
        28,
      ),
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          children[i],
        ],
        if (schedule != null && schedule.length > 3)
          Center(
            child: TextButton(
              onPressed: () =>
                  context.push('/me/debts/loans/${loan.id}/schedule'),
              child: Text(
                s.loanFullSchedule,
                style: FreevaTypography.bodyM.copyWith(
                  fontWeight: FontWeight.w600,
                  color: c.textLink,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NextCard extends StatelessWidget {
  const _NextCard({
    required this.loan,
    required this.next,
    required this.money,
    required this.onPay,
  });

  final Loan loan;
  final LoanScheduleRow? next;
  final String Function(BigInt) money;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final row = next;
    final due = row?.dueDate ?? loan.nextDueDate;
    final title = due == null
        ? s.loanNextPeriod
        : s.loanNextOnTitle(debtDay(due));
    final subtitle = row == null
        ? s.loanInterestOnly(money(loan.periodInterestMinor))
        : s.loanSplit(money(row.principalMinor), money(row.interestMinor));
    return FreevaCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MergeSemantics(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c.statusWarningBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.calendarClock,
                    size: 19,
                    color: c.statusWarning,
                  ),
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
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                if (row != null) ...[
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
              ],
            ),
          ),
          const SizedBox(height: 12),
          FreevaButton(
            label: s.loanRecordPayment,
            size: FreevaButtonSize.dialog,
            expand: true,
            onPressed: onPay,
          ),
        ],
      ),
    );
  }
}

class _HowCard extends StatelessWidget {
  const _HowCard({required this.text, required this.onEdit});

  final String text;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return FreevaCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    s.loanHow,
                    style: FreevaTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(FreevaRadius.sm),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    s.loanEditShort,
                    style: FreevaTypography.bodyM.copyWith(
                      fontWeight: FontWeight.w600,
                      color: c.textLink,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: FreevaTypography.bodyM.copyWith(
              height: 21 / 14,
              color: c.textOnWash,
            ),
          ),
        ],
      ),
    );
  }
}
