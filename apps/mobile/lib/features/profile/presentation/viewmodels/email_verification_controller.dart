import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../auth/domain/auth_repository.dart';

/// Where "Gửi link xác nhận" stands on Hồ sơ.
enum EmailSendState {
  /// Nothing sent yet, or the cooldown is over: the person may send.
  idle,
  sending,

  /// Sent; the button stays away for the cooldown so it cannot be spammed.
  sent,

  /// The server refused for now (5 per 15 minutes per email).
  limited,

  /// The request did not go through (offline, server down).
  failed,
}

/// Resends the verification email from Hồ sơ.
///
/// The server answers 202 whether or not it sent anything, so success here
/// only means "asked". Whether the email is confirmed comes from the profile.
class EmailVerificationController extends ChangeNotifier {
  EmailVerificationController({
    required this.resend,
    this.cooldown = const Duration(seconds: 60),
  });

  /// Sends the email; returns the failure, or null when the server accepted.
  final Future<AuthFailure?> Function() resend;
  final Duration cooldown;

  EmailSendState state = EmailSendState.idle;

  /// Minutes until a refused send may be retried; null otherwise.
  int? retryMinutes;
  Timer? _timer;
  bool _disposed = false;

  bool get canSend =>
      state == EmailSendState.idle || state == EmailSendState.failed;

  Future<void> send() async {
    if (!canSend) return;
    state = EmailSendState.sending;
    retryMinutes = null;
    notifyListeners();
    final failure = await resend();
    if (_disposed) return;
    if (failure == null) {
      state = EmailSendState.sent;
      _wait(cooldown);
    } else if (failure.code == AuthError.rateLimited) {
      final seconds = failure.retryAfter ?? 900;
      state = EmailSendState.limited;
      retryMinutes = (seconds / 60).ceil().clamp(1, 60);
      _wait(Duration(seconds: seconds));
    } else {
      state = EmailSendState.failed;
    }
    notifyListeners();
  }

  void _wait(Duration duration) {
    _timer?.cancel();
    _timer = Timer(duration, () {
      if (_disposed) return;
      state = EmailSendState.idle;
      retryMinutes = null;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
