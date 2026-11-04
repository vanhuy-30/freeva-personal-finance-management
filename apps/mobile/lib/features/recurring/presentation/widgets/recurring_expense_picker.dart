import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_sheet.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../viewmodels/recurring_view_model.dart';
import 'recurring_labels.dart';

/// Recent expenses to link as the payment of a bill. Returns the chosen
/// transaction id, or null when nothing was picked.
Future<String?> showRecurringExpensePicker(
  BuildContext context,
  RecurringViewModel model,
) async {
  final s = S.of(context);
  final legs = await model.recentExpenses();
  if (!context.mounted) return null;
  if (legs == null) {
    showFreevaToast(context, message: s.meSaveError);
    return null;
  }
  if (legs.isEmpty) {
    showFreevaToast(context, message: s.recNoExpense);
    return null;
  }
  final locale = Localizations.localeOf(context).toString();
  return showFreevaSheet<String>(
    context: context,
    title: s.recPickExpense,
    builder: (context) {
      final c = context.colors;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final leg in legs)
            InkWell(
              onTap: () => Navigator.of(context).pop(leg.id),
              child: Container(
                constraints: const BoxConstraints(minHeight: FreevaSize.row),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: c.listDivider)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${formatMoneyText(leg.amountMinor.abs(), model.digitsOf(leg.currencyCode), locale)} ${leg.currencyCode}',
                            style: FreevaTypography.body.copyWith(
                              fontWeight: FontWeight.w500,
                              color: c.textPrimary,
                            ),
                          ),
                          Text(
                            [
                              dayMonth(leg.occurredOn),
                              if (leg.merchant != null) leg.merchant!,
                            ].join(' · '),
                            style: FreevaTypography.bodyS.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}
