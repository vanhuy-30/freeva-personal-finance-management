import 'package:mobile/core/di/injection.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/profile/domain/profile_use_cases.dart';
import 'package:mobile/features/settings/data/settings_repository_impl.dart';
import 'package:mobile/features/settings/domain/settings_use_cases.dart';
import 'package:mobile/features/settings/presentation/viewmodels/settings_view_model.dart';

import '../profile/fakes.dart';
import '../settings/fakes.dart';
import 'fakes.dart';

/// What the first-run setup screens take from getIt, with in-memory stores.
class SetupDeps {
  final profiles = MemoryProfiles();
  final preferences = MemoryPreferences();
  final analytics = RecordingAnalytics();
  late final DefaultSettingsViewModel settings;
}

/// Registers [SetupDeps] on a clean getIt. The caller keeps `AuthViewModel`.
Future<SetupDeps> registerSetupDeps() async {
  final deps = SetupDeps();
  final cases = DefaultSettingsUseCases(
    SettingsRepositoryImpl(deps.preferences),
  );
  deps.settings = DefaultSettingsViewModel(
    cases,
    DefaultAuthUseCases(
      AuthRepositoryImpl(FakeApi(), MemoryVault(), FakeBiometrics()),
    ),
    deps.analytics,
  );
  await deps.settings.load();
  getIt
    ..registerSingleton<ProfileUseCases>(ProfileUseCases(deps.profiles))
    ..registerSingleton<SettingsUseCases>(cases)
    ..registerSingleton<SettingsViewModel>(deps.settings);
  return deps;
}
