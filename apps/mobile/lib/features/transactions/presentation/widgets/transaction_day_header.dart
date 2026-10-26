import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../domain/transaction.dart';

/// "Hôm nay · 21/10" ··· "−168.000". Net of income and expense per
/// currency; transfers are left out.
class TransactionDayHeader extends StatelessWidget {
  const TransactionDayHeader({
    required this.date,
    required this.today,
    required this.rows,
    required this.mainCurrency,
    required this.digitsOf,
    this.showNet = true,
    super.key,
  });

  final String date;
  final String today;
  final List<TransactionBundle> rows;
  final String mainCurrency;
  final int Function(String) digitsOf;

  /// False on search and deleted lists: the day label only.
  final bool showNet;

  /// Day label: "Hôm nay · 21/10" or "Thứ Hai · 20/10".
  static String label(S s, String date, String today, String locale) {
    final day = DateTime.parse(date);
    final short = DateFormat('dd/MM', locale).format(day);
    final name = date == today
        ? s.txToday
        : _titleCase(DateFormat('EEEE', locale).format(day));
    return s.txDayHeader(name, short);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final net = <String, BigInt>{};
    for (final row in rows) {
      if (row.type == TransactionType.transfer) continue;
      final leg = row.legs.first;
      net.update(
        leg.currencyCode,
        (v) => v + leg.amountMinor,
        ifAbsent: () => leg.amountMinor,
      );
    }
    String sign(BigInt v) => v > BigInt.zero
        ? '+'
        : v < BigInt.zero
        ? '−'
        : '';
    final parts = [
      for (final MapEntry(key: code, value: minor) in net.entries)
        '${sign(minor)}${formatMoneyText(minor.abs(), digitsOf(code), locale)}'
            '${code == mainCurrency ? '' : ' $code'}',
    ];
    final style = FreevaTypography.bodyS.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, FreevaSpace.s2),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                label(s, date, today, locale),
                style: style.copyWith(
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
            ),
          ),
          if (showNet)
            Text(
              parts.join(' · '),
              style: style.copyWith(color: c.textSecondary),
            ),
        ],
      ),
    );
  }
}

/// "thứ hai" → "Thứ Hai" (Vietnamese weekday names are two words).
String _titleCase(String text) => text
    .split(' ')
    .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
    .join(' ');
