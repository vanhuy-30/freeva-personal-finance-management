import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../reports/domain/report.dart';

/// One tappable line on the balance card: a currency left out of the
/// converted total, or the action that changes the display currency. Same
/// shape as the other-currency pill: white 72%, [FreevaSize.pill] high.
class ConvertLine extends StatelessWidget {
  const ConvertLine({
    required this.text,
    required this.semanticsLabel,
    required this.onTap,
    super.key,
  });

  final String text;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Material(
        color: c.bgSurface.withValues(alpha: .72),
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: FreevaSpace.s3),
            child: SizedBox(
              height: FreevaSize.pill,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FreevaTypography.label.copyWith(
                        color: c.textOnWash,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    LucideIcons.chevronRight,
                    size: FreevaSize.iconXs,
                    color: c.textOnWash,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "USD: chưa có tỷ giá, chạm để nhập" for a currency that is not in the
/// converted total.
String unconvertedText(S s, UnconvertedCurrency item) =>
    switch (item.reason) {
      UnconvertedReason.missingRate => s.homeUnconvertedMissing(item.currency),
      UnconvertedReason.fractional => s.homeUnconvertedFractional(
        item.currency,
      ),
    };
