import 'package:injectable/injectable.dart';

import 'feature_flag_service.dart';

@LazySingleton(as: FeatureFlagService)
class LocalFeatureFlagService implements FeatureFlagService {
  const LocalFeatureFlagService();

  @override
  bool isEnabled(String key) => false;
}
