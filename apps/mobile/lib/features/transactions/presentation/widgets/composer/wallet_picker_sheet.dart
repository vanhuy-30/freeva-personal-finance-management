import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../../core/money/money_text.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../../../core/widgets/freeva_sheet.dart';
import '../../../../wallets/domain/wallet.dart';

/// Wallet picker: name and balance (masked when balances are hidden); the
/// chosen one shows a check. Picking closes the sheet.
Future<String?> showWalletPicker(
  BuildContext context, {
  required String title,
  String? subtitle,
  required List<Wallet> wallets,
  required String? selected,
  required int Function(String) digitsOf,
  required bool hideBalances,
}) => showFreevaSheet<String>(
  context: context,
  title: title,
  subtitle: subtitle,
  builder: (context) {
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    return SingleChildScrollView(
      child: Column(
        children: [
          for (final w in wallets.where((w) => !w.archived))
            InkWell(
              onTap: () => Navigator.of(context).pop(w.id),
              child: Container(
                height: FreevaSize.row,
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: c.listDivider)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c.tintBlue,
                        borderRadius: BorderRadius.circular(FreevaRadius.sm),
                      ),
                      child: Icon(
                        LucideIcons.wallet,
                        size: 18,
                        color: c.tintBlueFg,
                      ),
                    ),
                    const SizedBox(width: FreevaSpace.s3),
                    Expanded(
                      child: Text(
                        w.draft.name,
                        style: FreevaTypography.body.copyWith(
                          fontWeight: w.id == selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    if (w.id == selected)
                      Icon(LucideIcons.circleCheck, color: c.actionPrimary)
                    else
                      Text(
                        hideBalances
                            ? '••••••'
                            : '${formatMoneyText(w.balance, digitsOf(w.draft.currency), locale)} ${w.draft.currency == 'VND' ? '' : w.draft.currency}'
                                  .trim(),
                        style: FreevaTypography.bodyS.copyWith(
                          color: c.textSecondary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  },
);
