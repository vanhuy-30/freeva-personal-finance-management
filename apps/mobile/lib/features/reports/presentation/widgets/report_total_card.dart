import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/money_display.dart';
import '../../domain/report_summary.dart';
import '../../../wallets/presentation/widgets/editor/form_pair.dart';
import 'change_line.dart';

/// Top card of Báo cáo tài chính: Tổng thu nhập and Tổng chi tiêu, the saving
/// with its rate as a ring, then the wallet balance and the average spend per
/// day. Every figure but the balance's source is against the period before
/// ([compare] says which one); a custom range passes null and shows none.
class ReportTotalCard extends StatelessWidget {
  const ReportTotalCard({
    required this.summary,
    required this.currency,
    required this.digits,
    required this.compare,
    super.key,
  });

  final ReportSummary summary;
  final String currency;
  final int digits;

  /// "so tháng trước"; null when there is nothing to compare with.
  final String? compare;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    String money(BigInt v) => formatMoneyText(v, digits, locale);
    final symbol = MoneyDisplay.symbolFor(currency);
    Widget? change(int? bps, {required bool better, bool points = false}) =>
        bps == null
        ? null
        : ChangeLine(
            bps: bps,
            higherIsBetter: better,
            compare: points ? null : compare,
            points: points,
          );
    final savings = summary.savings;
    final rate = summary.savingsRateBps;
    final balance = summary.walletBalance;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-0.6, -1),
          end: const Alignment(0.6, 1),
          colors: [c.tintBlue, c.bgSurface],
        ),
        border: Border.all(color: c.borderDivider),
        borderRadius: BorderRadius.circular(24),
        boxShadow: FreevaElevation.s1,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, box) {
            final wide = fitsSideBySide(context, box.maxWidth + 2 * 14 + 40);
            final income = _Tile(
              icon: LucideIcons.arrowDownLeft,
              iconBg: c.statusSuccessBg,
              iconFg: c.statusSuccess,
              label: s.reportTotalIncome,
              value: money(summary.income),
              symbol: symbol,
              change: change(summary.incomeChangeBps, better: true),
            );
            final expense = _Tile(
              icon: LucideIcons.arrowUpRight,
              iconBg: c.bgSubtle,
              iconFg: c.textPrimary,
              label: s.reportTotalExpense,
              value: money(summary.expense),
              symbol: symbol,
              change: change(summary.expenseChangeBps, better: false),
            );
            final savedText = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.reportSavings, style: _label(c)),
                const SizedBox(height: 2),
                _Amount(
                  text:
                      '${savings.isNegative ? '−' : ''}${money(savings.abs())}',
                  symbol: symbol,
                  size: 24,
                ),
                ?change(summary.savingsChangeBps, better: true),
              ],
            );
            final ring = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RateRing(rateBps: rate),
                const SizedBox(height: 2),
                Text(s.reportSavingsRate, style: _label(c)),
                ?change(
                  summary.savingsRateChangeBps,
                  better: true,
                  points: true,
                ),
              ],
            );
            final stats = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _Stat(
                    label: s.reportWalletTotal,
                    value: balance == null ? null : money(balance),
                    change: change(summary.walletChangeBps, better: true),
                  ),
                ),
                Container(
                  width: 1,
                  height: 44,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: c.borderDivider,
                ),
                Expanded(
                  child: _Stat(
                    label: s.reportAverageDay,
                    value: summary.averagePerDay == null
                        ? null
                        : money(summary.averagePerDay!),
                    change: change(summary.averageChangeBps, better: false),
                  ),
                ),
              ],
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (wide)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: income),
                        const SizedBox(width: 10),
                        Expanded(child: expense),
                      ],
                    ),
                  )
                else ...[
                  income,
                  const SizedBox(height: 10),
                  expense,
                ],
                const SizedBox(height: 10),
                _Panel(
                  child: wide
                      ? Row(
                          children: [
                            Expanded(child: savedText),
                            const SizedBox(width: 12),
                            ring,
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            savedText,
                            const SizedBox(height: 12),
                            Center(child: ring),
                          ],
                        ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: stats,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

TextStyle _label(FreevaColors c) => FreevaTypography.label.copyWith(
  fontWeight: FontWeight.w400,
  color: c.textSecondary,
);

/// White translucent panel on the gradient.
class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.bgSurface.withValues(alpha: 0.85),
        border: Border.all(color: c.borderDivider),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: child,
      ),
    );
  }
}

/// A money figure in ink with the currency symbol small beside it.
class _Amount extends StatelessWidget {
  const _Amount({required this.text, required this.symbol, required this.size});

  final String text;
  final String symbol;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      label: '$text $symbol',
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          style: FreevaTypography.titleL.copyWith(
            fontSize: size,
            height: 1.2,
            letterSpacing: -0.4,
            color: c.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.label,
    required this.value,
    required this.symbol,
    required this.change,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String label;
  final String value;
  final String symbol;
  final Widget? change;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _Panel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: ExcludeSemantics(
                  child: Icon(icon, size: 16, color: iconFg),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: _label(c))),
            ],
          ),
          const SizedBox(height: 6),
          _Amount(text: value, symbol: symbol, size: 19),
          if (change != null) ...[const SizedBox(height: 2), change!],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.change});

  final String label;

  /// Null when the figure is not known (nothing to show but the label).
  final String? value;
  final Widget? change;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _label(c)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            value ?? '—',
            maxLines: 1,
            softWrap: false,
            style: FreevaTypography.titleL.copyWith(
              fontSize: 16,
              height: 1.2,
              color: c.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        ?change,
      ],
    );
  }
}

/// The savings rate as a ring: blue for what was saved, grey for the rest.
/// Nothing is filled for a negative rate or no income, and the centre says "—".
class _RateRing extends StatelessWidget {
  const _RateRing({required this.rateBps});

  final int? rateBps;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final rate = rateBps;
    final text = rate == null
        ? '—'
        : '${NumberFormat('#,##0.0', locale).format(rate / 100)}%';
    final fill = rate == null ? 0.0 : (rate / 10000).clamp(0.0, 1.0);
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5);
    final size = 76.0 * scale;
    return Semantics(
      container: true,
      label: text,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RingPainter(
            fill: fill,
            track: c.borderDivider,
            color: rate != null && rate < 0 ? c.statusDanger : c.data1,
          ),
          child: Center(
            child: Text(
              text,
              style: FreevaTypography.label.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: rate != null && rate < 0
                    ? c.statusDanger
                    : c.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.fill,
    required this.track,
    required this.color,
  });

  final double fill;
  final Color track;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const width = 8.0;
    final rect = Rect.fromLTWH(
      width / 2,
      width / 2,
      size.width - width,
      size.height - width,
    );
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawArc(rect, 0, 2 * math.pi, false, base);
    if (fill <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * fill,
      false,
      base..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fill != fill || old.track != track || old.color != color;
}
