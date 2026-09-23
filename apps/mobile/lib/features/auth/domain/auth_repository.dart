import 'package:dartz/dartz.dart';

enum AuthStage { signedOut, setupPin, locked, unlocked }

enum AuthAction {
  login,
  register,
  requestVerification,
  verifyEmail,
  requestReset,
  resetPassword
}

enum AuthError {
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
  expired
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
      AuthAction action, Map<String, String> fields);
  Future<Either<AuthFailure, Unit>> setupPin(
      String pin, bool biometrics, String reason);
  Future<Either<AuthFailure, Unit>> unlockPin(String pin);
  Future<Either<AuthFailure, Unit>> unlockBiometric(String reason);
  Future<Either<AuthFailure, bool>> biometricAvailable();
  Future<Either<AuthFailure, List<AuthSession>>> sessions();
  Future<Either<AuthFailure, Unit>> revoke(String? id);
  Future<Either<AuthFailure, Unit>> logout();
  Future<Either<AuthFailure, Unit>> forgetDevice();
}
