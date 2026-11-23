import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../../core/widgets/money_display.dart';
import '../../domain/category_detail.dart';
import '../../domain/report_breakdown.dart';
import '../widgets/breakdown_rows.dart';
import '../widgets/report_period_labels.dart';

import 'package:go_router/go_router.dart';

/// Every category of the viewed period, biggest first, with its share and
/// amount. Children are counted in their parent, as in the card it comes from;
/// no category is folded into "Khác" here except the uncategorised money.
class ReportBreakdownPage extends StatelessWidget {
  const ReportBreakdownPage({required this.args, super.key});

  final BreakdownPageArgs args;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final expense = args.kind == BreakdownKind.expense;
    final breakdown = reportBreakdown(
      args.report,
      args.currency,
      args.kind,
      top: 1 << 30,
    );
    final slices = breakdown.slices;
    final title = periodTitle(s, args.report.period, locale);
    final symbol = MoneyDisplay.symbolFor(args.currency);
    return Scaffold(
      appBar: FreevaTopBar(
        title: expense
            ? s.reportBreakdownPageExpense
            : s.reportBreakdownPageIncome,
        subtitle: [
          title.title,
          if (title.subtitle != null) title.subtitle!,
        ].join(' · '),
        onLeading: () => context.popOrGo('/reports'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          context.screenMargin,
          FreevaSpace.s2,
          context.screenMargin,
          FreevaSpace.s8,
        ),
        children: [
          FreevaCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  expense ? s.reportTotalExpense : s.reportTotalIncome,
                  style: FreevaTypography.label.copyWith(
                    fontWeight: FontWeight.w400,
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Semantics(
                    container: true,
                    label:
                        '${formatMoneyText(breakdown.total, args.digits, locale)} $symbol',
                    excludeSemantics: true,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: formatMoneyText(
                              breakdown.total,
                              args.digits,
                              locale,
                            ),
                            style: FreevaTypography.titleL.copyWith(
                              fontSize: 28,
                              letterSpacing: -0.6,
                              color: c.textPrimary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          TextSpan(
                            text: ' $symbol',
                            style: FreevaTypography.bodyM.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                ),
                if (slices.isNotEmpty) ...[
                  const SizedBox(height: FreevaSpace.s3),
                  ExcludeSemantics(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(FreevaRadius.full),
                      child: SizedBox(
                        height: 12,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < slices.length; i++) ...[
                              if (i > 0) const SizedBox(width: 2),
                              Expanded(
                                flex: slices[i].percent == 0
                                    ? 1
                                    : slices[i].percent * 10,
                                child: ColoredBox(
                                  color: sliceColor(context, i, slices[i]),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: FreevaSpace.s4),
          if (slices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: FreevaSpace.s6),
              child: Text(
                s.reportEmptyHint,
                textAlign: TextAlign.center,
                style: FreevaTypography.bodyS.copyWith(color: c.textSecondary),
              ),
            )
          else ...[
            FreevaCard(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            s.reportBreakdownCount(slices.length).toUpperCase(),
                            style: FreevaTypography.sectionLabel.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        expense
                            ? s.reportBreakdownSortExpense
                            : s.reportBreakdownSortIncome,
                        style: FreevaTypography.label.copyWith(
                          fontWeight: FontWeight.w400,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: FreevaSpace.s2),
                  BreakdownRows(
                    slices: slices,
                    currency: args.currency,
                    digits: args.digits,
                    showShare: true,
                    onOpen: (slice) => context.push(
                      '/reports/category',
                      extra: CategoryDetailArgs(
                        report: args.report,
                        currency: args.currency,
                        digits: args.digits,
                        kind: args.kind,
                        slice: slice,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: FreevaSpace.s3),
            Text(
              s.reportBreakdownNote,
              textAlign: TextAlign.center,
              style: FreevaTypography.label.copyWith(
                fontWeight: FontWeight.w400,
                color: c.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
