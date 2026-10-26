import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../../../core/widgets/freeva_sheet.dart';
import '../../../domain/wallet.dart';

/// Currency picker; the chosen code shows a check. Picking closes the sheet.
Future<String?> showCurrencyPicker(
  BuildContext context, {
  required List<WalletCurrency> currencies,
  required String selected,
}) => showFreevaSheet<String>(
  context: context,
  title: S.of(context).walletCurrencyTitle,
  builder: (context) {
    final c = context.colors;
    return SingleChildScrollView(
      child: Column(
        children: [
          for (final currency in currencies)
            Semantics(
              container: true,
              button: true,
              selected: currency.code == selected,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(currency.code),
                child: Container(
                  height: FreevaSize.row,
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: c.listDivider)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          currency.code,
                          style: FreevaTypography.body.copyWith(
                            fontWeight: currency.code == selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      if (currency.code == selected)
                        Icon(LucideIcons.circleCheck, color: c.actionPrimary),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  },
);
