import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/money_display.dart';
import '../../domain/investment.dart';
import 'investment_labels.dart';

/// A2 total card: value, change pill, cost and expected gain/loss, with the
/// value history as a faint line behind the number (hidden under two points).
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-0.6, -1),
          end: const Alignment(0.6, 1),
          colors: [c.tintBlue, c.bgSurface],
        ),
        border: Border.all(color: c.borderDivider),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            if (line.length >= 2)
              Positioned.fill(
                child: ExcludeSemantics(
                  child: CustomPaint(
                    painter: _FaintLine([
                      for (final p in line) p.valueMinor,
                    ], c.actionPrimary.withValues(alpha: 0.18)),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    s.investmentsTotal,
                    style: FreevaTypography.bodyS.copyWith(
                      fontWeight: FontWeight.w500,
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: MoneyDisplay(
                            minor: total.currentValueMinor,
                            currency: currency,
                            minorDigits: digits,
                            style: FreevaTypography.moneyDisplayCompact
                                .copyWith(letterSpacing: -1),
                            hidden: hidden,
                          ),
                        ),
                      ),
                      if (bps != null && !hidden)
                        _Pill(
                          text: investmentPill(bps, locale),
                          negative: bps < 0,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.bgSurface.withValues(alpha: 0.8),
                      border: Border.all(color: c.borderDivider),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
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

/// Decorative value history, low on the card behind the number.
class _FaintLine extends CustomPainter {
  _FaintLine(this.values, this.color);

  final List<BigInt> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    var low = values.first;
    var high = values.first;
    for (final v in values) {
      if (v < low) low = v;
      if (v > high) high = v;
    }
    final span = high - low;
    final top = size.height * 0.15;
    final bottom = size.height * 0.55;
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
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_FaintLine old) =>
      old.color != color || !_same(old.values, values);

  static bool _same(List<BigInt> a, List<BigInt> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
