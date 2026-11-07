import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/money/quantity.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../domain/investment.dart';
import 'investment_labels.dart';

/// One asset on the category screen (board P.3): name and quantity, the
/// price pill that opens "Cập nhật giá", Giá trị · Vốn · Lãi/lỗ, its buys,
/// and Mua thêm · Bán.
class InvestmentAssetCard extends StatelessWidget {
  const InvestmentAssetCard({
    required this.investment,
    required this.buys,
    required this.digits,
    required this.hidden,
    required this.onPrice,
    required this.onBuyMore,
    required this.onSell,
    super.key,
  });

  final Investment investment;
  final List<InvestmentTrade> buys;
  final int digits;
  final bool hidden;
  final VoidCallback onPrice;
  final VoidCallback onBuyMore;
  final VoidCallback onSell;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final i = investment;
    final bps = i.unrealizedBps;
    final held = parseQuantityApi(i.quantity) ?? BigInt.zero;
    String money(BigInt v) =>
        hidden ? '••••••' : formatMoneyText(v, digits, locale);
    final unit = i.unit;
    final gain = bps == null || i.unrealizedMinor == null
        ? '—'
        : hidden
        ? '••••••'
        : investmentSigned(i.unrealizedMinor!, digits, locale);
    return FreevaCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      i.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FreevaTypography.titleM.copyWith(
                        color: c.textPrimary,
                      ),
                    ),
                    Text(
                      investmentQuantityText(s, held, unit, locale),
                      style: FreevaTypography.label.copyWith(
                        fontWeight: FontWeight.w400,
                        color: c.textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              if (bps != null && !hidden) InvestmentChangePill(bps: bps),
            ],
          ),
          const SizedBox(height: 12),
          _PricePill(
            text: i.latestPriceMinor == null
                ? s.investmentsUnpriced
                : '${s.investmentPerUnit(money(i.latestPriceMinor!), s.investmentUnit(unit))} · ${_day(i.latestPriceAt!, locale)}',
            action: s.investmentUpdatePrice,
            onTap: onPrice,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Stat(
                label: s.investmentsValue,
                value: money(i.currentValueMinor),
              ),
              const SizedBox(width: 10),
              _Stat(label: s.investmentsCost, value: money(i.costBasisMinor)),
              const SizedBox(width: 10),
              _Stat(
                label: s.investmentsGain,
                value: gain,
                color: bps == null
                    ? c.textSecondary
                    : i.unrealizedMinor!.isNegative
                    ? c.moneyExpense
                    : c.moneyIncome,
              ),
            ],
          ),
          if (buys.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              s.investmentTradesHeader.toUpperCase(),
              style: FreevaTypography.sectionLabel.copyWith(
                color: c.textSecondary,
              ),
            ),
            for (final t in buys)
              _TradeRow(trade: t, unit: unit, digits: digits, hidden: hidden),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (!i.kind.singleLot) ...[
                Expanded(
                  child: FreevaButton(
                    label: s.investmentBuyMore,
                    icon: LucideIcons.plus,
                    variant: FreevaButtonVariant.secondary,
                    expand: true,
                    onPressed: onBuyMore,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: FreevaButton(
                  label: s.investmentSell,
                  icon: LucideIcons.arrowDownToLine,
                  variant: FreevaButtonVariant.secondary,
                  expand: true,
                  onPressed: held > BigInt.zero ? onSell : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _day(DateTime at, String locale) {
    final d = at.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }
}

/// ▲ / ▼ percentage in a coloured pill.
class InvestmentChangePill extends StatelessWidget {
  const InvestmentChangePill({required this.bps, super.key});

  final int bps;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final negative = bps < 0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: negative ? c.statusDangerBg : c.statusSuccessBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Text(
          investmentPill(bps, locale),
          maxLines: 1,
          style: FreevaTypography.label.copyWith(
            fontWeight: FontWeight.w600,
            color: negative ? c.moneyExpense : c.moneyIncome,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

class _PricePill extends StatelessWidget {
  const _PricePill({
    required this.text,
    required this.action,
    required this.onTap,
  });

  final String text;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: '$text, $action',
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: c.bgSubtle,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(LucideIcons.tag, size: 16, color: c.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FreevaTypography.bodyS.copyWith(
                      color: c.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  action,
                  maxLines: 1,
                  style: FreevaTypography.bodyS.copyWith(
                    fontWeight: FontWeight.w600,
                    color: c.textLink,
                  ),
                ),
              ],
            ),
          ),
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
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            style: FreevaTypography.label.copyWith(
              fontWeight: FontWeight.w400,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            style: FreevaTypography.bodyS.copyWith(
              fontWeight: FontWeight.w600,
              color: color ?? c.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// One buy: date box, quantity and unit price, amount and change.
class _TradeRow extends StatelessWidget {
  const _TradeRow({
    required this.trade,
    required this.unit,
    required this.digits,
    required this.hidden,
  });

  final InvestmentTrade trade;
  final String unit;
  final int digits;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final existing = trade.existing;
    final (top, bottom) = existing
        ? ('—', s.investmentExistingBox)
        : investmentDateBox(trade.tradedOn);
    String money(BigInt v) =>
        hidden ? '••••••' : formatMoneyText(v, digits, locale);
    final price = money(trade.unitPriceMinor);
    final unitName = s.investmentUnit(unit);
    final bps = trade.unrealizedBps;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.borderDivider)),
      ),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: existing ? c.statusWarningBg : c.bgSubtle,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    top,
                    style: FreevaTypography.label.copyWith(
                      fontWeight: FontWeight.w600,
                      color: existing ? c.statusWarning : c.textPrimary,
                    ),
                  ),
                  Text(
                    bottom,
                    maxLines: 1,
                    style: FreevaTypography.label.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: existing ? c.statusWarning : c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  investmentQuantityText(s, trade.quantity, unit, locale),
                  style: FreevaTypography.bodyM.copyWith(
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  existing
                      ? s.investmentTradeCost(price, unitName)
                      : s.investmentTradePrice(price, unitName),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                money(trade.amountMinor),
                style: FreevaTypography.bodyS.copyWith(
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (bps != null && !hidden)
                Text(
                  investmentPill(bps, locale),
                  style: FreevaTypography.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: bps < 0 ? c.moneyExpense : c.moneyIncome,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
