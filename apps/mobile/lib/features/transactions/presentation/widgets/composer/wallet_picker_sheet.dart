import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../../core/money/money_text.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../../../core/widgets/freeva_sheet.dart';
import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../wallets/domain/credit_card_status.dart';
import '../../../../wallets/domain/wallet.dart';
import '../../../../../core/money/currency_catalog.dart';

/// Wallet picker: name and balance (masked when balances are hidden); the
/// chosen one shows a check. Picking closes the sheet.
Future<String?> showWalletPicker(
  BuildContext context, {
  required String title,
  String? subtitle,
  required List<Wallet> wallets,
  required String? selected,
  required int Function(String) digitsOf,
  required bool hideBalances,
}) => showFreevaSheet<String>(
  context: context,
  title: title,
  subtitle: subtitle,
  builder: (context) {
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final s = S.of(context);
    return SingleChildScrollView(
      child: Column(
        children: [
          for (final w in wallets.where((w) => !w.archived))
            InkWell(
              onTap: () => Navigator.of(context).pop(w.id),
              child: Container(
                height: FreevaSize.row,
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: c.listDivider)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c.tintBlue,
                        borderRadius: BorderRadius.circular(FreevaRadius.sm),
                      ),
                      child: Icon(
                        LucideIcons.wallet,
                        size: 18,
                        color: c.tintBlueFg,
                      ),
                    ),
                    const SizedBox(width: FreevaSpace.s3),
                    Expanded(
                      child: Text(
                        w.draft.name,
                        style: FreevaTypography.body.copyWith(
                          fontWeight: w.id == selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    if (w.id == selected)
                      Icon(LucideIcons.circleCheck, color: c.actionPrimary)
                    else if (w.draft.type == WalletType.credit)
                      _CreditBalance(
                        status: CreditCardStatus.of(w, DateTime.now()),
                        digits: digitsOf(w.draft.currency),
                        locale: locale,
                        hidden: hideBalances,
                        debt: s.walletCreditDebt,
                        available: s.walletCreditAvailable,
                      )
                    else
                      Text(
                        hideBalances
                            ? '••••••'
                            : '${formatMoneyText(w.balance, digitsOf(w.draft.currency), locale)} ${w.draft.currency == CurrencyCatalog.current.defaultCode ? '' : w.draft.currency}'
                                  .trim(),
                        style: FreevaTypography.bodyS.copyWith(
                          color: c.textSecondary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  },
);

/// Credit card: what is owed and, with a limit, what can still be used.
class _CreditBalance extends StatelessWidget {
  const _CreditBalance({
    required this.status,
    required this.digits,
    required this.locale,
    required this.hidden,
    required this.debt,
    required this.available,
  });

  final CreditCardStatus status;
  final int digits;
  final String locale;
  final bool hidden;
  final String Function(String) debt;
  final String Function(String) available;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    String money(BigInt v) =>
        hidden ? '••••••' : formatMoneyText(v, digits, locale);
    final style = FreevaTypography.label.copyWith(
      color: c.textSecondary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final left = status.available;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(debt(money(status.used)), style: style),
        if (left != null) Text(available(money(left)), style: style),
      ],
    );
  }
}
