// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:mobile/core/feature_flags/feature_flag_service.dart' as _i1017;
import 'package:mobile/core/feature_flags/local_feature_flag_service.dart'
    as _i158;
import 'package:mobile/core/logging/app_logger.dart' as _i766;
import 'package:mobile/core/logging/app_logger_impl.dart' as _i760;

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
    gh.lazySingleton<_i1017.FeatureFlagService>(
        () => const _i158.LocalFeatureFlagService());
    gh.lazySingleton<_i766.AppLogger>(() => _i760.AppLoggerImpl());
    return this;
  }
}
