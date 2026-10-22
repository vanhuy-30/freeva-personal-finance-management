import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/money_display.dart';
import '../../domain/transaction.dart';
import '../viewmodels/transaction_view_model.dart';
import 'delete_circle_button.dart';
import 'transaction_detail_card.dart';
import 'transaction_naming.dart';

enum DetailAction { edit, copy, delete }

class TransactionDetailBody extends StatelessWidget {
  const TransactionDetailBody({
    required this.model,
    required this.bundle,
    required this.naming,
    super.key,
  });

  final TransactionViewModel model;
  final TransactionBundle bundle;
  final TransactionNaming naming;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final label = naming.label(bundle);
    final digits =
        model.currencies
            .where((x) => x.code == label.currency)
            .map((x) => x.minorDigits)
            .firstOrNull ??
        0;
    void close(DetailAction a) => Navigator.of(context).pop(a);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.bgSubtle,
              ),
              child: Icon(
                label.icon,
                size: FreevaSize.iconInline,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(width: FreevaSpace.s3),
            Expanded(
              child: Text(
                label.title,
                style: FreevaTypography.titleL.copyWith(color: c.textPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: FreevaSpace.s3),
        MoneyDisplay(
          minor: label.minor,
          currency: label.currency,
          minorDigits: digits,
          tone: label.tone,
          style: FreevaTypography.moneyL,
        ),
        const SizedBox(height: FreevaSpace.s4),
        TransactionDetailCard(
          bundle: bundle,
          label: label,
          naming: naming,
          today: model.today(),
        ),
        const SizedBox(height: FreevaSpace.s5),
        Row(
          children: [
            DeleteCircleButton(
              label: s.txDetailDelete,
              onPressed: () => close(DetailAction.delete),
            ),
            const SizedBox(width: FreevaSpace.s2),
            Expanded(
              child: FreevaButton(
                label: s.txDetailCopy,
                variant: FreevaButtonVariant.secondary,
                expand: true,
                onPressed: () => close(DetailAction.copy),
              ),
            ),
            const SizedBox(width: FreevaSpace.s2),
            Expanded(
              child: FreevaButton(
                label: s.txDetailEdit,
                variant: FreevaButtonVariant.ink,
                expand: true,
                onPressed: () => close(DetailAction.edit),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
