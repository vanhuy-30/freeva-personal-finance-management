import 'server_config.dart';

/// MOB-P5-001: typed product numbers from the server (`/app-config`, BE-P5-E08/001).
/// Built once per config version; null when any key is missing so a caller never
/// guesses a number. Keys and meaning: backend `app-config-registry.ts`.
class AppLimits {
  const AppLimits({
    required this.budgetThresholdOptions,
    required this.budgetDefaultThresholds,
    required this.budgetMaxThresholds,
    required this.budgetThresholdMax,
    required this.forecastMonthOptions,
    required this.forecastDefaultMonths,
    required this.forecastMaxMonths,
    required this.installmentTermOptions,
    required this.installmentDefaultTerm,
    required this.installmentMinTerm,
    required this.installmentMaxTerm,
    required this.recurringRemindOptions,
    required this.recurringDefaultRemind,
    required this.remindBeforeMax,
    required this.creditHighUsagePercent,
    required this.creditCriticalUsagePercent,
    required this.creditDueSoonDays,
    required this.debtDueSoonDays,
    required this.netWorthDefaultWindow,
    required this.investmentChartWindow,
    required this.reportTopRows,
    required this.homeRecentTransactions,
    required this.goalDefaultOffsetDays,
    required this.goalMaxOffsetYears,
    required this.notificationMinuteStep,
    required this.dailyLogDefaultTime,
  });

  final List<int> budgetThresholdOptions;
  final List<int> budgetDefaultThresholds;
  final int budgetMaxThresholds;
  final int budgetThresholdMax;
  final List<int> forecastMonthOptions;
  final int forecastDefaultMonths;
  final int forecastMaxMonths;
  final List<int> installmentTermOptions;
  final int installmentDefaultTerm;
  final int installmentMinTerm;
  final int installmentMaxTerm;
  final List<int> recurringRemindOptions;
  final int recurringDefaultRemind;
  final int remindBeforeMax;
  final int creditHighUsagePercent;
  final int creditCriticalUsagePercent;
  final int creditDueSoonDays;
  final int debtDueSoonDays;

  /// Series window code: `7d`, `30d`, `3m`, `6m`, `1y` or `all`.
  final String netWorthDefaultWindow;
  final String investmentChartWindow;
  final int reportTopRows;
  final int homeRecentTransactions;
  final int goalDefaultOffsetDays;
  final int goalMaxOffsetYears;
  final int notificationMinuteStep;

  /// `HH:mm`.
  final String dailyLogDefaultTime;

  static AppLimits? from(ServerConfig config) {
    try {
      int n(String key) => config.integer(key)!;
      List<int> ns(String key) => List.unmodifiable(config.integers(key)!);
      String t(String key) => config.text(key)!;
      return AppLimits(
        budgetThresholdOptions: ns('budget.alertThresholdOptions'),
        budgetDefaultThresholds: ns('budget.defaultAlertThresholds'),
        budgetMaxThresholds: n('budget.maxAlertThresholds'),
        budgetThresholdMax: n('limit.budgetThresholdMax'),
        forecastMonthOptions: ns('forecast.monthOptions'),
        forecastDefaultMonths: n('forecast.defaultMonths'),
        forecastMaxMonths: n('limit.forecastMaxMonths'),
        installmentTermOptions: ns('installment.termOptions'),
        installmentDefaultTerm: n('installment.defaultTerm'),
        installmentMinTerm: n('limit.installmentMinTerm'),
        installmentMaxTerm: n('limit.installmentMaxTerm'),
        recurringRemindOptions: ns('recurring.remindBeforeOptions'),
        recurringDefaultRemind: n('recurring.defaultRemindBefore'),
        remindBeforeMax: n('limit.remindBeforeMax'),
        creditHighUsagePercent: n('creditCard.highUsagePercent'),
        creditCriticalUsagePercent: n('creditCard.criticalUsagePercent'),
        creditDueSoonDays: n('creditCard.dueSoonDays'),
        debtDueSoonDays: n('debt.dueSoonDays'),
        netWorthDefaultWindow: t('netWorth.defaultWindow'),
        investmentChartWindow: t('investment.chartDefaultWindow'),
        reportTopRows: n('report.topRows'),
        homeRecentTransactions: n('home.recentTransactions'),
        goalDefaultOffsetDays: n('goal.defaultDateOffsetDays'),
        goalMaxOffsetYears: n('goal.maxDateOffsetYears'),
        notificationMinuteStep: n('notification.minuteStep'),
        dailyLogDefaultTime: t('notification.dailyLogDefaultTime'),
      );
    } on TypeError {
      // A `!` on a missing or mistyped key.
      return null;
    }
  }
}

/// Domain-side read of [AppLimits]; the app instance is the server config model.
/// Use cases depend on this, not on the presentation model.
abstract class AppLimitsSource {
  /// Never null inside the signed-in app (guarded by `ServerConfigBoundary`).
  AppLimits get requireLimits;
}
