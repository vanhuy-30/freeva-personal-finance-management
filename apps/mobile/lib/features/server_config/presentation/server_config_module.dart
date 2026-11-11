import 'package:injectable/injectable.dart';

import '../../../core/feature_flags/feature_flag_service.dart';
import 'viewmodels/server_config_view_model.dart';

@module
abstract class ServerConfigModule {
  /// Flags read anywhere in the app come from the server copy (MOB-P5-E08).
  @lazySingleton
  FeatureFlagService featureFlags(ServerConfigViewModel model) => model;
}
