import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../../auth/domain/auth_repository.dart';
import '../../../auth/domain/auth_use_cases.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';

/// The Bảo mật actions that change something: PIN, password and signing out
/// the other devices. One action at a time; each returns whether it worked and
/// leaves the reason in [failure].
class SecurityViewModel extends ChangeNotifier {
  SecurityViewModel(this._cases, this._auth);

  final AuthUseCases _cases;
  final AuthViewModel _auth;
  bool busy = false;
  AuthFailure? failure;
  bool _disposed = false;

  Future<bool> changePin(String oldPin, String newPin, String confirmation) =>
      _run(() => _cases.changePin(oldPin, newPin, confirmation));

  Future<bool> changePassword(
    String current,
    String next,
    String confirmation,
  ) => _run(() => _cases.changePassword(current, next, confirmation));

  Future<bool> revokeOthers() => _run(_cases.revokeOthers);

  void clear() {
    failure = null;
    notifyListeners();
  }

  Future<bool> _run(Future<Either<AuthFailure, Unit>> Function() work) async {
    if (busy) return false;
    busy = true;
    failure = null;
    notifyListeners();
    final result = await work();
    busy = false;
    final error = result.fold<AuthFailure?>((e) => e, (_) => null);
    failure = error;
    // Five wrong PINs clear the device; an expired session goes to sign-in.
    if (error?.code == AuthError.expired) _auth.sessionExpired();
    if (!_disposed) notifyListeners();
    return error == null;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
