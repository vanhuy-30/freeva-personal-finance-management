import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../money/display_converted.dart';
import '../money/money_text.dart';
import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';

/// "≈ 308.500 VND" with "1 USD = 25.000 VND · tỷ giá bạn nhập lúc 09:00,
/// 30/10" under it. Display only; the original amount stays the real one.
class ConvertedNote extends StatelessWidget {
  const ConvertedNote({
    required this.value,
    required this.from,
    required this.minorDigits,
    this.hidden = false,
    this.color,
    this.textAlign = TextAlign.start,
    super.key,
  });

  final DisplayConverted value;

  /// Currency of the original amount.
  final String from;

  /// Minor digits of [DisplayConverted.currency].
  final int minorDigits;

  /// Masks the number the way balances are masked.
  final bool hidden;
  final Color? color;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final locale = Localizations.localeOf(context).toString();
    final tone = color ?? context.colors.textSecondary;
    final amount = hidden
        ? '••••••'
        : formatMoneyText(value.minor, minorDigits, locale);
    final when = value.quotedAt.toLocal();
    final time =
        '${_two(when.hour)}:${_two(when.minute)}, ${_two(when.day)}/${_two(when.month)}';
    final line1 = '${s.convertedAmount(amount)} ${value.currency}';
    final line2 = s.convertedRateLine(from, value.rate, value.currency, time);
    return Semantics(
      label: '$line1. $line2',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: switch (textAlign) {
          TextAlign.center => CrossAxisAlignment.center,
          TextAlign.end || TextAlign.right => CrossAxisAlignment.end,
          _ => CrossAxisAlignment.start,
        },
        children: [
          Text(
            line1,
            textAlign: textAlign,
            style: FreevaTypography.bodyM.copyWith(
              fontWeight: FontWeight.w600,
              color: tone,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            line2,
            textAlign: textAlign,
            style: FreevaTypography.label.copyWith(color: tone),
          ),
        ],
      ),
    );
  }
}

String _two(int value) => value.toString().padLeft(2, '0');
