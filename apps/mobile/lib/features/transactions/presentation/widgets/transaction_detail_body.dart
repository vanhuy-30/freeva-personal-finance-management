import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button_style.dart';
import '../../../../core/widgets/press_scale.dart';
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
        // Board: centred icon 52, name 15/500, amount moneyL; 4 above.
        Padding(
          padding: const EdgeInsets.only(top: FreevaSpace.s1),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.bgSubtle,
                ),
                child: Icon(
                  label.icon,
                  size: FreevaSize.icon,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                label.title,
                textAlign: TextAlign.center,
                style: FreevaTypography.body.copyWith(
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              MoneyDisplay(
                minor: label.minor,
                currency: label.currency,
                minorDigits: digits,
                tone: label.tone,
                style: FreevaTypography.moneyL,
              ),
            ],
          ),
        ),
        const SizedBox(height: FreevaSpace.s5),
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
              child: _ActionButton(
                label: s.txDetailCopy,
                icon: LucideIcons.copy,
                variant: FreevaButtonVariant.secondary,
                onPressed: () => close(DetailAction.copy),
              ),
            ),
            const SizedBox(width: FreevaSpace.s2),
            Expanded(
              child: _ActionButton(
                label: s.txDetailEdit,
                icon: LucideIcons.penLine,
                variant: FreevaButtonVariant.ink,
                onPressed: () => close(DetailAction.edit),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 52 action of the detail sheet: 18 icon, 8 gap, 15/600, no side padding
/// (board `.act`), so "Sao chép" fits beside the delete circle.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.variant,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final FreevaButtonVariant variant;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => PressScale(
    child: TextButton(
      onPressed: onPressed,
      style: freevaButtonStyle(context.colors, variant, FreevaButtonSize.m)
          .copyWith(
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: FreevaSpace.s2),
            ),
          ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: FreevaSize.iconSm),
          const SizedBox(width: FreevaSpace.s2),
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    ),
  );
}
