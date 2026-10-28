import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';
import 'money_display.dart';
import 'transaction_row_text.dart';

/// Transaction row: 40 round icon · title + "category · wallet" · signed
/// amount without ₫. Up to two tag chips replace the second line's tail.
/// The category glyph is 18 px in the circle.
class TransactionRow extends StatelessWidget {
  const TransactionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.semanticsLabel,
    this.tone = MoneyTone.expense,
    this.tags = const [],
    this.onTap,
    this.highlight,
    this.trailing,
    this.muted = false,
    this.iconBg,
    this.iconColor,
    this.subtitleWidget,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  /// Usually a [MoneyDisplay] with `showCurrency: false`.
  final Widget amount;

  /// Full spoken form, e.g. "trừ 65 nghìn đồng, Phở Thìn, ăn uống, hôm nay".
  final String semanticsLabel;
  final MoneyTone tone;
  final List<String> tags;
  final VoidCallback? onTap;

  /// Search text to mark in the title and second line.
  final String? highlight;

  /// Extra action after the amount (restore button on the deleted list).
  final Widget? trailing;

  /// Deleted rows: neutral circle, glyph in `text.secondary`.
  final bool muted;

  /// Overrides the circle background picked from [tone].
  final Color? iconBg;

  /// Overrides the glyph colour picked from [tone].
  final Color? iconColor;

  /// Replaces the second line (see [TransactionRowNote]).
  final Widget? subtitleWidget;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (toneBg, toneFg) = muted
        ? (c.bgSubtle, c.textSecondary)
        : switch (tone) {
            MoneyTone.income => (c.tintGreen, c.tintGreenFg),
            MoneyTone.transfer => (c.tintBlue, c.tintBlueFg),
            _ => (c.bgSubtle, c.textPrimary),
          };
    return Semantics(
      label: semanticsLabel,
      button: onTap != null,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: FreevaSize.row),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: FreevaSpace.s3),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxAmountWidth = constraints.maxWidth / 2;
                return Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: iconBg ?? toneBg,
                      ),
                      child: Icon(
                        icon,
                        size: FreevaSize.iconSm,
                        color: iconColor ?? toneFg,
                      ),
                    ),
                    const SizedBox(width: FreevaSpace.s3),
                    Expanded(
                      child: TransactionRowText(
                        title: title,
                        subtitle: subtitle,
                        tags: tags,
                        highlight: highlight,
                        subtitleWidget: subtitleWidget,
                      ),
                    ),
                    const SizedBox(width: FreevaSpace.s3),
                    // Large amounts shrink instead of truncating with "…".
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxAmountWidth),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: amount,
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: FreevaSpace.s3),
                      trailing!,
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
