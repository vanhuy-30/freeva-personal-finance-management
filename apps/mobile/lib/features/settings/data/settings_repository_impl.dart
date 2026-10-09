import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../domain/app_preferences.dart';
import '../domain/settings_repository.dart';
import 'preference_vault.dart';

@LazySingleton(as: SettingsRepository)
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._vault);
  final PreferenceVault _vault;

  @override
  Future<Either<SettingsFailure, AppPreferences>> load() async {
    try {
      final raw = await _vault.read();
      if (raw == null) return right(const AppPreferences());
      return right(decodePreferences(raw));
    } catch (_) {
      return left(const SettingsFailure(SettingsError.storage));
    }
  }

  @override
  Future<Either<SettingsFailure, AppPreferences>> save(
    AppPreferences value,
  ) async {
    try {
      await _vault.write(encodePreferences(value));
      return right(value);
    } catch (_) {
      return left(const SettingsFailure(SettingsError.storage));
    }
  }
}
