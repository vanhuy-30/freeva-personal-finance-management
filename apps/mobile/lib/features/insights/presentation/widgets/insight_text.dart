import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/insight.dart';

/// The insight's sentence from the l10n template of its kind. [money] formats
/// an amount without the currency symbol. No percent is said when the server
/// has too little history for one.
String insightTitle(S s, Insight item, String Function(BigInt) money) =>
    switch (item) {
      BudgetRiskInsight(:final category?, :final percent) =>
        s.insightBudgetCategory(category.name, percent),
      BudgetRiskInsight(:final percent) => s.insightBudgetMonth(percent),
      OutlierInsight(:final merchant, :final category) => s.insightOutlier(
        money(item.amountMinor),
        merchant == null || merchant.trim().isEmpty ? category.name : merchant,
        item.times,
      ),
      CategoryChangeInsight(:final category, :final up, :final changePercent) =>
        switch (changePercent) {
          null when up => s.insightCategoryMore(category.name),
          null => s.insightCategoryLess(category.name),
          final p when up => s.insightCategoryUp(category.name, p),
          final p => s.insightCategoryDown(category.name, p),
        },
      SpendTrendInsight(:final days, :final up, :final changePercent) =>
        switch (changePercent) {
          null when up => s.insightTrendMore,
          null => s.insightTrendLess,
          final p when up => s.insightTrendUp(days, p),
          final p => s.insightTrendDown(days, p),
        },
    };
