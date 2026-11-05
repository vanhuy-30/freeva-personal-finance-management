import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/error_retry.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/freeva_dialog.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../../core/widgets/progress_bar.dart';
import '../../../recurring/presentation/widgets/rec_tag.dart';
import '../../../transactions/presentation/viewmodels/transaction_view_model.dart';
import '../../../transactions/presentation/widgets/transaction_naming.dart';
import '../../domain/card_installment.dart';
import '../viewmodels/installment_view_model.dart';
import '../widgets/installment_parts.dart';

/// "Lịch trả góp" (M, màn 6, board `InstDetail`): what is left of the
/// purchase, every period, and "Kết thúc trả góp" for an early payoff.
class InstallmentDetailPage extends StatefulWidget {
  const InstallmentDetailPage({required this.planId, this.model, super.key});

  final String planId;
  final InstallmentViewModel? model;

  @override
  State<InstallmentDetailPage> createState() => _InstallmentDetailPageState();
}

class _InstallmentDetailPageState extends State<InstallmentDetailPage> {
  late final InstallmentViewModel model =
      widget.model ?? getIt<InstallmentViewModel>();
  late final TransactionViewModel main = getIt<TransactionViewModel>();
  bool closing = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!main.composerReady) await main.load();
      await model.load(widget.planId);
    });
  }

  Future<void> _close(CardInstallment plan) async {
    final s = S.of(context);
    final ok = await showFreevaConfirm(
      context: context,
      title: s.installmentCloseTitle,
      message: s.installmentCloseBody,
      cancelLabel: s.commonCancel,
      confirmLabel: s.installmentCloseConfirm,
      destructive: true,
      icon: LucideIcons.archive,
    );
    if (!ok || !mounted) return;
    setState(() => closing = true);
    final closed = await model.close(plan);
    if (!mounted) return;
    setState(() => closing = false);
    showFreevaToast(
      context,
      message: closed == null ? s.installmentLoadError : s.installmentClosed,
      success: closed != null,
      aboveNav: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([model, main]),
      builder: (context, _) {
        final plan = model.detail(widget.planId);
        final naming = TransactionNaming(
          s,
          categories: main.categories,
          wallets: main.wallets,
        );
        if (plan == null || plan.periods == null) {
          return Scaffold(
            appBar: FreevaTopBar(title: s.installmentTitle),
            body: model.failure != null
                ? ErrorRetry(
                    title: s.installmentLoadError,
                    message: s.homeErrorBody,
                    onRetry: () => model.load(widget.planId),
                  )
                : const SizedBox.shrink(),
          );
        }
        return Scaffold(
          appBar: FreevaTopBar(title: installmentName(s, naming, plan)),
          body: _body(context, s, plan, naming),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    S s,
    CardInstallment plan,
    TransactionNaming naming,
  ) {
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final digits = model.digitsOf(plan.currencyCode);
    final periods = plan.periods!;
    final left = plan.remainingMinor ?? BigInt.zero;
    final paid = plan.totalMinor - left;
    final ratio = plan.totalMinor <= BigInt.zero
        ? 0.0
        : (paid * BigInt.from(10000) ~/ plan.totalMinor).toInt() / 10000;
    final next = periods
        .where((p) => p.state == InstallmentPeriodState.upcoming)
        .firstOrNull;
    final wallet = naming.wallet(plan.accountId);
    final margin = context.screenMargin;
    final top = <Widget>[
      FreevaCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.installmentLeft,
                    style: FreevaTypography.label.copyWith(
                      fontWeight: FontWeight.w400,
                      color: c.textSecondary,
                    ),
                  ),
                ),
                if (!plan.active)
                  RecTag(
                    s.installmentClosedTag,
                    background: c.bgSubtle,
                    color: c.textSecondary,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  MoneyDisplay(
                    minor: left,
                    currency: plan.currencyCode,
                    minorDigits: digits,
                    style: FreevaTypography.moneyL.copyWith(
                      fontSize: 30,
                      height: 34 / 30,
                      letterSpacing: -0.9,
                    ),
                    currencySize: 15,
                    currencyColor: c.textOnWash,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.debtOfPrincipal(
                      formatMoneyText(plan.totalMinor, digits, locale),
                    ),
                    maxLines: 1,
                    style: FreevaTypography.bodyM.copyWith(
                      color: c.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FreevaProgressBar(
              value: ratio,
              color: c.tintVioletFg,
              height: 10,
              semanticsLabel: s.installmentLeft,
            ),
            const SizedBox(height: 12),
            Text(
              s.installmentPaidOf(
                plan.pastCount,
                plan.installmentCount,
                wallet,
              ),
              style: FreevaTypography.label.copyWith(
                fontWeight: FontWeight.w400,
                color: c.textSecondary,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      InstallmentGroup(
        children: [
          for (final p in periods)
            InstallmentPeriodTile(
              period: p,
              digits: digits,
              next: identical(p, next),
            ),
        ],
      ),
      const SizedBox(height: 14),
      Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          s.installmentEachAdds,
          style: FreevaTypography.bodyS.copyWith(
            height: 18 / 13,
            color: c.textSecondary,
          ),
        ),
      ),
    ];
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(margin, FreevaSpace.s2, margin, 0),
          sliver: SliverList.list(children: top),
        ),
        // Board: "Kết thúc trả góp" sits at the bottom of the screen.
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(margin, FreevaSpace.s6, margin, 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (plan.active) ...[
                  Center(
                    child: TextButton.icon(
                      onPressed: closing ? null : () => _close(plan),
                      icon: const Icon(LucideIcons.archive, size: 18),
                      label: Text(s.installmentClose),
                      style: TextButton.styleFrom(
                        foregroundColor: c.actionDanger,
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        textStyle: FreevaTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    s.installmentCloseSub,
                    textAlign: TextAlign.center,
                    style: FreevaTypography.bodyS.copyWith(
                      height: 18 / 13,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
