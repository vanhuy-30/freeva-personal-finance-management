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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: bar.name,
                            children: [
                              // "Ăn uống (chung)": the suffix in grey.
                              if (bar.general)
                                TextSpan(
                                  text: ' ${s.reportBarGeneralSuffix}',
                                  style: TextStyle(color: c.textSecondary),
                                ),
                            ],
                          ),
                          style: FreevaTypography.bodyM.copyWith(
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
                        style: FreevaTypography.bodyM.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  FreevaProgressBar(
                    value: detail.total == BigInt.zero
                        ? 0
                        : (bar.minor * BigInt.from(1000) ~/ detail.total)
                                  .toInt() /
                              1000,
                    trackColor: c.borderDivider,
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
