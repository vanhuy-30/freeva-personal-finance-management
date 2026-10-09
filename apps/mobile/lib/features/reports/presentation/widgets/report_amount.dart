import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../wallets/domain/wallet.dart';
import 'report_money.dart';

enum ReportTone { income, expense }

class ReportAmountText extends StatelessWidget {
  const ReportAmountText({
    required this.label,
    required this.minor,
    required this.currency,
    required this.currencies,
    this.tone,
    super.key,
  });

  final String label;
  final BigInt minor;
  final String currency;
  final List<WalletCurrency> currencies;
  final ReportTone? tone;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final amount = formatReportMoney(
      minor,
      currency,
      currencies,
      Localizations.localeOf(context).toString(),
    );
    final color = switch (tone) {
      ReportTone.income => AppColors.success,
      ReportTone.expense => AppColors.danger,
      null => null,
    };
    return Text(
      s.reportAmount(label, amount ?? '', currency),
      style: TextStyle(color: color),
    );
  }
}
