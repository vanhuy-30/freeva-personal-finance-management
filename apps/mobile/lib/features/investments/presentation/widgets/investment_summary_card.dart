import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../../core/widgets/total_card.dart';
import '../../domain/investment.dart';
import 'investment_labels.dart';

/// Flat total card (PA1): icon and label with the change pill, the value, the
/// value history as a line under it (hidden under two points), then cost and
/// expected gain/loss.
class InvestmentSummaryCard extends StatelessWidget {
  const InvestmentSummaryCard({
    required this.total,
    required this.line,
    required this.currency,
    required this.digits,
    required this.hidden,
    super.key,
  });

  final InvestmentTotal total;
  final List<InvestmentValuePoint> line;
  final String currency;
  final int digits;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final bps = total.unrealizedBps;
    final gain = total.unrealizedMinor;
    final gainColor = gain.isNegative ? c.moneyExpense : c.moneyIncome;
    String money(BigInt v) =>
        hidden ? '••••••' : formatMoneyText(v, digits, locale);
    return DecoratedBox(
      decoration: totalCardDecoration(c),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                TotalCardIcon(
                  icon: LucideIcons.trendingUp,
                  background: c.tintBlue,
                  foreground: c.tintBlueFg,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.investmentsTotal,
                    style: FreevaTypography.bodyS.copyWith(
                      fontWeight: FontWeight.w500,
                      color: c.textSecondary,
                    ),
                  ),
                ),
                if (bps != null && !hidden)
                  _Pill(text: investmentPill(bps, locale), negative: bps < 0),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: MoneyDisplay(
                minor: total.currentValueMinor,
                currency: currency,
                minorDigits: digits,
                style: FreevaTypography.moneyDisplayCompact.copyWith(
                  letterSpacing: -1,
                ),
                hidden: hidden,
              ),
            ),
            if (line.length >= 2) ...[
              const SizedBox(height: 12),
              ExcludeSemantics(
                child: SizedBox(
                  height: 64,
                  child: CustomPaint(
                    painter: _ValueLine(
                      [for (final p in line) p.valueMinor],
                      c.actionPrimary,
                      FreevaPrimitive.blue100,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: totalCardStatsDecoration(c),
              child: Padding(
                padding: totalCardStatsPadding,
                child: Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        label: s.investmentsCost,
                        value: money(total.costBasisMinor),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 34,
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      color: c.borderDivider,
                    ),
                    Expanded(
                      child: _Stat(
                        label: s.investmentsGain,
                        value: bps == null
                            ? '—'
                            : hidden
                            ? '••••••'
                            : investmentSigned(gain, digits, locale),
                        color: bps == null ? null : gainColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
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
          style: FreevaTypography.bodyM.copyWith(
            fontWeight: FontWeight.w600,
            color: color ?? c.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// ▲ / ▼ percentage: green for a gain, red for a loss, with the arrow so the
/// colour is not the only cue.
class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.negative});

  final String text;
  final bool negative;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: negative ? c.statusDangerBg : c.statusSuccessBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          text,
          maxLines: 1,
          style: FreevaTypography.bodyS.copyWith(
            fontWeight: FontWeight.w600,
            color: negative ? c.moneyExpense : c.moneyIncome,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

/// Value history over the whole card width: a filled area fading to the
/// surface under a 2.5 line, hidden under two points.
class _ValueLine extends CustomPainter {
  _ValueLine(this.values, this.line, this.fill);

  final List<BigInt> values;
  final Color line;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    var low = values.first;
    var high = values.first;
    for (final v in values) {
      if (v < low) low = v;
      if (v > high) high = v;
    }
    final span = high - low;
    final top = size.height * 0.1;
    final bottom = size.height * 0.9;
    double y(BigInt v) {
      if (span == BigInt.zero) return (top + bottom) / 2;
      final ratio = ((v - low) * BigInt.from(10000) ~/ span).toInt();
      return bottom - (bottom - top) * ratio / 10000;
    }

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      i == 0 ? path.moveTo(x, y(values[i])) : path.lineTo(x, y(values[i]));
    }
    final area = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [fill, fill.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = line,
    );
  }

  @override
  bool shouldRepaint(_ValueLine old) =>
      old.line != line || old.fill != fill || !_same(old.values, values);

  static bool _same(List<BigInt> a, List<BigInt> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
