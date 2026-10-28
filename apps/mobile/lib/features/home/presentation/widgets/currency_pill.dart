import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../domain/overview.dart';

/// Other-currency pill on the balance card: "1.250,00" (14/600) · "USD · 1 ví"
/// (12/500 on-wash) · chevron. 32 high, white 72%.
class CurrencyPill extends StatelessWidget {
  const CurrencyPill({
    required this.balance,
    required this.minorDigits,
    required this.hidden,
    required this.onTap,
    super.key,
  });

  final CurrencyBalance balance;
  final int minorDigits;
  final bool hidden;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final amount = hidden
        ? '••••••'
        : formatMoneyText(balance.minor, minorDigits, locale);
    final meta = s.homeOtherCurrencyMeta(balance.currency, balance.walletCount);
    return Semantics(
      button: true,
      label: hidden
          ? '${s.balanceHiddenSemantics}, ${balance.currency}'
          : s.homeOtherCurrency(amount, balance.currency, balance.walletCount),
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
                  Text(
                    amount,
                    maxLines: 1,
                    style: FreevaTypography.bodyM.copyWith(
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      meta,
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
