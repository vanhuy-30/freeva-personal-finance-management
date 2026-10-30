// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:mobile/core/analytics/analytics_service.dart' as _i1020;
import 'package:mobile/core/analytics/debug_analytics_service.dart' as _i862;
import 'package:mobile/core/config/app_config.dart' as _i467;
import 'package:mobile/core/feature_flags/feature_flag_service.dart' as _i1017;
import 'package:mobile/core/feature_flags/local_feature_flag_service.dart'
    as _i158;
import 'package:mobile/core/logging/app_logger.dart' as _i766;
import 'package:mobile/core/logging/app_logger_impl.dart' as _i760;
import 'package:mobile/features/auth/data/auth_api.dart' as _i88;
import 'package:mobile/features/auth/data/auth_data_module.dart' as _i901;
import 'package:mobile/features/auth/data/auth_platform.dart' as _i810;
import 'package:mobile/features/auth/data/auth_repository_impl.dart' as _i274;
import 'package:mobile/features/auth/data/authorized_api.dart' as _i443;
import 'package:mobile/features/auth/data/local_session_alert_notifier.dart'
    as _i165;
import 'package:mobile/features/auth/domain/auth_repository.dart' as _i173;
import 'package:mobile/features/auth/domain/auth_use_cases.dart' as _i253;
import 'package:mobile/features/auth/domain/session_alert_notifier.dart'
    as _i54;
import 'package:mobile/features/auth/presentation/auth_presentation_module.dart'
    as _i282;
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart'
    as _i990;
import 'package:mobile/features/bills/data/bill_repository_impl.dart' as _i1026;
import 'package:mobile/features/bills/domain/bill_repository.dart' as _i194;
import 'package:mobile/features/bills/domain/bill_use_cases.dart' as _i659;
import 'package:mobile/features/bills/presentation/viewmodels/bill_view_model.dart'
    as _i151;
import 'package:mobile/features/budgets/data/budget_repository_impl.dart'
    as _i1036;
import 'package:mobile/features/budgets/domain/budget_repository.dart'
    as _i1073;
import 'package:mobile/features/budgets/domain/budget_use_cases.dart' as _i245;
import 'package:mobile/features/budgets/presentation/viewmodels/budget_view_model.dart'
    as _i137;
import 'package:mobile/features/calendar/data/calendar_repository_impl.dart'
    as _i918;
import 'package:mobile/features/calendar/domain/calendar_repository.dart'
    as _i791;
import 'package:mobile/features/calendar/domain/calendar_use_cases.dart'
    as _i471;
import 'package:mobile/features/calendar/presentation/viewmodels/calendar_view_model.dart'
    as _i622;
import 'package:mobile/features/categories/data/category_expansion_repository_impl.dart'
    as _i226;
import 'package:mobile/features/categories/data/category_repository_impl.dart'
    as _i613;
import 'package:mobile/features/categories/domain/category_expansion_repository.dart'
    as _i444;
import 'package:mobile/features/categories/domain/category_repository.dart'
    as _i561;
import 'package:mobile/features/categories/domain/category_use_cases.dart'
    as _i221;
import 'package:mobile/features/categories/presentation/viewmodels/category_view_model.dart'
    as _i961;
import 'package:mobile/features/feedback/data/feedback_repository_impl.dart'
    as _i216;
import 'package:mobile/features/feedback/domain/feedback.dart' as _i173;
import 'package:mobile/features/home/domain/overview_use_cases.dart' as _i970;
import 'package:mobile/features/home/presentation/viewmodels/home_view_model.dart'
    as _i722;
import 'package:mobile/features/notifications/data/notification_repository_impl.dart'
    as _i419;
import 'package:mobile/features/notifications/domain/notification_repository.dart'
    as _i199;
import 'package:mobile/features/notifications/domain/notification_use_cases.dart'
    as _i338;
import 'package:mobile/features/notifications/presentation/viewmodels/notification_view_model.dart'
    as _i921;
import 'package:mobile/features/profile/data/profile_repository_impl.dart'
    as _i72;
import 'package:mobile/features/profile/data/share_account_file_sharer.dart'
    as _i429;
import 'package:mobile/features/profile/domain/account_export_use_case.dart'
    as _i410;
import 'package:mobile/features/profile/domain/account_file_sharer.dart'
    as _i1007;
import 'package:mobile/features/profile/domain/profile_repository.dart' as _i4;
import 'package:mobile/features/profile/domain/profile_use_cases.dart' as _i281;
import 'package:mobile/features/profile/presentation/viewmodels/profile_view_model.dart'
    as _i887;
import 'package:mobile/features/recurring/data/recurring_repository_impl.dart'
    as _i279;
import 'package:mobile/features/recurring/domain/recurring_repository.dart'
    as _i821;
import 'package:mobile/features/recurring/domain/recurring_use_cases.dart'
    as _i629;
import 'package:mobile/features/recurring/presentation/viewmodels/recurring_view_model.dart'
    as _i72;
import 'package:mobile/features/reports/data/report_repository_impl.dart'
    as _i931;
import 'package:mobile/features/reports/domain/report_repository.dart' as _i61;
import 'package:mobile/features/reports/domain/report_use_cases.dart' as _i146;
import 'package:mobile/features/reports/presentation/viewmodels/report_view_model.dart'
    as _i1044;
import 'package:mobile/features/settings/data/preference_vault.dart' as _i1060;
import 'package:mobile/features/settings/data/settings_repository_impl.dart'
    as _i1018;
import 'package:mobile/features/settings/domain/settings_repository.dart'
    as _i1056;
import 'package:mobile/features/settings/domain/settings_use_cases.dart'
    as _i519;
import 'package:mobile/features/settings/presentation/viewmodels/settings_view_model.dart'
    as _i421;
import 'package:mobile/features/sync/data/sync_queue_vault.dart' as _i938;
import 'package:mobile/features/sync/data/sync_repository_impl.dart' as _i430;
import 'package:mobile/features/sync/domain/sync_repository.dart' as _i882;
import 'package:mobile/features/sync/domain/sync_use_cases.dart' as _i665;
import 'package:mobile/features/sync/presentation/viewmodels/sync_view_model.dart'
    as _i488;
import 'package:mobile/features/tags/data/tag_repository_impl.dart' as _i729;
import 'package:mobile/features/tags/domain/tag_repository.dart' as _i57;
import 'package:mobile/features/tags/domain/tag_use_cases.dart' as _i112;
import 'package:mobile/features/transactions/data/transaction_repository_impl.dart'
    as _i1020;
import 'package:mobile/features/transactions/domain/transaction_repository.dart'
    as _i931;
import 'package:mobile/features/transactions/domain/transaction_use_cases.dart'
    as _i292;
import 'package:mobile/features/transactions/presentation/viewmodels/transaction_results_view_model.dart'
    as _i1024;
import 'package:mobile/features/transactions/presentation/viewmodels/transaction_view_model.dart'
    as _i332;
import 'package:mobile/features/wallets/data/wallet_repository_impl.dart'
    as _i128;
import 'package:mobile/features/wallets/domain/wallet_repository.dart' as _i107;
import 'package:mobile/features/wallets/domain/wallet_use_cases.dart' as _i336;
import 'package:mobile/features/wallets/presentation/viewmodels/wallet_detail_view_model.dart'
    as _i599;
import 'package:mobile/features/wallets/presentation/viewmodels/wallet_view_model.dart'
    as _i251;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final authDataModule = _$AuthDataModule();
    final authPresentationModule = _$AuthPresentationModule();
    gh.lazySingleton<_i467.AppConfig>(() => _i467.AppConfig());
    gh.lazySingleton<_i1060.PreferenceVault>(
        () => _i1060.SecurePreferenceVault());
    gh.lazySingleton<_i938.SyncQueueVault>(() => _i938.SecureSyncQueueVault());
    gh.lazySingleton<_i810.AuthVault>(
        () => _i810.SecureAuthVault(gh<_i467.AppConfig>()));
    gh.lazySingleton<_i54.SessionAlertNotifier>(
        () => _i165.LocalSessionAlertNotifier());
    gh.lazySingleton<_i810.DeviceBiometrics>(
        () => _i810.LocalDeviceBiometrics());
    gh.lazySingleton<_i1017.FeatureFlagService>(
        () => const _i158.LocalFeatureFlagService());
    gh.lazySingleton<_i444.CategoryExpansionRepository>(
        () => _i226.CategoryExpansionRepositoryImpl());
    gh.lazySingleton<_i766.AppLogger>(() => _i760.AppLoggerImpl());
    gh.lazySingleton<_i1007.AccountFileSharer>(
        () => _i429.ShareAccountFileSharer());
    gh.lazySingleton<_i88.AuthApi>(() => _i88.HttpAuthApi(
          gh<_i467.AppConfig>(),
          gh<_i766.AppLogger>(),
        ));
    gh.lazySingleton<_i1056.SettingsRepository>(
        () => _i1018.SettingsRepositoryImpl(gh<_i1060.PreferenceVault>()));
    gh.lazySingleton<_i1020.AnalyticsService>(
        () => _i862.DebugAnalyticsService(gh<_i766.AppLogger>()));
    gh.lazySingleton<_i173.AuthRepository>(() => _i274.AuthRepositoryImpl(
          gh<_i88.AuthApi>(),
          gh<_i810.AuthVault>(),
          gh<_i810.DeviceBiometrics>(),
        ));
    gh.lazySingleton<_i443.AuthorizedApi>(
        () => authDataModule.authorizedApi(gh<_i173.AuthRepository>()));
    gh.lazySingleton<_i519.SettingsUseCases>(
        () => _i519.DefaultSettingsUseCases(gh<_i1056.SettingsRepository>()));
    gh.lazySingleton<_i561.CategoryRepository>(
        () => _i613.CategoryRepositoryImpl(gh<_i443.AuthorizedApi>()));
    gh.lazySingleton<_i882.SyncRepository>(() => _i430.SyncRepositoryImpl(
          gh<_i443.AuthorizedApi>(),
          gh<_i938.SyncQueueVault>(),
          gh<_i766.AppLogger>(),
        ));
    gh.lazySingleton<_i199.NotificationRepository>(
        () => _i419.NotificationRepositoryImpl(gh<_i443.AuthorizedApi>()));
    gh.lazySingleton<_i791.CalendarRepository>(
        () => _i918.CalendarRepositoryImpl(gh<_i443.AuthorizedApi>()));
    gh.lazySingleton<_i931.TransactionRepository>(
        () => _i1020.TransactionRepositoryImpl(gh<_i443.AuthorizedApi>()));
    gh.lazySingleton<_i821.RecurringRepository>(
        () => _i279.RecurringRepositoryImpl(gh<_i443.AuthorizedApi>()));
    gh.lazySingleton<_i194.BillRepository>(
        () => _i1026.BillRepositoryImpl(gh<_i443.AuthorizedApi>()));
    gh.lazySingleton<_i292.TransactionUseCases>(() =>
        _i292.DefaultTransactionUseCases(gh<_i931.TransactionRepository>()));
    gh.lazySingleton<_i629.RecurringUseCases>(
        () => _i629.DefaultRecurringUseCases(gh<_i821.RecurringRepository>()));
    gh.lazySingleton<_i1073.BudgetRepository>(
        () => _i1036.BudgetRepositoryImpl(gh<_i443.AuthorizedApi>()));
    gh.lazySingleton<_i659.BillUseCases>(
        () => _i659.DefaultBillUseCases(gh<_i194.BillRepository>()));
    gh.factory<_i410.AccountExportUseCase>(() => _i410.AccountExportUseCase(
          gh<_i173.AuthRepository>(),
          gh<_i1007.AccountFileSharer>(),
        ));
    gh.lazySingleton<_i107.WalletRepository>(
        () => _i128.WalletRepositoryImpl(gh<_i443.AuthorizedApi>()));
    gh.lazySingleton<_i4.ProfileRepository>(
        () => _i72.ProfileRepositoryImpl(gh<_i443.AuthorizedApi>()));
    gh.lazySingleton<_i61.ReportRepository>(
        () => _i931.ReportRepositoryImpl(gh<_i443.AuthorizedApi>()));
    gh.lazySingleton<_i173.FeedbackRepository>(
        () => _i216.FeedbackRepositoryImpl(gh<_i443.AuthorizedApi>()));
    gh.lazySingleton<_i57.TagRepository>(
        () => _i729.TagRepositoryImpl(gh<_i443.AuthorizedApi>()));
    gh.lazySingleton<_i338.NotificationUseCases>(() =>
        _i338.DefaultNotificationUseCases(gh<_i199.NotificationRepository>()));
    gh.factory<_i253.AuthUseCases>(
        () => _i253.DefaultAuthUseCases(gh<_i173.AuthRepository>()));
    gh.lazySingleton<_i665.SyncUseCases>(
        () => _i665.DefaultSyncUseCases(gh<_i882.SyncRepository>()));
    gh.lazySingleton<_i221.CategoryUseCases>(
        () => _i221.DefaultCategoryUseCases(gh<_i561.CategoryRepository>()));
    gh.lazySingleton<_i112.TagUseCases>(
        () => _i112.DefaultTagUseCases(gh<_i57.TagRepository>()));
    gh.lazySingleton<_i173.FeedbackUseCases>(
        () => _i173.DefaultFeedbackUseCases(gh<_i173.FeedbackRepository>()));
    gh.lazySingleton<_i421.SettingsViewModel>(
        () => _i421.DefaultSettingsViewModel(
              gh<_i519.SettingsUseCases>(),
              gh<_i253.AuthUseCases>(),
              gh<_i1020.AnalyticsService>(),
            ));
    gh.lazySingleton<_i471.CalendarUseCases>(
        () => _i471.DefaultCalendarUseCases(gh<_i791.CalendarRepository>()));
    gh.lazySingleton<_i245.BudgetUseCases>(
        () => _i245.DefaultBudgetUseCases(gh<_i1073.BudgetRepository>()));
    gh.lazySingleton<_i990.AuthViewModel>(
        () => authPresentationModule.authViewModel(
              gh<_i253.AuthUseCases>(),
              gh<_i519.SettingsUseCases>(),
              gh<_i54.SessionAlertNotifier>(),
              gh<_i1020.AnalyticsService>(),
              gh<_i338.NotificationUseCases>(),
            ));
    gh.lazySingleton<_i336.WalletUseCases>(
        () => _i336.DefaultWalletUseCases(gh<_i107.WalletRepository>()));
    gh.factory<_i281.ProfileUseCases>(
        () => _i281.ProfileUseCases(gh<_i4.ProfileRepository>()));
    gh.lazySingleton<_i622.CalendarViewModel>(() => _i622.CalendarViewModel(
          gh<_i471.CalendarUseCases>(),
          gh<_i990.AuthViewModel>(),
        ));
    gh.lazySingleton<_i146.ReportUseCases>(() => _i146.DefaultReportUseCases(
          gh<_i61.ReportRepository>(),
          gh<_i107.WalletRepository>(),
          gh<_i561.CategoryRepository>(),
        ));
    gh.lazySingleton<_i961.CategoryViewModel>(
        () => _i961.DefaultCategoryViewModel(
              gh<_i221.CategoryUseCases>(),
              gh<_i990.AuthViewModel>(),
              gh<_i444.CategoryExpansionRepository>(),
            ));
    gh.lazySingleton<_i970.OverviewUseCases>(
        () => _i970.DefaultOverviewUseCases(
              gh<_i61.ReportRepository>(),
              gh<_i107.WalletRepository>(),
              gh<_i931.TransactionRepository>(),
              gh<_i561.CategoryRepository>(),
              gh<_i245.BudgetUseCases>(),
            ));
    gh.lazySingleton<_i72.RecurringViewModel>(() => _i72.RecurringViewModel(
          gh<_i629.RecurringUseCases>(),
          gh<_i990.AuthViewModel>(),
        ));
    gh.lazySingleton<_i151.BillViewModel>(() => _i151.BillViewModel(
          gh<_i659.BillUseCases>(),
          gh<_i292.TransactionUseCases>(),
          gh<_i990.AuthViewModel>(),
        ));
    gh.lazySingleton<_i488.SyncViewModel>(() => _i488.DefaultSyncViewModel(
          gh<_i665.SyncUseCases>(),
          gh<_i990.AuthViewModel>(),
          gh<_i1020.AnalyticsService>(),
        ));
    gh.lazySingleton<_i251.WalletViewModel>(() => _i251.DefaultWalletViewModel(
          gh<_i336.WalletUseCases>(),
          gh<_i990.AuthViewModel>(),
          gh<_i887.ProfileViewModel>(),
        ));
    gh.lazySingleton<_i887.ProfileViewModel>(
        () => _i887.DefaultProfileViewModel(
              gh<_i281.ProfileUseCases>(),
              gh<_i990.AuthViewModel>(),
              gh<_i410.AccountExportUseCase>(),
            ));
    gh.lazySingleton<_i1044.ReportViewModel>(
        () => _i1044.DefaultReportViewModel(
              gh<_i146.ReportUseCases>(),
              gh<_i990.AuthViewModel>(),
              gh<_i1020.AnalyticsService>(),
              gh<_i887.ProfileViewModel>(),
            ));
    gh.lazySingleton<_i137.BudgetViewModel>(() => _i137.DefaultBudgetViewModel(
          gh<_i245.BudgetUseCases>(),
          gh<_i561.CategoryRepository>(),
          gh<_i887.ProfileViewModel>(),
          gh<_i1056.SettingsRepository>(),
          gh<_i990.AuthViewModel>(),
        ));
    gh.lazySingleton<_i722.HomeViewModel>(() => _i722.DefaultHomeViewModel(
          gh<_i970.OverviewUseCases>(),
          gh<_i990.AuthViewModel>(),
          gh<_i887.ProfileViewModel>(),
          gh<_i421.SettingsViewModel>(),
          gh<_i488.SyncViewModel>(),
        ));
    gh.lazySingleton<_i921.NotificationViewModel>(
        () => _i921.DefaultNotificationViewModel(
              gh<_i338.NotificationUseCases>(),
              gh<_i990.AuthViewModel>(),
              gh<_i887.ProfileViewModel>(),
            ));
    gh.lazySingleton<_i332.TransactionViewModel>(
        () => _i332.DefaultTransactionViewModel(
              gh<_i292.TransactionUseCases>(),
              gh<_i221.CategoryUseCases>(),
              gh<_i112.TagUseCases>(),
              gh<_i336.WalletUseCases>(),
              gh<_i251.WalletViewModel>(),
              gh<_i281.ProfileUseCases>(),
              gh<_i990.AuthViewModel>(),
              gh<_i1020.AnalyticsService>(),
              gh<_i488.SyncViewModel>(),
            ));
    gh.factoryParam<_i599.WalletDetailViewModel, String, dynamic>((
      walletId,
      _,
    ) =>
        _i599.DefaultWalletDetailViewModel(
          gh<_i292.TransactionUseCases>(),
          gh<_i332.TransactionViewModel>(),
          walletId: walletId,
        ));
    gh.factoryParam<_i1024.TransactionResultsViewModel, bool?, String?>((
      deleted,
      accountId,
    ) =>
        _i1024.DefaultTransactionResultsViewModel(
          gh<_i292.TransactionUseCases>(),
          gh<_i332.TransactionViewModel>(),
          deleted: deleted,
          accountId: accountId,
        ));
    return this;
  }
}

class _$AuthDataModule extends _i901.AuthDataModule {}

class _$AuthPresentationModule extends _i282.AuthPresentationModule {}
