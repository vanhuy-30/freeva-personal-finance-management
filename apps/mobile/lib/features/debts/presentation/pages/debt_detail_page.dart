import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import '../../../../core/widgets/freeva_icon_button.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../../core/widgets/progress_bar.dart';
import '../../domain/personal_debt.dart';
import '../viewmodels/debt_view_model.dart';
import '../widgets/debt_parts.dart';
import '../widgets/debt_repay_sheet.dart';

/// One debt (DebtDetail): what is still owed of the amount, the details,
/// the history and "Ghi tiền nhận lại" / "Ghi tiền đã trả".
class DebtDetailPage extends StatefulWidget {
  const DebtDetailPage({required this.debtId, super.key});

  final String debtId;

  @override
  State<DebtDetailPage> createState() => _DebtDetailPageState();
}

class _DebtDetailPageState extends State<DebtDetailPage> {
  late final DebtViewModel model = getIt<DebtViewModel>();
  List<DebtPayment>? payments;
  bool _paymentsFailed = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!model.loaded) await model.load();
      await _loadPayments();
    });
  }

  Future<void> _loadPayments() async {
    final debt = model.byId(widget.debtId);
    if (debt == null) return;
    final items = await model.payments(debt);
    if (!mounted) return;
    setState(() {
      payments = items;
      _paymentsFailed = items == null;
    });
  }

  Future<void> _repay(PersonalDebt debt) async {
    final done = await showDebtRepaySheet(context, model, debt);
    if (done == true) await _loadPayments();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final debt = model.byId(widget.debtId);
        if (debt == null) {
          return Scaffold(
            appBar: FreevaTopBar(
              title: s.meDebts,
              onLeading: () => context.popOrGo('/me/debts'),
            ),
            body: model.loaded || model.failure != null
                ? ErrorRetry(
                    title: s.debtsLoadError,
                    message: s.homeErrorBody,
                    onRetry: model.load,
                  )
                : const SizedBox.shrink(),
          );
        }
        final margin = context.screenMargin;
        return Scaffold(
          appBar: FreevaTopBar(
            title: debt.counterparty,
            onLeading: () => context.popOrGo('/me/debts'),
            action: FreevaIconButton(
              icon: LucideIcons.penLine,
              iconSize: FreevaSize.iconSm,
              label: s.debtEditTitle,
              onPressed: () => context.push('/me/debts/${debt.id}/edit'),
            ),
          ),
          body: Column(
            children: [
              Expanded(child: _body(context, s, debt)),
              if (!debt.settled)
                Padding(
                  padding: EdgeInsets.fromLTRB(margin, 0, margin, 28),
                  child: FreevaButton(
                    label: debt.lent ? s.debtRecordReceived : s.debtRecordPaid,
                    size: FreevaButtonSize.l,
                    expand: true,
                    onPressed: () => _repay(debt),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, S s, PersonalDebt debt) {
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final digits = model.digitsOf(debt.currencyCode);
    String money(BigInt value) => formatMoneyText(value, digits, locale);
    String walletName(String id) => model.wallet(id)?.draft.name ?? '—';
    final tag = debt.settled
        ? null
        : dueTag(context, model.today, debt.dueDate);
    final note = debt.note?.trim();
    final history = <Widget>[
      for (final p in (payments ?? const <DebtPayment>[]).reversed)
        DebtHistoryRow(
          icon: debt.lent
              ? LucideIcons.arrowDownToLine
              : LucideIcons.arrowUpToLine,
          title: debt.lent ? s.debtTheyPaid(debt.counterparty) : s.debtYouPaid,
          subtitle: debt.lent
              ? s.debtInto(debtDay(p.paidOn), walletName(p.accountId))
              : s.debtOutOf(debtDay(p.paidOn), walletName(p.accountId)),
          amount: '${debt.lent ? '+' : '−'}${money(p.amountMinor)}',
          incoming: debt.lent,
        ),
      if (payments != null)
        DebtHistoryRow(
          icon: debt.lent
              ? LucideIcons.arrowUpToLine
              : LucideIcons.arrowDownToLine,
          title: debt.lent ? s.debtLend : s.debtHistoryBorrowed,
          subtitle: debt.lent
              ? s.debtOutOf(
                  debtDay(debt.occurredOn),
                  walletName(debt.accountId),
                )
              : s.debtInto(
                  debtDay(debt.occurredOn),
                  walletName(debt.accountId),
                ),
          amount: '${debt.lent ? '−' : '+'}${money(debt.principalMinor)}',
          incoming: !debt.lent,
        ),
    ];
    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.screenMargin,
        FreevaSpace.s2,
        context.screenMargin,
        14,
      ),
      children: [
        FreevaCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  NameAvatar(name: debt.counterparty, size: 44),
                  const Spacer(),
                  if (tag != null) tag,
                ],
              ),
              const SizedBox(height: 12),
              Text(
                debt.settled
                    ? s.debtsGroupSettled
                    : debt.lent
                    ? s.debtTheyOwe(debt.counterparty)
                    : s.debtYouOweName(debt.counterparty),
                style: FreevaTypography.label.copyWith(
                  fontWeight: FontWeight.w400,
                  color: c.textSecondary,
                ),
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
                      minor: debt.outstandingMinor,
                      currency: debt.currencyCode,
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
                      s.debtOfPrincipal(money(debt.principalMinor)),
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
                value: debt.progress,
                color: c.moneyIncome,
                height: 10,
                semanticsLabel: debt.counterparty,
              ),
              const SizedBox(height: 12),
              Text(
                debt.lent
                    ? s.debtReceived(money(debt.paidMinor))
                    : s.debtPaid(money(debt.paidMinor)),
                style: FreevaTypography.label.copyWith(
                  fontWeight: FontWeight.w400,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        DebtCard(
          children: [
            DebtInfoRow(
              label: debt.lent ? s.debtLentDate : s.debtBorrowedDate,
              value: debtDay(debt.occurredOn),
            ),
            DebtInfoRow(
              label: s.debtDueDate,
              value: debt.dueDate == null
                  ? s.debtNoDueValue
                  : debtDay(debt.dueDate!),
            ),
            DebtInfoRow(
              label: debt.lent ? s.debtFromWalletShort : s.debtToWallet,
              value: walletName(debt.accountId),
            ),
            if (note != null && note.isNotEmpty)
              DebtInfoRow(label: s.debtNote, value: note),
          ],
        ),
        if (history.isNotEmpty) ...[
          const SizedBox(height: 14),
          DebtGroup(label: s.debtHistory, children: history),
        ] else if (_paymentsFailed) ...[
          const SizedBox(height: 14),
          Center(
            child: TextButton(
              onPressed: _loadPayments,
              child: Text(s.commonRetry),
            ),
          ),
        ],
      ],
    );
  }
}
