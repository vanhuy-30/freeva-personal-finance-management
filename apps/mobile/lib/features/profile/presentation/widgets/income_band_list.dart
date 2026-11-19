import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../domain/declared_income.dart';
import 'income_band_label.dart';

/// Income bands as one radio list (board ObIncome), ending with "Không muốn
/// chia sẻ". Used on question 2 and in the Cá nhân income sheet.
class IncomeBandList extends StatelessWidget {
  const IncomeBandList({
    required this.bands,
    required this.digits,
    required this.selected,
    required this.notShared,
    required this.onBand,
    required this.onNotShared,
    super.key,
  });

  final List<DeclaredIncome> bands;
  final int digits;
  final DeclaredIncome? selected;
  final bool notShared;
  final ValueChanged<DeclaredIncome> onBand;
  final VoidCallback onNotShared;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final rows = <Widget>[
      for (final band in bands)
        _BandRow(
          label: incomeBandLabel(s, band, digits, locale),
          selected: band.sameBand(selected),
          onTap: () => onBand(band),
        ),
      _BandRow(
        label: s.incomeBandNone,
        selected: notShared,
        muted: true,
        onTap: onNotShared,
      ),
    ];
    return FreevaCard(
      list: true,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(FreevaComponent.listRadius),
        child: Semantics(
          container: true,
          explicitChildNodes: true,
          child: Column(
            children: [
              for (final (i, row) in rows.indexed) ...[
                if (i > 0)
                  Divider(height: 1, thickness: 1, color: c.listDivider),
                row,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 52 high, 8/16 padding, 15/500 label (600 when picked on a blue wash),
/// 22 radio at the end.
class _BandRow extends StatelessWidget {
  const _BandRow({
    required this.label,
    required this.selected,
    required this.onTap,
    this.muted = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// "Không muốn chia sẻ" reads in the secondary colour.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: Material(
        color: selected ? c.tintBlue : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FreevaSpace.s4,
                vertical: FreevaSpace.s2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: FreevaTypography.body.copyWith(
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: muted && !selected
                            ? c.textSecondary
                            : c.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: FreevaSpace.s3),
                  ExcludeSemantics(
                    child: AnimatedContainer(
                      duration: FreevaMotion.fast,
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? c.actionPrimary : c.borderStrong,
                          width: selected ? 6 : FreevaBorder.selected,
                        ),
                      ),
                    ),
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
