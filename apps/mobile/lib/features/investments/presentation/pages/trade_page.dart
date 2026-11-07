import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../auth/presentation/widgets/auth_message.dart';
import '../../../net_worth/presentation/widgets/net_worth_labels.dart';
import '../../../settings/presentation/widgets/balances_hidden_builder.dart';
import '../../domain/investment.dart';
import '../viewmodels/investment_view_model.dart';
import '../widgets/investment_asset_card.dart';
import '../widgets/investment_labels.dart';
import '../widgets/investment_price_sheet.dart';
import '../widgets/trade_delete_sheet.dart';

/// One buy (board P.4): what it is worth now, its date, quantity, price,
/// wallet, the position's current price and note. Edit and delete.
class TradePage extends StatefulWidget {
  const TradePage({required this.id, required this.tradeId, super.key});

  final String id;
  final String tradeId;

  @override
  State<TradePage> createState() => _TradePageState();
}

class _TradePageState extends State<TradePage> {
  late final InvestmentViewModel model = getIt<InvestmentViewModel>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!model.loaded) await model.load();
      if (!mounted) return;
      await model.loadTrades([widget.id]);
    });
  }

  String? _walletName(String? id) =>
      model.wallets.where((w) => w.id == id).firstOrNull?.draft.name;

  Future<void> _delete(Investment inv, InvestmentTrade trade) async {
    final s = S.of(context);
    final locale = Localizations.localeOf(context).toString();
    final digits = model.digitsOf(inv.currencyCode);
    final yes = await showTradeDeleteSheet(
      context,
      date: investmentDateBox(trade.tradedOn).$1,
      line: s.tradeDeleteLine(
        investmentQuantityText(s, trade.quantity, inv.unit, locale),
        inv.name,
      ),
      walletName: _walletName(trade.accountId),
      amountMinor: trade.amountMinor,
      digits: digits,
    );
    if (!yes || !mounted) return;
    final ok = await model.deleteBuy(inv, trade.id);
    if (!mounted) return;
    if (ok) {
      // The asset goes with its last buy.
      context.popOrGo(
        model.byId(inv.id) == null
            ? '/me/investments'
            : '/me/investments/kind/${inv.kind.apiValue}',
      );
      return;
    }
    final failure = model.failure;
    showFreevaToast(
      context,
      message: failure == null ? s.meSaveError : authFailureText(s, failure),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final margin = context.screenMargin;
    return BalancesHiddenBuilder(
      builder: (context, hidden) => ListenableBuilder(
        listenable: model,
        builder: (context, _) {
          final inv = model.byId(widget.id);
          final trade = model.tradeById(widget.id, widget.tradeId);
          return Scaffold(
            appBar: FreevaTopBar(
              title: trade == null
                  ? s.investmentsTitle
                  : s.tradeTitle(investmentDateBox(trade.tradedOn).$1),
              onLeading: () => context.popOrGo('/me/investments'),
            ),
            body: ListView(
              padding: EdgeInsets.fromLTRB(
                margin,
                FreevaSpace.s2,
                margin,
                FreevaSpace.s8,
              ),
              children: inv == null || trade == null
                  ? const [SkeletonBox(height: 220, radius: 24)]
                  : _body(context, hidden, inv, trade),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _body(
    BuildContext context,
    bool hidden,
    Investment inv,
    InvestmentTrade trade,
  ) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final digits = model.digitsOf(inv.currencyCode);
    String money(BigInt v) =>
        hidden ? '••••••' : formatMoneyText(v, digits, locale);
    final price = inv.latestPriceMinor;
    final value = trade.currentValueMinor;
    final gain = trade.unrealizedMinor;
    final bps = trade.unrealizedBps;
    final unitName = s.investmentUnit(inv.unit);
    final dateText = netWorthDate(trade.tradedOn, locale, year: true);
    Widget row(String label, String text, {VoidCallback? onTap}) {
      final inner = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Text(
              label,
              style: FreevaTypography.bodyM.copyWith(color: c.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                textAlign: TextAlign.end,
                style: FreevaTypography.bodyM.copyWith(
                  fontWeight: FontWeight.w500,
                  color: c.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              Icon(LucideIcons.chevronRight, size: 16, color: c.textSecondary),
            ],
          ],
        ),
      );
      return onTap == null ? inner : InkWell(onTap: onTap, child: inner);
    }

    final rows = <Widget>[
      row(s.investmentBuyDate, dateText),
      row(
        s.investmentQuantity,
        investmentQuantityText(s, trade.quantity, inv.unit, locale),
      ),
      row(
        s.tradePriceRow,
        s.investmentPerUnit(money(trade.unitPriceMinor), unitName),
      ),
      row(
        s.investmentFromWallet,
        trade.accountId == null
            ? s.investmentExisting
            : (_walletName(trade.accountId) ?? '—'),
      ),
      if (price != null && inv.latestPriceAt != null)
        row(
          s.tradeCurrentPrice,
          '${money(price)} · ${inv.latestPriceAt!.toLocal().day.toString().padLeft(2, '0')}/${inv.latestPriceAt!.toLocal().month.toString().padLeft(2, '0')}',
          onTap: () => showInvestmentPriceSheet(context, model, inv),
        ),
      if (trade.note != null && trade.note!.isNotEmpty)
        row(s.tradeNoteRow, trade.note!),
    ];
    return [
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: const Alignment(-0.6, -1),
            end: const Alignment(0.6, 1),
            colors: [c.tintBlue, c.bgSurface],
          ),
          border: Border.all(color: c.borderDivider),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                s.tradeCardTitle(inv.name),
                style: FreevaTypography.bodyS.copyWith(
                  fontWeight: FontWeight.w500,
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: value == null
                          ? Text(
                              s.investmentsUnpriced,
                              style: FreevaTypography.titleL.copyWith(
                                color: c.textSecondary,
                              ),
                            )
                          : MoneyDisplay(
                              minor: value,
                              currency: inv.currencyCode,
                              minorDigits: digits,
                              style: FreevaTypography.moneyDisplayCompact
                                  .copyWith(letterSpacing: -1),
                              hidden: hidden,
                            ),
                    ),
                  ),
                  if (bps != null && !hidden) InvestmentChangePill(bps: bps),
                ],
              ),
              if (price != null) ...[
                const SizedBox(height: 4),
                Text(
                  s.tradeQuantityTimes(
                    investmentQuantityText(s, trade.quantity, inv.unit, locale),
                    money(price),
                  ),
                  style: FreevaTypography.bodyS.copyWith(
                    color: c.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
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
                          value: money(trade.amountMinor),
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
                          value: gain == null
                              ? '—'
                              : hidden
                              ? '••••••'
                              : investmentSigned(gain, digits, locale),
                          color: gain == null
                              ? null
                              : gain.isNegative
                              ? c.moneyExpense
                              : c.moneyIncome,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      FreevaCard(
        list: true,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) Divider(height: 1, color: c.borderDivider),
              rows[i],
            ],
          ],
        ),
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: FreevaButton(
              label: s.tradeEdit,
              icon: LucideIcons.pencil,
              variant: FreevaButtonVariant.secondary,
              expand: true,
              onPressed: () => context.push(
                '/me/investments/${inv.id}/trades/${trade.id}/edit',
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FreevaButton(
              label: s.tradeDelete,
              icon: LucideIcons.trash,
              variant: FreevaButtonVariant.secondary,
              expand: true,
              onPressed: () => _delete(inv, trade),
            ),
          ),
        ],
      ),
    ];
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
