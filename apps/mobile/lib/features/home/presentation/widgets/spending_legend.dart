import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';

/// Two-column legend: dot · name · percent.
class SpendingLegend extends StatelessWidget {
  const SpendingLegend({required this.items, super.key});

  final List<(String, int, Color)> items;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget cell((String, int, Color) item) => Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: item.$3),
        ),
        const SizedBox(width: FreevaSpace.s2),
        Expanded(
          child: Text(
            item.$1,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: FreevaTypography.bodyS.copyWith(
              height: 1.2,
              color: c.textSecondary,
            ),
          ),
        ),
        Text(
          '${item.$2}%',
          style: FreevaTypography.bodyS.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.2,
            color: c.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : FreevaSpace.s2),
          child: Row(
            children: [
              Expanded(child: cell(items[i])),
              const SizedBox(width: FreevaSpace.s3),
              Expanded(
                child: i + 1 < items.length
                    ? cell(items[i + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}
