import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/error_retry.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../domain/report.dart';
import '../viewmodels/report_view_model.dart';
import 'report_breakdown_card.dart';
import 'report_budget_row.dart';
import 'report_cashflow_card.dart';
import 'report_currency_chips.dart';
import 'report_empty.dart';
import 'report_holdings_cards.dart';
import 'report_insights_card.dart';
import 'report_labels.dart';
import 'report_period_labels.dart';
import 'report_period_nav.dart';
import 'report_total_card.dart';
import 'report_trend_card.dart';

/// Báo cáo tài chính: the period navigator, then the totals with their
/// comparison, the month's findings and budget, the cash flow, the spending
/// trend, the breakdown, and how debt and investments moved. Loading, failure
/// and empty periods keep the navigator so the user can move.
class ReportBody extends StatelessWidget {
  const ReportBody({required this.model, super.key});

  final ReportViewModel model;

  @override
  Widget build(BuildContext context) {
    final margin = context.screenMargin;
    const gap = SizedBox(height: FreevaSpace.s4);
    return RefreshIndicator(
      onRefresh: model.reload,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          margin,
          FreevaSpace.s2,
          margin,
          FreevaLayout.navReserve,
        ),
        children: [
          ReportPeriodNav(model: model),
          gap,
          ..._content(context, gap),
        ],
      ),
    );
  }

  List<Widget> _content(BuildContext context, Widget gap) {
    final s = S.of(context);
    final data = model.data;
    final failure = model.failure;
    if (failure != null && data == null && !model.busy) {
      return [
        ErrorRetry(
          title: reportFailure(s, failure),
          message: s.homeErrorBody,
          onRetry: model.reload,
        ),
      ];
    }
    if (data == null) {
      return [
        if (model.kind != ReportPeriodKind.range || model.busy) ...[
          const SkeletonBox(height: 300, radius: 24),
          gap,
          const SkeletonBox(height: 210, radius: 24),
        ],
      ];
    }
    final period = data.report.period;
    final code = model.currency;
    final summary = model.summary;
    if (code == null || summary == null) {
      return [ReportEmpty(model: model, period: period)];
    }
    final digits = data.digitsOf(code);
    final holdings = model.holdings;
    final debt = holdings?.debtOf(code);
    final invest = holdings?.investOf(code);
    final subtitle = inPeriodLabel(s, period);
    return [
      if (model.currencies.length > 1) ...[
        ReportCurrencyChips(model: model),
        gap,
      ],
      ReportTotalCard(
        summary: summary,
        currency: code,
        digits: digits,
        compare: compareLabel(s, period.kind),
      ),
      if (period.kind == ReportPeriodKind.month) ...[
        // Nothing (and no space) while the findings are not there or not this month.
        ReportInsightsCard(period: period),
        gap,
        ReportBudgetRow(period: period, currency: code, minorDigits: digits),
      ],
      // A cash flow that failed to load hides its card; while loading it shows a skeleton.
      if (model.flow != null || model.extrasLoading) ...[
        gap,
        ReportCashflowCard(
          flow: model.flow,
          currency: code,
          digits: digits,
          today: model.today,
        ),
      ],
      gap,
      ReportTrendCard(
        model: model,
        currency: code,
        digits: digits,
        today: model.today,
      ),
      gap,
      ReportBreakdownCard(report: data.report, currency: code, digits: digits),
      if (debt != null) ...[
        gap,
        ReportDebtCard(
          change: debt,
          due: holdings?.dueOf(code),
          subtitle: subtitle,
          currency: code,
          digits: digits,
        ),
      ],
      if (invest != null) ...[
        gap,
        ReportInvestCard(
          change: invest,
          subtitle: subtitle,
          currency: code,
          digits: digits,
        ),
      ],
    ];
  }
}
