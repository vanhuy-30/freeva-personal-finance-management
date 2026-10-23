import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'auth_repository.dart';
import 'session_notice.dart';

abstract class AuthUseCases {
  Future<Either<AuthFailure, AuthStage>> restore();
  Future<Either<AuthFailure, bool>> accountExists(String email);
  Future<Either<AuthFailure, Unit>> submit(
    AuthAction action,
    Map<String, String> fields,
  );
  Future<Either<AuthFailure, Unit>> setupPin(
    String pin,
    String confirmation,
    bool biometrics,
    String reason,
  );
  Future<Either<AuthFailure, Unit>> unlockPin(String pin);
  Future<Either<AuthFailure, Unit>> changePin(
    String oldPin,
    String newPin,
    String confirmation,
  );
  Future<Either<AuthFailure, Unit>> changePassword(
    String current,
    String next,
    String confirmation,
  );
  Future<Either<AuthFailure, Unit>> revokeOthers();
  Future<Either<AuthFailure, Unit>> unlockBiometric(String reason);
  Future<Either<AuthFailure, bool>> biometricAvailable();
  Future<Either<AuthFailure, bool>> biometricHardware();
  Future<Either<AuthFailure, bool>> biometricEnabled();
  Future<Either<AuthFailure, String?>> accountEmail();
  Future<Either<AuthFailure, Unit>> setBiometricEnabled(
    bool enabled,
    String reason,
  );
  Future<Either<AuthFailure, List<AuthSession>>> sessions();
  Future<Either<AuthFailure, SessionNoticeDecision>> observeSessions();
  Future<Either<AuthFailure, Unit>> revoke(String? id);
  Future<Either<AuthFailure, Unit>> logout();
  Future<Either<AuthFailure, Unit>> forgetDevice();
}

@Injectable(as: AuthUseCases)
class DefaultAuthUseCases implements AuthUseCases {
  DefaultAuthUseCases(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<AuthFailure, bool>> accountExists(String email) {
    final normalized = email.trim().toLowerCase();
    if (normalized.length > 254 ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalized)) {
      return Future.value(left(const AuthFailure(AuthError.invalidEmail)));
    }
    return _repository.accountExists(normalized);
  }

  @override
  Future<Either<AuthFailure, AuthStage>> restore() => _repository.restore();
  @override
  Future<Either<AuthFailure, Unit>> submit(
    AuthAction action,
    Map<String, String> fields,
  ) {
    final requiredFields = switch (action) {
      AuthAction.login || AuthAction.register => {'email', 'password'},
      AuthAction.requestVerification || AuthAction.requestReset => {'email'},
      AuthAction.verifyEmail => {'token'},
      AuthAction.resetPassword => {'token', 'password'},
    };
    if (fields.length != requiredFields.length ||
        !fields.keys.toSet().containsAll(requiredFields)) {
      return Future.value(left(const AuthFailure(AuthError.invalidInput)));
    }
    final email = fields['email']?.trim().toLowerCase();
    final password = fields['password'];
    final token = fields['token'];
    // A new password needs a letter and a digit (any script); login keeps
    // the length rule only, so older passwords still work.
    final newPassword =
        action == AuthAction.register || action == AuthAction.resetPassword;
    if ((email != null &&
            (email.length > 254 ||
                !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email))) ||
        (password != null && (password.length < 12 || password.length > 128)) ||
        (newPassword && password != null && !hasLetterAndDigit(password)) ||
        (token != null && !RegExp(r'^[a-f0-9]{64}$').hasMatch(token))) {
      return Future.value(left(const AuthFailure(AuthError.invalidInput)));
    }
    return _repository.submit(action, {
      ...fields,
      if (email != null) 'email': email,
    });
  }

  @override
  Future<Either<AuthFailure, Unit>> setupPin(
    String pin,
    String confirmation,
    bool biometrics,
    String reason,
  ) {
    if (!RegExp(r'^\d{6}$').hasMatch(pin) || pin != confirmation) {
      return Future.value(left(const AuthFailure(AuthError.invalidInput)));
    }
    return _repository.setupPin(pin, biometrics, reason);
  }

  @override
  Future<Either<AuthFailure, Unit>> unlockPin(String pin) =>
      _repository.unlockPin(pin);
  @override
  Future<Either<AuthFailure, Unit>> changePin(
    String oldPin,
    String newPin,
    String confirmation,
  ) {
    final pin = RegExp(r'^\d{6}$');
    if (!pin.hasMatch(oldPin) || !pin.hasMatch(newPin)) {
      return Future.value(left(const AuthFailure(AuthError.invalidInput)));
    }
    if (newPin != confirmation) {
      return Future.value(left(const AuthFailure(AuthError.passwordMismatch)));
    }
    if (newPin == oldPin) {
      return Future.value(left(const AuthFailure(AuthError.invalidInput)));
    }
    return _repository.changePin(oldPin, newPin);
  }

  @override
  Future<Either<AuthFailure, Unit>> changePassword(
    String current,
    String next,
    String confirmation,
  ) {
    if (next != confirmation) {
      return Future.value(left(const AuthFailure(AuthError.passwordMismatch)));
    }
    if (current.isEmpty ||
        current.length > 128 ||
        next.length < 12 ||
        next.length > 128 ||
        !hasLetterAndDigit(next) ||
        next == current) {
      return Future.value(left(const AuthFailure(AuthError.invalidInput)));
    }
    return _repository.changePassword(current, next);
  }

  @override
  Future<Either<AuthFailure, Unit>> revokeOthers() =>
      _repository.revokeOthers();
  @override
  Future<Either<AuthFailure, Unit>> unlockBiometric(String reason) =>
      _repository.unlockBiometric(reason);
  @override
  Future<Either<AuthFailure, bool>> biometricAvailable() =>
      _repository.biometricAvailable();
  @override
  Future<Either<AuthFailure, bool>> biometricHardware() =>
      _repository.biometricHardware();
  @override
  Future<Either<AuthFailure, bool>> biometricEnabled() =>
      _repository.biometricEnabled();
  @override
  Future<Either<AuthFailure, String?>> accountEmail() =>
      _repository.accountEmail();
  @override
  Future<Either<AuthFailure, Unit>> setBiometricEnabled(
    bool enabled,
    String reason,
  ) => _repository.setBiometricEnabled(enabled, reason);
  @override
  Future<Either<AuthFailure, List<AuthSession>>> sessions() =>
      _repository.sessions();
  @override
  Future<Either<AuthFailure, SessionNoticeDecision>> observeSessions() =>
      _repository.observeSessions();
  @override
  Future<Either<AuthFailure, Unit>> revoke(String? id) =>
      _repository.revoke(id);
  @override
  Future<Either<AuthFailure, Unit>> logout() => _repository.logout();
  @override
  Future<Either<AuthFailure, Unit>> forgetDevice() =>
      _repository.forgetDevice();
}

/// At least one letter and one digit, in any script (Vietnamese included).
bool hasLetterAndDigit(String password) =>
    RegExp(r'\p{L}', unicode: true).hasMatch(password) &&
    RegExp(r'\p{Nd}', unicode: true).hasMatch(password);
