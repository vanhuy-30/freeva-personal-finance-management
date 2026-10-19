import 'package:dartz/dartz.dart';

import 'app_preferences.dart';

const int feedbackMaxLength = 2000;

Either<SettingsFailure, String> composeFeedback(
  FeedbackKind kind,
  String message,
) {
  final body = message.trim();
  if (body.isEmpty || body.length > feedbackMaxLength) {
    return left(const SettingsFailure(SettingsError.invalidInput));
  }
  final label = switch (kind) {
    FeedbackKind.idea => 'idea',
    FeedbackKind.problem => 'problem',
  };
  return right('Freeva $appVersionLabel\n$label\n$body');
}
