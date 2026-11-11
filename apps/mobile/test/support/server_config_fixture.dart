import 'package:get_it/get_it.dart';
import 'package:mobile/core/feature_flags/feature_flag_service.dart';
import 'package:mobile/features/server_config/domain/app_limits.dart';
import 'package:mobile/features/server_config/domain/server_config.dart';
import 'package:mobile/features/server_config/domain/server_config_repository.dart';
import 'package:mobile/features/server_config/presentation/viewmodels/server_config_view_model.dart';
import 'package:dartz/dartz.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';

/// Server config as the API returns it with nothing edited (backend registry defaults).
Map<String, Object> testConfigValues([
  Map<String, Object> overrides = const {},
]) => {
  'budget.alertThresholdOptions': [70, 80, 90, 100],
  'budget.defaultAlertThresholds': [80, 100],
  'budget.maxAlertThresholds': 4,
  'limit.budgetThresholdMax': 100,
  'forecast.monthOptions': [3, 6, 12],
  'forecast.defaultMonths': 3,
  'limit.forecastMaxMonths': 12,
  'installment.termOptions': [3, 6, 9, 12],
  'installment.defaultTerm': 6,
  'limit.installmentMinTerm': 2,
  'limit.installmentMaxTerm': 60,
  'recurring.remindBeforeOptions': [0, 1, 3, 7],
  'recurring.defaultRemindBefore': 3,
  'limit.remindBeforeMax': 30,
  'creditCard.highUsagePercent': 70,
  'creditCard.criticalUsagePercent': 90,
  'creditCard.dueSoonDays': 7,
  'debt.dueSoonDays': 14,
  'netWorth.defaultWindow': '6m',
  'investment.chartDefaultWindow': '6m',
  'report.topRows': 3,
  'home.recentTransactions': 3,
  'goal.defaultDateOffsetDays': 30,
  'goal.maxDateOffsetYears': 60,
  'notification.minuteStep': 15,
  'notification.dailyLogDefaultTime': '21:00',
  ...overrides,
};

ServerConfig testServerConfig([Map<String, Object> overrides = const {}]) =>
    ServerConfig(
      version: 1,
      flags: const {},
      values: testConfigValues(overrides),
    );

AppLimits testLimits([Map<String, Object> overrides = const {}]) =>
    AppLimits.from(testServerConfig(overrides))!;

/// A loaded model for widget tests and fakes.
ServerConfigViewModel testServerConfigModel([
  Map<String, Object> overrides = const {},
]) =>
    ServerConfigViewModel.withClock(_NoNetwork())
      ..debugSetConfig(testServerConfig(overrides));

/// Registers the loaded model under every type the app reads it by.
ServerConfigViewModel registerTestServerConfig([
  Map<String, Object> overrides = const {},
  GetIt? getIt,
]) {
  final it = getIt ?? GetIt.instance;
  final model = testServerConfigModel(overrides);
  if (it.isRegistered<ServerConfigViewModel>()) {
    it.unregister<ServerConfigViewModel>();
  }
  if (it.isRegistered<AppLimitsSource>()) it.unregister<AppLimitsSource>();
  if (it.isRegistered<FeatureFlagService>()) {
    it.unregister<FeatureFlagService>();
  }
  it
    ..registerSingleton<ServerConfigViewModel>(model)
    ..registerSingleton<AppLimitsSource>(model)
    ..registerSingleton<FeatureFlagService>(model);
  return model;
}

class _NoNetwork implements ServerConfigRepository {
  @override
  Future<Either<AuthFailure, ServerConfig>> fetch() async =>
      left(const AuthFailure(AuthError.network));
  @override
  Future<ServerConfig?> readCached() async => null;
  @override
  Future<void> writeCached(ServerConfig config) async {}
  @override
  Future<void> clearCached() async {}
}
