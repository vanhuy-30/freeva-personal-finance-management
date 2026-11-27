import '../../domain/auth_link.dart';
import '../../domain/auth_repository.dart';
import '../../domain/deep_link_service.dart';
import 'auth_view_model.dart';

/// Acts on the link waiting in [DeepLinkService] once the app can take it.
///
/// A reset link needs the signed-out flow. If the person is signed in (or
/// locked, or finishing sign-up) the reset would end every session anyway, so
/// [confirmSignOut] asks first; only a yes signs this device out.
class AuthLinkHandler {
  AuthLinkHandler({
    required this.service,
    required this.auth,
    required this.confirmSignOut,
    required this.onInvalidLink,
    required this.onSignOutFailed,
  });

  final DeepLinkService service;
  final AuthViewModel auth;

  /// Asks whether to sign out of this device to reset the password.
  final Future<bool> Function() confirmSignOut;
  final void Function() onInvalidLink;
  final void Function() onSignOutFailed;

  bool _busy = false;

  /// Handles the pending link if the auth state allows it. Call again whenever
  /// the pending link or the auth state changes; it does nothing otherwise.
  Future<void> process() async {
    if (_busy) return;
    final link = service.pending;
    // Before `ready` the stored session has not been read, so the stage is
    // not known yet; during a request the result could overwrite our change.
    if (link == null || !auth.ready || auth.loading) return;
    _busy = true;
    try {
      switch (link) {
        case InvalidAuthLink():
          service.consume(link);
          onInvalidLink();
        case ResetPasswordLink(:final token):
          await _reset(link, token);
      }
    } finally {
      _busy = false;
    }
    // A newer link may have replaced this one while a dialog was open.
    final next = service.pending;
    if (next != null && !identical(next, link)) await process();
  }

  Future<void> _reset(ResetPasswordLink link, String token) async {
    if (auth.stage == AuthStage.signedOut) {
      service.consume(link);
      auth.startReset(token);
      return;
    }
    final agreed = await confirmSignOut();
    // Only drop the link we asked about; a newer one stays for the next pass.
    if (!service.consume(link) || !agreed) return;
    // The stage may have changed while the dialog was open (auto-lock, expiry).
    if (auth.stage != AuthStage.signedOut) await auth.logout();
    if (auth.stage == AuthStage.signedOut) {
      auth.startReset(token);
    } else {
      onSignOutFailed();
    }
  }
}
