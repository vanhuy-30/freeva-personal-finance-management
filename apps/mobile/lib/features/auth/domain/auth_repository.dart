import 'package:dartz/dartz.dart';

import 'session_notice.dart';

enum AuthStage { signedOut, setupPin, locked, unlocked }

enum AuthAction {
  login,
  register,
  requestVerification,
  verifyEmail,
  requestReset,
  resetPassword,
}

enum AuthError {
  conflict,
  invalidInput,
  invalidEmail,
  passwordMismatch,
  credentials,
  invalidToken,
  rateLimited,
  network,
  storage,
  unavailable,
  wrongPin,
  expired,
}

class AuthFailure {
  const AuthFailure(this.code, {this.retryAfter});
  final AuthError code;
  final int? retryAfter;
}

class AuthSession {
  const AuthSession(this.id, this.createdAt, this.expiresAt, this.current);
  final String id;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool current;
}

abstract class AuthRepository {
  Future<Either<AuthFailure, AuthStage>> restore();
  Future<Either<AuthFailure, bool>> accountExists(String email);
  Future<Either<AuthFailure, Unit>> submit(
    AuthAction action,
    Map<String, String> fields,
  );
  Future<Either<AuthFailure, Unit>> setupPin(
    String pin,
    bool biometrics,
    String reason,
  );
  Future<Either<AuthFailure, Unit>> unlockPin(String pin);

  /// Checks [oldPin] (counted like an unlock attempt) and stores [newPin].
  Future<Either<AuthFailure, Unit>> changePin(String oldPin, String newPin);

  /// Signed-in password change. A wrong current password is
  /// [AuthError.credentials]; the other sessions end on the server.
  Future<Either<AuthFailure, Unit>> changePassword(String current, String next);

  /// Ends every session except this one.
  Future<Either<AuthFailure, Unit>> revokeOthers();
  Future<Either<AuthFailure, Unit>> unlockBiometric(String reason);
  Future<Either<AuthFailure, bool>> biometricAvailable();
  Future<Either<AuthFailure, bool>> biometricHardware();
  Future<Either<AuthFailure, bool>> biometricEnabled();

  /// Email this device signed in with; null for sessions saved before it was kept.
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
