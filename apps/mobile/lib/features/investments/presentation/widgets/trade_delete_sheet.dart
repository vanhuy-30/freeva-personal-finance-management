import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/freeva_sheet.dart';
import 'investment_labels.dart';

/// "Xoá lần mua 10/09?" (board P.8): what goes away and what comes back to
/// the wallet. True when the user confirms.
Future<bool> showTradeDeleteSheet(
  BuildContext context, {
  required String date,
  required String line,
  required String? walletName,
  required BigInt amountMinor,
  required int digits,
}) async {
  final s = S.of(context);
  final yes = await showFreevaSheet<bool>(
    context: context,
    builder: (context) {
      final c = context.colors;
      final locale = Localizations.localeOf(context).toString();
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.statusDangerBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SizedBox.square(
                  dimension: 44,
                  child: Icon(
                    LucideIcons.trash,
                    size: 20,
                    color: c.statusDanger,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              s.tradeDeleteTitle(date),
              textAlign: TextAlign.center,
              style: FreevaTypography.titleL.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              line,
              textAlign: TextAlign.center,
              style: FreevaTypography.bodyM.copyWith(color: c.textSecondary),
            ),
            if (walletName != null) ...[
              const SizedBox(height: 16),
              FreevaCard(
                list: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.tradeRefund(walletName),
                        style: FreevaTypography.bodyM.copyWith(
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      investmentSigned(amountMinor, digits, locale),
                      style: FreevaTypography.bodyM.copyWith(
                        fontWeight: FontWeight.w600,
                        color: c.moneyIncome,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            FreevaButton(
              label: s.tradeDeleteConfirm,
              size: FreevaButtonSize.l,
              expand: true,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 10),
            FreevaButton(
              label: s.tradeKeep,
              variant: FreevaButtonVariant.secondary,
              size: FreevaButtonSize.l,
              expand: true,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      );
    },
  );
  return yes ?? false;
}
