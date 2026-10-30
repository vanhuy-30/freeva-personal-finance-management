import 'package:dartz/dartz.dart';

import 'session_notice.dart';

/// [setup] is the first run after sign-up (confirm email, then an optional
/// PIN); everything in it can be skipped. Without a PIN the app never locks.
enum AuthStage { signedOut, setup, locked, unlocked }

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

  /// The category's kind does not fit the transaction type (expense/income).
  categoryKind,
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

  /// Whether this device has a PIN. Skipping it at sign-up leaves none.
  Future<Either<AuthFailure, bool>> pinSet();

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

  /// Name for "Chào {tên}" on the lock screen. Kept with the session record
  /// on this device and dropped with it; null or blank clears it.
  Future<Either<AuthFailure, Unit>> rememberName(String? name);
  Future<Either<AuthFailure, String?>> savedName();
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
