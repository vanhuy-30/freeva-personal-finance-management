import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';
import 'money_display.dart';
import 'tag_chip.dart';

/// Transaction row: 40 round icon · title + "category · wallet" · signed
/// amount without ₫. Up to two tag chips replace the second line's tail.
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

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (iconBg, iconFg) = switch (tone) {
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
                        color: iconBg,
                      ),
                      child: Icon(
                        icon,
                        size: FreevaSize.iconInline,
                        color: iconFg,
                      ),
                    ),
                    const SizedBox(width: FreevaSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FreevaTypography.body.copyWith(
                              fontWeight: FontWeight.w500,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: FreevaTypography.label.copyWith(
                                    fontWeight: FontWeight.w400,
                                    color: c.textSecondary,
                                  ),
                                ),
                              ),
                              for (final tag in tags.take(2)) TagChip(tag),
                            ],
                          ),
                        ],
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
