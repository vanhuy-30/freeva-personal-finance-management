import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../domain/insight.dart';
import 'insight_text.dart';
import 'insight_visual.dart';

/// Shared card shell of S.1 and S.2: white, radius 20, padding 14/16, the
/// whole card one button.
class InsightShell extends StatelessWidget {
  const InsightShell({
    required this.label,
    required this.onTap,
    required this.child,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(FreevaComponent.listRadius);
    return Semantics(
      button: true,
      container: true,
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.listBg,
          borderRadius: radius,
          boxShadow: FreevaElevation.s1,
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            splashFactory: NoSplash.splashFactory,
            highlightColor: c.bgSubtle,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FreevaSpace.s4,
                vertical: 14,
              ),
              child: ExcludeSemantics(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sentence style of every insight: 15/21, semibold, at most two lines.
TextStyle insightTitleStyle(FreevaColors c) =>
    FreevaTypography.titleM.copyWith(height: 21 / 15, color: c.textPrimary);

/// One insight on Phân tích (S.2): icon tile, sentence, chevron, picture.
class InsightCard extends StatelessWidget {
  const InsightCard({
    required this.item,
    required this.digits,
    required this.onTap,
    super.key,
  });

  final Insight item;
  final int digits;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final title = insightTitle(
      S.of(context),
      item,
      (v) => formatMoneyText(v, digits, locale),
    );
    final (icon, bg, fg) = _look(c);
    return InsightShell(
      label: title,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: FreevaSize.iconButtonS,
                height: FreevaSize.iconButtonS,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(FreevaRadius.sm),
                ),
                child: Icon(icon, size: FreevaSize.iconSm, color: fg),
              ),
              const SizedBox(width: FreevaSpace.s3),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: insightTitleStyle(c),
                  ),
                ),
              ),
              const SizedBox(width: FreevaSpace.s3),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Icon(
                  LucideIcons.chevronRight,
                  size: FreevaSize.iconChip,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: FreevaSpace.s3),
          InsightVisual(item: item, digits: digits),
        ],
      ),
    );
  }

  (IconData, Color, Color) _look(FreevaColors c) => switch (item) {
    BudgetRiskInsight() => (
      LucideIcons.triangleAlert,
      c.statusDangerBg,
      c.statusDanger,
    ),
    OutlierInsight() => (LucideIcons.zap, c.tintViolet, c.tintVioletFg),
    CategoryChangeInsight(up: true) => (
      LucideIcons.trendingUp,
      c.statusWarningBg,
      c.statusWarning,
    ),
    CategoryChangeInsight() => (
      LucideIcons.trendingDown,
      c.statusSuccessBg,
      c.statusSuccess,
    ),
    SpendTrendInsight() => (LucideIcons.chartLine, c.tintBlue, c.tintBlueFg),
  };
}
