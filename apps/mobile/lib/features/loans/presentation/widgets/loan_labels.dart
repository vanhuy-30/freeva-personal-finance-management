import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../domain/loan.dart';

/// Kinds the app lets you pick, in chip order.
const pickableLoanKinds = [
  LoanKind.mortgage,
  LoanKind.personal,
  LoanKind.other,
];

String loanKindLabel(S s, LoanKind kind) => switch (kind) {
  LoanKind.mortgage => s.loanKindMortgage,
  LoanKind.personal => s.loanKindPersonal,
  LoanKind.other || LoanKind.card => s.loanKindOther,
};

IconData loanKindIcon(LoanKind kind) => switch (kind) {
  LoanKind.mortgage => LucideIcons.house,
  LoanKind.personal => LucideIcons.wallet,
  LoanKind.other || LoanKind.card => LucideIcons.star,
};

/// Fill and glyph of the kind tile.
(Color, Color) loanKindTint(BuildContext context, LoanKind kind) {
  final c = context.colors;
  return switch (kind) {
    LoanKind.mortgage => (c.tintBlue, c.tintBlueFg),
    LoanKind.personal => (c.tintViolet, c.tintVioletFg),
    LoanKind.other || LoanKind.card => (c.bgSubtle, c.textOnWash),
  };
}

String loanFrequencyLabel(S s, LoanFrequency f) => switch (f) {
  LoanFrequency.weekly => s.loanFreqWeekly,
  LoanFrequency.monthly => s.loanFreqMonthly,
  LoanFrequency.quarterly => s.loanFreqQuarterly,
  LoanFrequency.yearly => s.loanFreqYearly,
};

/// "12" / "9,5" for the current locale.
String loanRate(BuildContext context, int bps) => formatRate(
  bps,
  Localizations.localeOf(context).languageCode == 'vi' ? ',' : '.',
);

/// `yyyy-MM-dd` as `MM/yyyy`.
String monthYear(String day) => '${day.substring(5, 7)}/${day.substring(0, 4)}';

/// Kind tile: [size] square, radius 12, glyph 19.
class LoanKindTile extends StatelessWidget {
  const LoanKindTile({required this.kind, this.size = 40, super.key});

  final LoanKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = loanKindTint(context, kind);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(loanKindIcon(kind), size: 19, color: fg),
      ),
    );
  }
}
