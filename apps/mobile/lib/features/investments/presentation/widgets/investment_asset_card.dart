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
    required this.onTrade,
    super.key,
  });

  final Investment investment;
  final List<InvestmentTrade> buys;
  final int digits;
  final bool hidden;
  final VoidCallback onPrice;
  final VoidCallback onBuyMore;
  final VoidCallback onSell;

  /// Opens the detail of one buy.
  final ValueChanged<InvestmentTrade> onTrade;

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
                    const SizedBox(height: 2),
                    Text(
                      investmentQuantityText(s, held, unit, locale),
                      style: FreevaTypography.bodyL.copyWith(
                        fontWeight: FontWeight.w600,
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
          DecoratedBox(
            decoration: BoxDecoration(
              color: c.bgSubtle,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  _Stat(
                    label: s.investmentsValue,
                    value: money(i.currentValueMinor),
                  ),
                  const _StatDivider(),
                  _Stat(
                    label: s.investmentsCost,
                    value: money(i.costBasisMinor),
                  ),
                  const _StatDivider(),
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
            ),
          ),
          if (buys.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(height: 1, color: c.borderDivider),
            const SizedBox(height: 14),
            _TradesList(
              buys: buys,
              unit: unit,
              digits: digits,
              hidden: hidden,
              onTap: onTrade,
            ),
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

/// The rate the user typed for a deposit ("7,5%"), not a gain: interest is
/// only paid at maturity.
class DepositRatePill extends StatelessWidget {
  const DepositRatePill({required this.bps, super.key});

  final int bps;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.statusSuccessBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Text(
          '${depositRateText(bps, locale)}%',
          maxLines: 1,
          style: FreevaTypography.label.copyWith(
            fontWeight: FontWeight.w600,
            color: c.moneyIncome,
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

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 32,
    margin: const EdgeInsets.symmetric(horizontal: 10),
    color: context.colors.borderDivider,
  );
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

/// The buys of one asset, newest first: the latest [_shown] and a toggle for
/// the rest, so a long history does not push the actions off the screen.
class _TradesList extends StatefulWidget {
  const _TradesList({
    required this.buys,
    required this.unit,
    required this.digits,
    required this.hidden,
    required this.onTap,
  });

  final List<InvestmentTrade> buys;
  final String unit;
  final int digits;
  final bool hidden;
  final ValueChanged<InvestmentTrade> onTap;

  @override
  State<_TradesList> createState() => _TradesListState();
}

class _TradesListState extends State<_TradesList> {
  static const _shown = 3;
  bool all = false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final buys = widget.buys.reversed.toList();
    final visible = all ? buys : buys.take(_shown).toList();
    final more = buys.length - _shown;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                s.investmentTradesHeader,
                style: FreevaTypography.bodyM.copyWith(
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
            ),
            Text(
              s.investmentTradesCount(buys.length),
              style: FreevaTypography.label.copyWith(
                fontWeight: FontWeight.w400,
                color: c.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        for (var k = 0; k < visible.length; k++) ...[
          if (k > 0) Divider(height: 1, color: c.borderDivider),
          _TradeRow(
            trade: visible[k],
            unit: widget.unit,
            digits: widget.digits,
            hidden: widget.hidden,
            onTap: () => widget.onTap(visible[k]),
          ),
        ],
        if (more > 0)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => setState(() => all = !all),
              child: Text(
                all ? s.investmentTradesLess : s.investmentTradesMore(more),
                style: FreevaTypography.bodyS.copyWith(
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

/// One buy in two lines: quantity and the amount paid, then the date with the
/// cost per unit and the change. A buy held before the app says "Có sẵn"
/// instead of a date.
class _TradeRow extends StatelessWidget {
  const _TradeRow({
    required this.trade,
    required this.unit,
    required this.digits,
    required this.hidden,
    required this.onTap,
  });

  final VoidCallback onTap;
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
    String money(BigInt v) =>
        hidden ? '••••••' : formatMoneyText(v, digits, locale);
    final price = s.investmentTradeCost(
      money(trade.unitPriceMinor),
      s.investmentUnit(unit),
    );
    final day = trade.tradedOn;
    final date =
        '${day.substring(8, 10)}/${day.substring(5, 7)}/${day.substring(0, 4)}';
    final bps = trade.unrealizedBps;
    final sub = FreevaTypography.label.copyWith(
      fontWeight: FontWeight.w400,
      color: c.textSecondary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          investmentQuantityText(
                            s,
                            trade.quantity,
                            unit,
                            locale,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FreevaTypography.bodyM.copyWith(
                            fontWeight: FontWeight.w500,
                            color: c.textPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      if (existing) ...[
                        const SizedBox(width: 8),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: c.statusWarningBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            child: Text(
                              s.investmentExistingTag,
                              style: FreevaTypography.label.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: c.statusWarning,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    existing ? price : '$date · $price',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: sub,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  money(trade.amountMinor),
                  style: FreevaTypography.bodyM.copyWith(
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  bps != null && !hidden ? investmentPill(bps, locale) : ' ',
                  style: FreevaTypography.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: bps == null
                        ? c.textSecondary
                        : bps < 0
                        ? c.moneyExpense
                        : c.moneyIncome,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
