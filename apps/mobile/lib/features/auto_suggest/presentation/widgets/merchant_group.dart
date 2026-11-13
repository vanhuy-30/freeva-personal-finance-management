import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../domain/merchant_mapping.dart';
import 'merchant_row.dart';

/// CỬA HÀNG ĐÃ NHỚ · n: header and one card of [MerchantRow]s. Shows the
/// first [preview] rows and a centred "Xem cả n" row until [expanded].
class MerchantGroup extends StatelessWidget {
  const MerchantGroup({
    required this.mappings,
    required this.expanded,
    required this.onExpand,
    required this.onForget,
    super.key,
  });

  static const preview = 4;

  /// Rows are 54 on the board with the 1 divider inside, so rows after the
  /// first are 53 here.
  static const _rowHeight = 54.0;

  final List<MerchantMapping> mappings;
  final bool expanded;
  final VoidCallback onExpand;
  final ValueChanged<MerchantMapping> onForget;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final more = !expanded && mappings.length > preview;
    final shown = more ? mappings.take(preview) : mappings;
    final rows = <Widget>[
      for (final (i, mapping) in shown.indexed)
        MerchantRow(
          key: ValueKey(mapping.id),
          mapping: mapping,
          onForget: () => onForget(mapping),
          minHeight: i == 0 ? _rowHeight : _rowHeight - 1,
        ),
      if (more)
        Semantics(
          button: true,
          container: true,
          child: InkWell(
            onTap: onExpand,
            splashFactory: NoSplash.splashFactory,
            highlightColor: c.bgSubtle,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _rowHeight - 1),
              child: Center(
                child: Text(
                  s.autoSuggestSeeAll(mappings.length),
                  style: FreevaTypography.bodyM.copyWith(
                    fontWeight: FontWeight.w600,
                    color: c.textLink,
                  ),
                ),
              ),
            ),
          ),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: FreevaSpace.s1),
          child: Semantics(
            header: true,
            child: Text(
              s.autoSuggestMerchants(mappings.length).toUpperCase(),
              style: FreevaTypography.sectionLabel.copyWith(
                color: c.textSecondary,
              ),
            ),
          ),
        ),
        // Board: 14 column gap pulled up by 8, under a 14.5 (not 16) line.
        const SizedBox(height: 5),
        FreevaCard(
          list: true,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) Divider(height: 1, color: c.listDivider),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
