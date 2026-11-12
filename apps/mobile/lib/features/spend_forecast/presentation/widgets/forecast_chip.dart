import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import 'spend_forecast_labels.dart';

/// Tint and ink of a [ForecastTone].
(Color, Color) toneColors(FreevaColors c, ForecastTone tone) => switch (tone) {
  ForecastTone.success => (c.statusSuccessBg, c.statusSuccess),
  ForecastTone.warning => (c.statusWarningBg, c.statusWarning),
  ForecastTone.danger => (c.statusDangerBg, c.statusDanger),
  ForecastTone.neutral => (c.bgSubtle, c.textPrimary),
};

/// Tinted status pill of the forecast cards ("Rủi ro cao", "Trễ 6 tháng"):
/// 24 high, padding 10, 12/600.
class ForecastChip extends StatelessWidget {
  const ForecastChip({required this.label, required this.tone, super.key});

  final String label;
  final ForecastTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, color) = toneColors(context.colors, tone);
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        color: background,
      ),
      child: Text(
        label,
        maxLines: 1,
        style: FreevaTypography.label.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
