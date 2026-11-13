import 'package:flutter/foundation.dart';

import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../domain/feedback.dart';
import '../../../server_config/domain/app_limits.dart';
import '../../../../core/app_version/app_version.dart';

/// The Góp ý form: what the user picked and typed, and sending it. The text
/// is never logged or tracked.
class FeedbackViewModel extends ChangeNotifier {
  FeedbackViewModel(this._cases, this._auth, this._limits, this._version);

  final AppVersion _version;

  /// Server limits (MOB-P5-001).
  final AppLimitsSource _limits;

  final FeedbackUseCases _cases;
  final AuthViewModel _auth;
  FeedbackKind kind = FeedbackKind.idea;
  FeedbackTopic topic = FeedbackTopic.record;
  bool allowReply = true;
  String message = '';
  bool sending = false;
  bool sent = false;
  AuthFailure? failure;

  bool get canSend =>
      !sending &&
      message.trim().isNotEmpty &&
      message.length <= _limits.requireLimits.feedbackMaxLength;

  void edit({
    FeedbackKind? kind,
    FeedbackTopic? topic,
    bool? allowReply,
    String? message,
  }) {
    this.kind = kind ?? this.kind;
    this.topic = topic ?? this.topic;
    this.allowReply = allowReply ?? this.allowReply;
    this.message = message ?? this.message;
    failure = null;
    notifyListeners();
  }

  Future<void> send() async {
    if (!canSend) return;
    sending = true;
    failure = null;
    notifyListeners();
    final result = await _cases.send(
      FeedbackDraft(
        kind: kind,
        topic: topic,
        message: message,
        allowReply: allowReply,
      ),
      _version.label,
    );
    sending = false;
    result.fold((error) {
      failure = error;
      if (error.code == AuthError.expired) _auth.sessionExpired();
    }, (_) => sent = true);
    notifyListeners();
  }
}
