import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/money/signed_money.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/money_display.dart';
import '../../domain/report_holdings.dart';
import 'change_line.dart';

/// "Nợ và vay": how debt moved in the viewed period. The totals and the list
/// of debts are on their own screen, which "Chi tiết" opens.
class ReportDebtCard extends StatelessWidget {
  const ReportDebtCard({
    required this.change,
    required this.due,
    required this.subtitle,
    required this.currency,
    required this.digits,
    super.key,
  });

  final DebtChange change;
  final LoanDue? due;

  /// "Trong tháng 11".
  final String subtitle;
  final String currency;
  final int digits;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final symbol = MoneyDisplay.symbolFor(currency);
    final delta = change.change;
    final falling = delta.isNegative;
    final flat = delta == BigInt.zero;
    // Debt going down is good news: green. Going up is not.
    final tone = flat
        ? c.textPrimary
        : falling
        ? c.statusSuccess
        : c.statusDanger;
    final dueText = due == null
        ? null
        : due!.amount == null
        ? s.reportDebtDueNoAmount(_day(s, due!.dueOn, locale))
        : s.reportDebtDue(
            '${formatMoneyText(due!.amount!, digits, locale)} $symbol',
            _day(s, due!.dueOn, locale),
          );
    return _HoldingsCard(
      title: s.reportDebtTitle,
      subtitle: subtitle,
      onTap: () => context.push('/me/debts'),
      headlineLabel: s.reportDebtChange,
      headline: signedMoney(delta, digits, locale),
      symbol: symbol,
      tone: tone,
      pill: flat ? null : (falling ? s.reportDebtFalling : s.reportDebtRising),
      pillTone: tone,
      stats: [
        (s.reportDebtPaid, formatMoneyText(change.paid, digits, locale)),
        (
          s.reportDebtBorrowed,
          formatMoneyText(
            change.borrowed.isNegative ? BigInt.zero : change.borrowed,
            digits,
            locale,
          ),
        ),
      ],
      footnote: dueText,
    );
  }
}

/// "Đầu tư": gain or loss in the viewed period (not the value change: what was
/// put in or taken out is left out), plus what was put in and taken out.
class ReportInvestCard extends StatelessWidget {
  const ReportInvestCard({
    required this.change,
    required this.subtitle,
    required this.currency,
    required this.digits,
    super.key,
  });

  final InvestChange change;
  final String subtitle;
  final String currency;
  final int digits;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final loss = change.pnl.isNegative;
    final flat = change.pnl == BigInt.zero;
    final tone = flat
        ? c.textPrimary
        : loss
        ? c.statusDanger
        : c.moneyIncome;
    final bps = change.pnlBps;
    return _HoldingsCard(
      title: s.reportInvestTitle,
      subtitle: subtitle,
      onTap: () => context.push('/me/investments'),
      headlineLabel: s.reportInvestPnl,
      headline: signedMoney(change.pnl, digits, locale),
      symbol: MoneyDisplay.symbolFor(currency),
      tone: tone,
      pill: bps == null || flat
          ? null
          : '${loss ? '▼' : '▲'} ${percentText(bps, locale)}',
      pillTone: tone,
      stats: [
        (s.reportInvestAdded, formatMoneyText(change.invested, digits, locale)),
        (
          s.reportInvestWithdrawn,
          formatMoneyText(change.withdrawn, digits, locale),
        ),
      ],
    );
  }
}

String _day(S s, String day, String locale) =>
    DateFormat(s.reportShortDatePattern, locale).format(DateTime.parse(day));

class _HoldingsCard extends StatelessWidget {
  const _HoldingsCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.headlineLabel,
    required this.headline,
    required this.symbol,
    required this.tone,
    required this.pill,
    required this.pillTone,
    required this.stats,
    this.footnote,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String headlineLabel;
  final String headline;
  final String symbol;
  final Color tone;
  final String? pill;
  final Color pillTone;
  final List<(String, String)> stats;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return FreevaCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      semanticsLabel: '$title, $subtitle, $headlineLabel $headline $symbol',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: FreevaTypography.titleM.copyWith(
                        color: c.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: FreevaTypography.label.copyWith(
                        fontWeight: FontWeight.w400,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.reportDetail,
                    style: FreevaTypography.bodyS.copyWith(
                      fontWeight: FontWeight.w600,
                      color: c.textLink,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(LucideIcons.chevronRight, size: 14, color: c.textLink),
                ],
              ),
            ],
          ),
          const SizedBox(height: FreevaSpace.s3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headlineLabel,
                      style: FreevaTypography.label.copyWith(
                        fontWeight: FontWeight.w400,
                        color: c.textSecondary,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: headline,
                              style: FreevaTypography.titleL.copyWith(
                                color: tone,
                                letterSpacing: -0.4,
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
                  ],
                ),
              ),
              if (pill != null) ...[
                const SizedBox(width: FreevaSpace.s2),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: pillTone.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(FreevaRadius.full),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    child: Text(
                      pill!,
                      style: FreevaTypography.label.copyWith(
                        fontWeight: FontWeight.w600,
                        color: pillTone,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: FreevaSpace.s3),
          LayoutBuilder(
            builder: (context, box) {
              final scale = MediaQuery.textScalerOf(context).scale(1);
              final tiles = [
                for (final (label, value) in stats) _Stat(label, value),
              ];
              if (box.maxWidth / scale < 300) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < tiles.length; i++) ...[
                      if (i > 0) const SizedBox(height: FreevaSpace.s2),
                      tiles[i],
                    ],
                  ],
                );
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < tiles.length; i++) ...[
                      if (i > 0) const SizedBox(width: FreevaSpace.s2),
                      Expanded(child: tiles[i]),
                    ],
                  ],
                ),
              );
            },
          ),
          if (footnote != null) ...[
            const SizedBox(height: FreevaSpace.s3),
            DecoratedBox(
              decoration: BoxDecoration(
                color: c.statusWarningBg,
                borderRadius: BorderRadius.circular(FreevaRadius.md),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Text(
                  footnote!,
                  style: FreevaTypography.bodyS.copyWith(
                    fontWeight: FontWeight.w500,
                    color: c.statusWarning,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.bgSubtle,
        borderRadius: BorderRadius.circular(FreevaRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: FreevaTypography.label.copyWith(
              fontWeight: FontWeight.w400,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            style: FreevaTypography.titleM.copyWith(
              color: c.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
