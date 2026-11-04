import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.g.dart';

/// Small status pill after a row title ("Quá hạn", "Còn 2 ngày",
/// "Tạm dừng"): 24 high, 12/500, padding 8.
class RecTag extends StatelessWidget {
  const RecTag(
    this.label, {
    required this.background,
    required this.color,
    super.key,
  });

  final String label;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    height: 24,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: ShapeDecoration(
      shape: const StadiumBorder(),
      color: background,
    ),
    child: Center(
      widthFactor: 1,
      child: Text(
        label,
        maxLines: 1,
        style: FreevaTypography.label.copyWith(color: color),
      ),
    ),
  );
}
