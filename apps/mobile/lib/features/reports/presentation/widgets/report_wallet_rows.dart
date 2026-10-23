import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../wallets/domain/wallet.dart';
import '../../../wallets/presentation/widgets/wallet_type_icon.dart';
import '../../domain/report.dart';

/// "Ví" tab: what came in and went out of each wallet, and the net. Tap opens
/// the wallet. Transfers between wallets appear only when there are any.
class ReportWalletRows extends StatelessWidget {
  const ReportWalletRows({required this.rows, required this.digits, super.key});

  final List<CashflowAccountRow> rows;
  final int digits;

  @override
  Widget build(BuildContext context) => Column(
    children: [for (final row in rows) _WalletRow(row: row, digits: digits)],
  );
}

class _WalletRow extends StatelessWidget {
  const _WalletRow({required this.row, required this.digits});

  final CashflowAccountRow row;
  final int digits;

  String _flow(S s, String locale) {
    String amount(BigInt minor) => formatMoneyText(minor.abs(), digits, locale);
    final move = row.transferMinor;
    // Only the " · " between parts may wrap, never the space inside one.
    return [
      if (row.incomeMinor != BigInt.zero)
        s.reportFlowIn(amount(row.incomeMinor)),
      if (row.expenseMinor != BigInt.zero)
        s.reportFlowOut(amount(row.expenseMinor)),
      if (move != BigInt.zero)
        s.reportFlowTransfer('${move.isNegative ? '−' : '+'}${amount(move)}'),
    ].map((part) => part.replaceAll(' ', '\u00A0')).join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final flow = _flow(
      S.of(context),
      Localizations.localeOf(context).toString(),
    );
    return Semantics(
      button: true,
      container: true,
      child: InkWell(
        onTap: () => context.push('/wallets/${row.accountId}'),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              WalletTypeIcon(type: row.type ?? WalletType.cash),
              const SizedBox(width: FreevaSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.name ?? '',
                      style: FreevaTypography.body.copyWith(
                        fontWeight: FontWeight.w500,
                        color: c.textPrimary,
                      ),
                    ),
                    if (flow.isNotEmpty)
                      Text(
                        flow,
                        style: FreevaTypography.label.copyWith(
                          color: c.textSecondary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              MoneyDisplay(
                minor: row.netMinor,
                currency: row.currency,
                minorDigits: digits,
                showCurrency: false,
                tone: row.netMinor > BigInt.zero
                    ? MoneyTone.income
                    : MoneyTone.plain,
                style: FreevaTypography.titleM,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
