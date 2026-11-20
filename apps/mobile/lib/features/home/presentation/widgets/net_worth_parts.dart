import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../../core/widgets/press_scale.dart';
import '../../domain/overview.dart';

/// "Có" and "Nợ" side by side on the net worth card.
class NetWorthSplit extends StatelessWidget {
  const NetWorthSplit({
    required this.balance,
    required this.digits,
    required this.hidden,
    required this.onOpenAssets,
    required this.onOpenDebts,
    this.investedMinor,
    super.key,
  });

  final CurrencyBalance balance;
  final int digits;
  final bool hidden;
  final BigInt? investedMinor;
  final VoidCallback onOpenAssets;
  final VoidCallback onOpenDebts;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final assets = balance.assetsMinor;
    final debts = -balance.liabilitiesMinor;
    final positive = assets > BigInt.zero;
    final invested = investedMinor;
    final investShare = positive && invested != null && invested > BigInt.zero
        ? _share(invested, assets)
        : null;
    final debtShare = positive && debts > BigInt.zero
        ? _share(debts, assets)
        : null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _Box(
            label: s.homeAssets,
            amount: assets,
            currency: balance.currency,
            digits: digits,
            hidden: hidden,
            note: investShare == null
                ? s.homeAssetsWallets(balance.walletCount)
                : s.homeAssetsInvestShare(investShare),
            bar: [
              if (investShare == null)
                (positive ? 1.0 : 0.0, c.data3)
              else ...[
                ((100 - investShare) / 100, c.data3),
                (investShare / 100, c.data1),
              ],
            ],
            onTap: onOpenAssets,
          ),
        ),
        const SizedBox(width: FreevaSpace.s2),
        Expanded(
          child: _Box(
            label: s.homeDebts,
            amount: debts,
            currency: balance.currency,
            digits: digits,
            hidden: hidden,
            note: debts <= BigInt.zero
                ? s.homeDebtsNone
                : debtShare == null
                ? ''
                : s.homeDebtsShare(debtShare),
            bar: [
              (
                debtShare == null
                    ? (debts > BigInt.zero ? 1.0 : 0.0)
                    : (debtShare / 100).clamp(0, 1).toDouble(),
                c.data2,
              ),
            ],
            onTap: onOpenDebts,
          ),
        ),
      ],
    );
  }

  /// Whole percent of [part] in [whole], at most 100.
  static int _share(BigInt part, BigInt whole) {
    final value = (part * BigInt.from(100) ~/ whole).toInt();
    return value > 100 ? 100 : value;
  }
}

class _Box extends StatelessWidget {
  const _Box({
    required this.label,
    required this.amount,
    required this.currency,
    required this.digits,
    required this.hidden,
    required this.note,
    required this.bar,
    required this.onTap,
  });

  final String label;
  final BigInt amount;
  final String currency;
  final int digits;
  final bool hidden;
  final String note;
  final List<(double, Color)> bar;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final small = FreevaTypography.label.copyWith(
      fontWeight: FontWeight.w400,
      height: 1.3,
      color: c.balanceCardFg,
    );
    return Semantics(
      button: true,
      container: true,
      child: PressScale(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(FreevaSpace.s3),
            decoration: BoxDecoration(
              color: c.bgSurface.withValues(alpha: .72),
              borderRadius: BorderRadius.circular(FreevaRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: small.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 14,
                      color: c.balanceCardFg,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: MoneyDisplay(
                    minor: amount,
                    currency: currency,
                    minorDigits: digits,
                    hidden: hidden,
                    showCurrency: false,
                    style: FreevaTypography.titleM.copyWith(
                      fontSize: 17,
                      height: 1.3,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                _Bar(parts: bar),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(note, maxLines: 1, softWrap: false, style: small),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 6 tall bar on a faint ink track; parts are fractions of the full width.
class _Bar extends StatelessWidget {
  const _Bar({required this.parts});

  final List<(double, Color)> parts;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(FreevaRadius.full),
    child: SizedBox(
      height: 6,
      child: ColoredBox(
        color: context.colors.textPrimary.withValues(alpha: .08),
        child: LayoutBuilder(
          builder: (context, box) => Row(
            children: [
              for (final (i, (fraction, color)) in parts.indexed)
                if (fraction > 0)
                  Container(
                    width: (box.maxWidth * fraction - (i > 0 ? 2 : 0))
                        .clamp(0, box.maxWidth)
                        .toDouble(),
                    margin: EdgeInsetsDirectional.only(start: i > 0 ? 2 : 0),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(FreevaRadius.full),
                    ),
                  ),
            ],
          ),
        ),
      ),
    ),
  );
}
