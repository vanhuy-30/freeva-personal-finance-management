import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_sheet.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../../core/widgets/settings_group.dart';
import '../../../auth/presentation/widgets/auth_message.dart';
import 'shown_balances.dart';
import '../../domain/investment.dart';
import '../viewmodels/investment_view_model.dart';
import 'investment_wallet_list.dart';

String _money(
  InvestmentViewModel model,
  Investment deposit,
  BigInt minor,
  String locale,
) {
  final digits = model.digitsOf(deposit.currencyCode);
  return '${formatMoneyText(minor, digits, locale)} ${MoneyDisplay.symbolFor(deposit.currencyCode)}';
}

/// Tells the user which matured deposits were paid back to their wallets.
Future<void> showMaturedPaidSheet(
  BuildContext context,
  InvestmentViewModel model,
  List<MaturedPayout> payouts,
) {
  final s = S.of(context);
  final c = context.colors;
  final locale = Localizations.localeOf(context).toString();
  return showFreevaSheet<void>(
    context: context,
    title: s.depositMaturedPaidTitle,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final payout in payouts)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                s.depositMaturedPaidBody(
                  payout.deposit.name,
                  _money(model, payout.deposit, payout.amountMinor, locale),
                  payout.walletName,
                ),
                style: FreevaTypography.bodyM.copyWith(color: c.textPrimary),
              ),
            ),
          const SizedBox(height: 6),
          FreevaButton(
            label: s.commonClose,
            size: FreevaButtonSize.l,
            expand: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    ),
  );
}

/// A matured deposit held before the app: send the payout to a wallet or
/// deposit it again. Dismissing it asks again next time the app opens.
Future<void> showMaturedChoiceSheet(
  BuildContext context,
  InvestmentViewModel model,
  Investment deposit,
) {
  final s = S.of(context);
  return showFreevaSheet<void>(
    context: context,
    title: s.depositMaturedChoiceTitle,
    builder: (context) => _ChoiceSheet(model: model, deposit: deposit),
  );
}

class _ChoiceSheet extends StatefulWidget {
  const _ChoiceSheet({required this.model, required this.deposit});

  final InvestmentViewModel model;
  final Investment deposit;

  @override
  State<_ChoiceSheet> createState() => _ChoiceSheetState();
}

class _ChoiceSheetState extends State<_ChoiceSheet> {
  late final List wallets = [
    for (final w in widget.model.wallets)
      if (w.draft.currency == widget.deposit.currencyCode) w,
  ];
  late String? walletId = wallets.firstOrNull?.id;
  bool saving = false;

  /// Kept while the sheet is open so a resend never records it twice.
  late final String clientId = widget.model.newClientId();

  Future<void> _run(Future<bool> Function() action) async {
    final s = S.of(context);
    setState(() => saving = true);
    final ok = await action();
    if (!mounted) return;
    setState(() => saving = false);
    if (ok) {
      Navigator.of(context).pop();
      return;
    }
    final failure = widget.model.failure;
    showFreevaToast(
      context,
      message: failure == null ? s.meSaveError : authFailureText(s, failure),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final model = widget.model;
    final deposit = widget.deposit;
    final payout = model.maturityPayout(deposit);
    return ShownBalances(
      builder: (context, hidden) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.depositMaturedChoiceBody(
                deposit.name,
                hidden ? '••••••' : _money(model, deposit, payout, locale),
              ),
              style: FreevaTypography.bodyM.copyWith(color: c.textSecondary),
            ),
            if (wallets.isNotEmpty) ...[
              SectionHeader(s.depositToWallet),
              InvestmentWalletList(
                wallets: [for (final w in wallets) w],
                selected: walletId,
                digitsOf: model.digitsOf,
                hidden: hidden,
                allowExisting: false,
                onChanged: (id) => setState(() => walletId = id),
              ),
              const SizedBox(height: 16),
              FreevaButton(
                label: s.depositMaturedToWallet,
                size: FreevaButtonSize.l,
                expand: true,
                loading: saving,
                onPressed: saving || walletId == null
                    ? null
                    : () => _run(
                        () => model.withdraw(
                          deposit,
                          amountMinor: payout,
                          accountId: walletId!,
                          tradedOn: deposit.maturityDate!,
                          clientId: clientId,
                        ),
                      ),
              ),
              const SizedBox(height: 8),
            ] else
              const SizedBox(height: 16),
            FreevaButton(
              label: s.depositMaturedRenew,
              size: FreevaButtonSize.l,
              expand: true,
              variant: wallets.isEmpty
                  ? FreevaButtonVariant.primary
                  : FreevaButtonVariant.secondary,
              onPressed: saving
                  ? null
                  : () => _run(() => model.renewDeposit(deposit)),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: saving ? null : () => Navigator.of(context).pop(),
              child: Text(
                s.depositMaturedLater,
                style: FreevaTypography.bodyM.copyWith(
                  fontWeight: FontWeight.w600,
                  color: c.textLink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
