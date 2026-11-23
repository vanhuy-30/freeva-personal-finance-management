import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/currency_catalog.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../insights/domain/insight.dart';
import '../../../insights/presentation/viewmodels/insights_view_model.dart';
import '../../../insights/presentation/widgets/insight_card.dart';
import '../../../insights/presentation/widgets/insight_navigation.dart';
import '../../../insights/presentation/widgets/insight_text.dart';
import '../../domain/report.dart';

/// "Nhận định": the first two findings of Phân tích for the running month,
/// from the same source, with a way to the rest. It adds no figures of its
/// own, so the two screens cannot disagree. Shown only while the viewed
/// period is the fiscal month those findings were worked out for. Brings its
/// own space above it, so nothing is left behind when it is hidden.
class ReportInsightsCard extends StatelessWidget {
  const ReportInsightsCard({required this.period, super.key});

  final ReportPeriod period;

  @override
  Widget build(BuildContext context) {
    // Not registered in some widget tests.
    if (!getIt.isRegistered<InsightsViewModel>()) return const SizedBox();
    final model = getIt<InsightsViewModel>();
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final worked = model.period;
        final items = model.items.take(2).toList();
        if (items.isEmpty ||
            worked == null ||
            period.kind != ReportPeriodKind.month ||
            worked.from != period.from ||
            worked.to != period.to ||
            worked.today.compareTo(period.to) > 0) {
          return const SizedBox();
        }
        return Padding(
          padding: const EdgeInsets.only(top: FreevaSpace.s4),
          child: _Card(
            items: items,
            period: worked,
            digits: CurrencyCatalog.current.digits(model.currencyCode),
          ),
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.items,
    required this.period,
    required this.digits,
  });

  final List<Insight> items;
  final InsightPeriod period;
  final int digits;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    return FreevaCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.reportInsightsTitle,
                  style: FreevaTypography.titleM.copyWith(color: c.textPrimary),
                ),
              ),
              Text(
                s.reportInsightsMonth,
                style: FreevaTypography.label.copyWith(
                  fontWeight: FontWeight.w400,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: FreevaSpace.s1),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: 1, color: c.borderDivider),
            _Row(
              item: items[i],
              title: insightTitle(
                s,
                items[i],
                (v) => formatMoneyText(v, digits, locale),
              ),
              onTap: () => items[i] is SpendTrendInsight
                  ? context.push('/insights')
                  : openInsight(context, items[i], period),
            ),
          ],
          Divider(height: 1, color: c.borderDivider),
          InkWell(
            onTap: () => context.push('/insights'),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: FreevaSize.touch),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      s.reportInsightsAll,
                      textAlign: TextAlign.center,
                      style: FreevaTypography.bodyS.copyWith(
                        fontWeight: FontWeight.w600,
                        color: c.textLink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(LucideIcons.chevronRight, size: 14, color: c.textLink),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.item, required this.title, required this.onTap});

  final Insight item;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (icon, bg, fg) = insightLook(c, item);
    return Semantics(
      button: true,
      label: title,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: FreevaSize.touch + 8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(FreevaRadius.sm),
                  ),
                  child: Icon(icon, size: 16, color: fg),
                ),
                const SizedBox(width: FreevaSpace.s3),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: FreevaTypography.bodyM.copyWith(
                      fontWeight: FontWeight.w500,
                      color: c.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: FreevaSpace.s2),
                Icon(
                  LucideIcons.chevronRight,
                  size: 14,
                  color: c.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
