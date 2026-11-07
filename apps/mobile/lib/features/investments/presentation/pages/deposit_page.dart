import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/error_retry.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/freeva_dialog.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../auth/presentation/widgets/auth_message.dart';
import '../../../net_worth/presentation/widgets/net_worth_labels.dart';
import '../../../reports/presentation/widgets/report_labels.dart';
import '../../../settings/presentation/widgets/balances_hidden_builder.dart';
import '../../domain/investment.dart';
import '../viewmodels/investment_view_model.dart';
import '../widgets/deposit_sheets.dart';
import '../widgets/investment_asset_card.dart';
import '../widgets/investment_labels.dart';

/// A savings deposit (board P.11): value today, principal and interest so
/// far, rate, dates and the wallet it came from. Withdraw, edit, delete.
class DepositPage extends StatefulWidget {
  const DepositPage({required this.id, super.key});

  final String id;

  @override
  State<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends State<DepositPage> {
  late final InvestmentViewModel model = getIt<InvestmentViewModel>();

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    if (!model.loaded) await model.load();
    if (!mounted) return;
    await model.loadTrades([widget.id]);
  }

  Future<void> _withdraw(Investment deposit) async {
    final ok = await showDepositWithdrawSheet(context, model, deposit);
    if (ok == true && mounted) context.popOrGo('/me/investments');
  }

  Future<void> _delete(Investment deposit) async {
    final s = S.of(context);
    final yes = await showFreevaConfirm(
      context: context,
      title: s.depositDeleteTitle,
      message: s.depositDeleteBody,
      cancelLabel: s.commonCancel,
      confirmLabel: s.depositDelete,
      destructive: true,
      icon: LucideIcons.trash,
    );
    if (!yes || !mounted) return;
    final ok = await model.deleteDeposit(deposit);
    if (!mounted) return;
    if (ok) {
      context.popOrGo('/me/investments');
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
          final deposit = model.byId(widget.id);
          return Scaffold(
            appBar: FreevaTopBar(
              title: deposit?.name ?? s.investmentsTitle,
              onLeading: () => context.popOrGo('/me/investments'),
            ),
            body: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  margin,
                  FreevaSpace.s2,
                  margin,
                  FreevaSpace.s8,
                ),
                children: _body(context, hidden, deposit),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _body(BuildContext context, bool hidden, Investment? deposit) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    if (deposit == null) {
      if (model.failure != null && !model.loading) {
        return [
          ErrorRetry(
            title: reportFailure(s, model.failure!),
            message: s.homeErrorBody,
            onRetry: _load,
          ),
        ];
      }
      return [
        if (model.loaded)
          const SizedBox.shrink()
        else
          const SkeletonBox(height: 220, radius: 24),
      ];
    }
    final digits = model.digitsOf(deposit.currencyCode);
    final interest = deposit.currentValueMinor - deposit.costBasisMinor;
    final bps = deposit.unrealizedBps;
    final days = deposit.maturityDate == null
        ? null
        : daysUntil(deposit.maturityDate!, model.today);
    final maturity = deposit.maturityDate == null
        ? '—'
        : days! > 0
        ? s.depositMaturityLeft(
            netWorthDate(deposit.maturityDate!, locale, year: true),
            days,
          )
        : s.depositMatured(
            netWorthDate(deposit.maturityDate!, locale, year: true),
          );
    final walletId = model.buysOf(deposit.id).firstOrNull?.accountId;
    final tradesKnown = model.trades[deposit.id] != null;
    final wallet = walletId == null
        ? null
        : model.wallets.where((w) => w.id == walletId).firstOrNull;
    Widget row(String label, String value) => Padding(
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
              value,
              textAlign: TextAlign.end,
              style: FreevaTypography.bodyM.copyWith(
                fontWeight: FontWeight.w500,
                color: c.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
    String money(BigInt v) =>
        hidden ? '••••••' : formatMoneyText(v, digits, locale);
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
                s.depositValueToday,
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
                      child: MoneyDisplay(
                        minor: deposit.currentValueMinor,
                        currency: deposit.currencyCode,
                        minorDigits: digits,
                        style: FreevaTypography.moneyDisplayCompact.copyWith(
                          letterSpacing: -1,
                        ),
                        hidden: hidden,
                      ),
                    ),
                  ),
                  if (bps != null && !hidden) InvestmentChangePill(bps: bps),
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
                          label: s.depositPrincipal,
                          value: money(deposit.costBasisMinor),
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
                          label: s.depositInterest,
                          value: hidden
                              ? '••••••'
                              : investmentSigned(interest, digits, locale),
                          color: interest.isNegative
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
            if (deposit.interestRateBps != null) ...[
              row(
                s.depositRateLabel,
                s.depositRatePerYear(
                  '${depositRateText(deposit.interestRateBps!, locale)}%',
                ),
              ),
              Divider(height: 1, color: c.borderDivider),
            ],
            if (deposit.startDate != null) ...[
              row(
                s.investmentDepositDate,
                netWorthDate(deposit.startDate!, locale, year: true),
              ),
              Divider(height: 1, color: c.borderDivider),
            ],
            row(s.depositMaturityRow, maturity),
            if (tradesKnown) ...[
              Divider(height: 1, color: c.borderDivider),
              row(
                s.investmentFromWallet,
                walletId == null
                    ? s.investmentExisting
                    : (wallet?.draft.name ?? '—'),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 20),
      FreevaButton(
        label: s.depositWithdraw,
        size: FreevaButtonSize.l,
        expand: true,
        onPressed: () => _withdraw(deposit),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () => showDepositEditSheet(context, model, deposit),
            child: Text(
              s.depositEdit,
              style: FreevaTypography.bodyM.copyWith(
                fontWeight: FontWeight.w600,
                color: c.textLink,
              ),
            ),
          ),
          const SizedBox(width: 24),
          TextButton(
            onPressed: tradesKnown ? () => _delete(deposit) : null,
            child: Text(
              s.depositDelete,
              style: FreevaTypography.bodyM.copyWith(
                fontWeight: FontWeight.w600,
                color: c.textLink,
              ),
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
