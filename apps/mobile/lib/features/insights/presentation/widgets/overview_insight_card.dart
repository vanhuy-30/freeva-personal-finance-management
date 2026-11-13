import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../domain/insight.dart';
import 'insight_card.dart';
import 'insight_text.dart';
import 'insight_visual.dart';

/// Tổng quan · đáng chú ý (S.1): "Đáng chú ý" and "Xem cả n ›", the first
/// insight's sentence and picture. The whole card opens Phân tích.
class OverviewInsightCard extends StatelessWidget {
  const OverviewInsightCard({
    required this.item,
    required this.count,
    required this.digits,
    required this.onTap,
    super.key,
  });

  /// Board eyebrow row uses the browser's normal line height.
  static const _line = 1.2;

  final Insight item;

  /// Items on Phân tích.
  final int count;
  final int digits;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final title = insightTitle(
      s,
      item,
      (v) => formatMoneyText(v, digits, locale),
    );
    return InsightShell(
      label: '${s.insightsEyebrow}. $title. ${s.insightsSeeAll(count)}',
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(LucideIcons.lightbulb, size: 14, color: c.statusWarning),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  s.insightsEyebrow,
                  style: FreevaTypography.label.copyWith(
                    fontWeight: FontWeight.w600,
                    height: _line,
                    color: c.statusWarning,
                  ),
                ),
              ),
              const SizedBox(width: FreevaSpace.s2),
              Text(
                s.insightsSeeAll(count),
                style: FreevaTypography.bodyS.copyWith(
                  fontWeight: FontWeight.w600,
                  height: _line,
                  color: c.textLink,
                ),
              ),
              const SizedBox(width: 2),
              Icon(LucideIcons.chevronRight, size: 14, color: c.textLink),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: insightTitleStyle(c),
          ),
          const SizedBox(height: 10),
          InsightVisual(item: item, digits: digits),
        ],
      ),
    );
  }
}
