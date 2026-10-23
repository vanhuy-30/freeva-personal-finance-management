import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../../core/widgets/progress_bar.dart';
import '../../domain/category_detail.dart';

/// One bar per child category, each against the slice total. A parent's own
/// transactions read "Ăn uống (chung)" when it also has children.
class CategoryBars extends StatelessWidget {
  const CategoryBars({
    required this.detail,
    required this.currency,
    required this.digits,
    super.key,
  });

  final CategoryDetail detail;
  final String currency;
  final int digits;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return FreevaCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Column(
        children: [
          for (final (i, bar) in detail.bars.indexed)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: i == 0
                    ? null
                    : Border(top: BorderSide(color: c.borderDivider)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          bar.general ? s.reportBarGeneral(bar.name) : bar.name,
                          style: FreevaTypography.body.copyWith(
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      MoneyDisplay(
                        minor: bar.minor,
                        currency: currency,
                        minorDigits: digits,
                        showCurrency: false,
                        style: FreevaTypography.titleM,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  FreevaProgressBar(
                    value: detail.total == BigInt.zero
                        ? 0
                        : (bar.minor * BigInt.from(1000) ~/ detail.total) / 1000,
                    semanticsLabel: bar.name,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
