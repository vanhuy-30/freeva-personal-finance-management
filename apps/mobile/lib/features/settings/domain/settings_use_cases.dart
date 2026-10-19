import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'app_preferences.dart';
import 'feedback_message.dart';
import 'settings_repository.dart';

abstract class SettingsUseCases {
  Future<Either<SettingsFailure, AppPreferences>> load();
  Future<Either<SettingsFailure, AppPreferences>> save(AppPreferences value);
  Either<SettingsFailure, String> feedbackText(
    FeedbackKind kind,
    String message,
  );
}

@LazySingleton(as: SettingsUseCases)
class DefaultSettingsUseCases implements SettingsUseCases {
  DefaultSettingsUseCases(this._repository);
  final SettingsRepository _repository;

  @override
  Future<Either<SettingsFailure, AppPreferences>> load() => _repository.load();

  @override
  Future<Either<SettingsFailure, AppPreferences>> save(AppPreferences value) =>
      _repository.save(value);

  @override
  Either<SettingsFailure, String> feedbackText(
    FeedbackKind kind,
    String message,
  ) => composeFeedback(kind, message);
}
