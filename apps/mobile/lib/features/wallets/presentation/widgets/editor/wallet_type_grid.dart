import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../../../core/widgets/press_scale.dart';
import '../../../domain/wallet.dart';
import '../wallet_labels.dart';
import '../wallet_type_icon.dart';
import 'form_pair.dart';

/// "Loại ví": 2×2 one-line cards, icon and label on a row, check in the
/// corner. Order follows the artboard: cash, bank, e-wallet, credit card.
class WalletTypeGrid extends StatelessWidget {
  const WalletTypeGrid({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final WalletType selected;
  final ValueChanged<WalletType> onChanged;

  static const order = [
    WalletType.cash,
    WalletType.bank,
    WalletType.ewallet,
    WalletType.credit,
  ];

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    Widget card(WalletType type) => Expanded(
      child: _TypeCard(
        type: type,
        label: walletTypeLabel(s, type),
        selected: type == selected,
        onTap: () => onChanged(type),
      ),
    );
    return Semantics(
      label: s.walletType,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Narrow or large text: one card per row so labels stay on a line.
          if (!fitsSideBySide(context, constraints.maxWidth)) {
            return Column(
              children: [
                for (final (i, type) in order.indexed) ...[
                  if (i > 0) const SizedBox(height: FreevaSpace.s2),
                  Row(children: [card(type)]),
                ],
              ],
            );
          }
          return Column(
            children: [
              Row(
                children: [
                  card(order[0]),
                  const SizedBox(width: 8),
                  card(order[1]),
                ],
              ),
              const SizedBox(height: FreevaSpace.s2),
              Row(
                children: [
                  card(order[2]),
                  const SizedBox(width: 8),
                  card(order[3]),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.type,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final WalletType type;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(FreevaRadius.lg);
    return Semantics(
      container: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: PressScale(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: FreevaMotion.fast,
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: selected ? c.tintBlue : c.bgSurface,
              borderRadius: radius,
              border: Border.all(
                color: selected ? c.actionPrimary : c.borderDefault,
                width: selected
                    ? FreevaBorder.selected
                    : FreevaBorder.defaultValue,
              ),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: FreevaSpace.s3),
                  child: Row(
                    children: [
                      selected
                          ? _SelectedIcon(type: type)
                          : WalletTypeIcon(type: type, size: 32),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          label,
                          style: FreevaTypography.body.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Positioned(
                    top: 8,
                    right: -6,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.actionPrimary,
                      ),
                      child: Icon(
                        LucideIcons.check,
                        size: 12,
                        color: c.textOnAction,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// On the selected (blue) card the icon tile turns white.
class _SelectedIcon extends StatelessWidget {
  const _SelectedIcon({required this.type});

  final WalletType type;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: c.bgSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        walletTypeIconData(type),
        size: 16,
        color: type == WalletType.credit ? c.textPrimary : c.actionPrimary,
      ),
    );
  }
}
