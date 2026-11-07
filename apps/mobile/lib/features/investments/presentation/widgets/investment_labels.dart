import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../domain/investment.dart';

String investmentKindName(S s, InvestmentKind kind) =>
    s.investmentKind(kind.apiValue);

IconData investmentKindIcon(InvestmentKind kind) => switch (kind) {
  InvestmentKind.gold => LucideIcons.coins,
  InvestmentKind.stock => LucideIcons.chartCandlestick,
  InvestmentKind.fund => LucideIcons.layers,
  InvestmentKind.savingsDeposit => LucideIcons.piggyBank,
  InvestmentKind.realEstate => LucideIcons.building2,
  InvestmentKind.crypto => LucideIcons.bitcoin,
};

/// Tile background and glyph colour of a kind, from the theme tints.
(Color, Color) investmentKindTint(FreevaColors c, InvestmentKind kind) =>
    switch (kind) {
      InvestmentKind.gold => (c.statusWarningBg, c.statusWarning),
      InvestmentKind.stock => (c.tintBlue, c.tintBlueFg),
      InvestmentKind.fund => (c.tintViolet, c.tintVioletFg),
      InvestmentKind.savingsDeposit => (c.tintGreen, c.tintGreenFg),
      InvestmentKind.realEstate => (c.tintBlue, c.tintBlueFg),
      InvestmentKind.crypto => (c.bgSubtle, c.textSecondary),
    };

/// Slice colour of a kind in the share ring and its legend.
Color investmentKindColor(FreevaColors c, InvestmentKind kind) =>
    switch (kind) {
      InvestmentKind.gold => c.statusWarning,
      InvestmentKind.stock => c.actionPrimary,
      InvestmentKind.fund => c.tintVioletFg,
      InvestmentKind.savingsDeposit => c.tintGreenFg,
      InvestmentKind.realEstate => c.tintBlueFg,
      InvestmentKind.crypto => c.textSecondary,
    };

/// Basis points as a percentage with one decimal, no float: 829 → "8,3%".
/// Rounds half away from zero; the sign is not included.
String investmentPercent(int bps, String locale) {
  final tenths = (bps.abs() + 5) ~/ 10;
  final sep = NumberFormat.decimalPattern(locale).symbols.DECIMAL_SEP;
  return '${tenths ~/ 10}$sep${tenths % 10}%';
}

/// "▲ 8,3%" or "▼ 3,2%"; zero has no arrow.
String investmentPill(int bps, String locale) {
  final text = investmentPercent(bps, locale);
  return bps == 0 ? text : '${bps < 0 ? '▼' : '▲'} $text';
}

/// Profit or loss amount with its sign: "+50.000.000", "−450.000".
String investmentSigned(BigInt minor, int digits, String locale) {
  final sign = minor.isNegative ? '−' : (minor == BigInt.zero ? '' : '+');
  return '$sign${formatMoneyText(minor.abs(), digits, locale)}';
}
