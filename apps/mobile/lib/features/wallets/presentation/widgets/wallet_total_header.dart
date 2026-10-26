import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/money_display.dart';
import '../../domain/wallet_totals.dart';

/// "Tổng số dư · 4 ví" with the main-currency total, other currencies on a
/// small line, and the "Sắp xếp" link when there is something to sort.
class WalletTotalHeader extends StatelessWidget {
  const WalletTotalHeader({
    required this.totals,
    required this.digitsOf,
    required this.hidden,
    this.onSort,
    super.key,
  });

  /// Main currency first (see [walletTotals]).
  final List<WalletTotal> totals;
  final int Function(String) digitsOf;
  final bool hidden;
  final VoidCallback? onSort;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final main = totals.first;
    final others = totals.skip(1).map((t) {
      final amount = hidden
          ? '•••••• ${t.currency}'
          : '${formatMoneyText(t.minor, digitsOf(t.currency), locale)} '
                '${t.currency}';
      return s.walletOtherTotal(amount, t.count);
    }).toList();
    final secondary = FreevaTypography.bodyS.copyWith(color: c.textSecondary);
    // The board lines "Sắp xếp" up with the label line (baseline); its 36
    // box pushes the label down. Ours keeps the 44 touch height, so the top
    // padding is tuned to land the label where the board has it.
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 7, 4, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.walletTotal(main.count), style: secondary),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: MoneyDisplay(
                    minor: main.minor,
                    currency: main.currency,
                    minorDigits: digitsOf(main.currency),
                    style: FreevaTypography.moneyL,
                    hidden: hidden,
                  ),
                ),
                for (final line in others) Text(line, style: secondary),
              ],
            ),
          ),
          if (onSort != null)
            Semantics(
              button: true,
              child: InkWell(
                onTap: onSort,
                borderRadius: BorderRadius.circular(FreevaRadius.full),
                child: SizedBox(
                  height: FreevaSize.touch,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.arrowUpDown,
                          size: FreevaSize.iconChip,
                          color: c.actionPrimary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          s.walletSort,
                          style: FreevaTypography.bodyM.copyWith(
                            fontWeight: FontWeight.w500,
                            color: c.actionPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
