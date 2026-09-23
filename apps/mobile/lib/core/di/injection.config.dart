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
import 'package:mobile/core/feature_flags/feature_flag_service.dart' as _i1017;
import 'package:mobile/core/feature_flags/local_feature_flag_service.dart'
    as _i158;
import 'package:mobile/core/logging/app_logger.dart' as _i766;
import 'package:mobile/core/logging/app_logger_impl.dart' as _i760;
import 'package:mobile/features/auth/data/auth_api.dart' as _i88;
import 'package:mobile/features/auth/data/auth_platform.dart' as _i810;
import 'package:mobile/features/auth/data/auth_repository_impl.dart' as _i274;
import 'package:mobile/features/auth/domain/auth_repository.dart' as _i173;
import 'package:mobile/features/auth/domain/auth_use_cases.dart' as _i253;
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart'
    as _i990;

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
    gh.lazySingleton<_i810.DeviceBiometrics>(
        () => _i810.LocalDeviceBiometrics());
    gh.lazySingleton<_i1017.FeatureFlagService>(
        () => const _i158.LocalFeatureFlagService());
    gh.lazySingleton<_i88.AuthApi>(() => _i88.HttpAuthApi());
    gh.lazySingleton<_i810.AuthVault>(() => _i810.SecureAuthVault());
    gh.lazySingleton<_i766.AppLogger>(() => _i760.AppLoggerImpl());
    gh.lazySingleton<_i1020.AnalyticsService>(
        () => _i862.DebugAnalyticsService(gh<_i766.AppLogger>()));
    gh.lazySingleton<_i173.AuthRepository>(() => _i274.AuthRepositoryImpl(
          gh<_i88.AuthApi>(),
          gh<_i810.AuthVault>(),
          gh<_i810.DeviceBiometrics>(),
        ));
    gh.factory<_i253.AuthUseCases>(
        () => _i253.DefaultAuthUseCases(gh<_i173.AuthRepository>()));
    gh.lazySingleton<_i990.AuthViewModel>(
        () => _i990.DefaultAuthViewModel(gh<_i253.AuthUseCases>()));
    return this;
  }
}
