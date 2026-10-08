import 'dart:convert';
import 'dart:math';
import 'dart:isolate';
import 'package:cryptography/cryptography.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../domain/auth_repository.dart';
import 'auth_api.dart';
import 'authorized_api.dart';
import 'auth_platform.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository, AuthorizedApi {
  AuthRepositoryImpl(this._api, this._vault, this._biometrics);
  final AuthApi _api;
  final AuthVault _vault;
  final DeviceBiometrics _biometrics;
  Map<String, dynamic>? _record;

  Future<Either<AuthFailure, T>> _guard<T>(Future<T> Function() work) async {
    try {
      return right(await work());
    } on AuthFailure catch (failure) {
      return left(failure);
    } catch (_) {
      return left(const AuthFailure(AuthError.storage));
    }
  }

  Future<void> _save(Map<String, dynamic> record) async {
    await _vault.write(jsonEncode(record));
    _record = record;
  }

  Future<void> _clear() async {
    _record = null;
    await _vault.clear();
  }

  Future<String> _token() async {
    final record = _record;
    if (record == null ||
        !DateTime.parse(record['expiresAt'] as String)
            .isAfter(DateTime.now())) {
      await _clear();
      throw const AuthFailure(AuthError.expired);
    }
    return record['accessToken'] as String;
  }

  Future<Map<String, dynamic>> _authorized(String method, String path,
      {Map<String, dynamic>? body}) async {
    final token = await _token();
    try {
      return await _api.request(method, path, token: token, body: body);
    } on AuthFailure catch (failure) {
      if (failure.code == AuthError.expired && _record?['accessToken'] == token) {
        await _clear();
      }
      rethrow;
    }
  }

  @override
  Future<Either<AuthFailure, Map<String, dynamic>>> request(
          String method, String path, {Map<String, dynamic>? body}) =>
      _guard(() => _authorized(method, path, body: body));

  @override
  Future<Either<AuthFailure, bool>> accountExists(String email) =>
      _guard(() async {
        final result = await _api
            .request('POST', 'auth/email-step', body: {'email': email});
        return switch (result['nextStep']) {
          'login' => true,
          'register' => false,
          _ => throw const AuthFailure(AuthError.unavailable),
        };
      });

  @override
  Future<Either<AuthFailure, AuthStage>> restore() => _guard(() async {
        final stored = await _vault.read();
        if (stored == null) return AuthStage.signedOut;
        _record = jsonDecode(stored) as Map<String, dynamic>;
        if (_record!['pinHash'] == null) {
          await _clear();
          return AuthStage.signedOut;
        }
        await _token();
        return AuthStage.locked;
      });
  @override
  Future<Either<AuthFailure, Unit>> submit(
          AuthAction action, Map<String, String> fields) =>
      _guard(() async {
        final path = switch (action) {
          AuthAction.login => 'login',
          AuthAction.register => 'register',
          AuthAction.requestVerification => 'email-verifications',
          AuthAction.verifyEmail => 'verify-email',
          AuthAction.requestReset => 'password-resets',
          AuthAction.resetPassword => 'reset-password',
        };
        final result = await _api.request('POST', 'auth/$path', body: fields);
        if (action == AuthAction.login) {
          if (result['tokenType'] != 'Bearer' ||
              !RegExp(r'^[a-f0-9]{64}$')
                  .hasMatch(result['accessToken'] as String)) {
            throw const AuthFailure(AuthError.unavailable);
          }
          DateTime.parse(result['expiresAt'] as String);
          await _save({...result, 'attempts': 0, 'biometrics': false});
        }
        if (action == AuthAction.resetPassword) await _clear();
        return unit;
      });
  Future<String> _hash(String pin, String salt) =>
      Isolate.run(() => derivePinHash(pin, salt));
  @override
  Future<Either<AuthFailure, Unit>> setupPin(
          String pin, bool biometrics, String reason) =>
      _guard(() async {
        await _token();
        if (!RegExp(r'^\d{6}$').hasMatch(pin) || _record!['pinHash'] != null) {
          throw const AuthFailure(AuthError.invalidInput);
        }
        if (biometrics &&
            (!await _biometrics.available() ||
                !await _biometrics.authenticate(reason))) {
          throw const AuthFailure(AuthError.unavailable);
        }
        final random = Random.secure();
        final salt =
            base64Encode(List.generate(32, (_) => random.nextInt(256)));
        final hash = await _hash(pin, salt);
        await _authorized('GET', 'sessions');
        await _save({
          ..._record!,
          'salt': salt,
          'pinHash': hash,
          'biometrics': biometrics,
        });
        return unit;
      });
  @override
  Future<Either<AuthFailure, Unit>> unlockPin(String pin) => _guard(() async {
        await _token();
        final attempts = (_record!['attempts'] as int) + 1;
        // Persist before expensive verification: process termination cannot reset attempts.
        await _save({..._record!, 'attempts': attempts});
        if (attempts > 5) {
          await _clear();
          throw const AuthFailure(AuthError.expired);
        }
        final actual = await _hash(pin, _record!['salt'] as String);
        final expected = _record!['pinHash'] as String;
        var difference = actual.length ^ expected.length;
        for (var i = 0; i < actual.length && i < expected.length; i++) {
          difference |= actual.codeUnitAt(i) ^ expected.codeUnitAt(i);
        }
        if (difference != 0) {
          if (attempts >= 5) {
            await _clear();
            throw const AuthFailure(AuthError.expired);
          }
          throw const AuthFailure(AuthError.wrongPin);
        }
        await _save({..._record!, 'attempts': 0});
        await _authorized('GET', 'sessions');
        return unit;
      });
  @override
  Future<Either<AuthFailure, Unit>> unlockBiometric(String reason) =>
      _guard(() async {
        await _token();
        if (_record!['biometrics'] != true ||
            (_record!['attempts'] as int) >= 5 ||
            !await _biometrics.available() ||
            !await _biometrics.authenticate(reason)) {
          throw const AuthFailure(AuthError.unavailable);
        }
        await _authorized('GET', 'sessions');
        return unit;
      });
  @override
  Future<Either<AuthFailure, bool>> biometricAvailable() => _guard(() async =>
      await _biometrics.available() &&
      (_record?['pinHash'] == null || _record?['biometrics'] == true));
  @override
  Future<Either<AuthFailure, List<AuthSession>>> sessions() => _guard(() async {
        final response = await _authorized('GET', 'sessions');
        return (response['sessions'] as List)
            .map((s) => AuthSession(
                s['id'] as String,
                DateTime.parse(s['createdAt'] as String),
                DateTime.parse(s['expiresAt'] as String),
                s['current'] as bool))
            .toList();
      });
  @override
  Future<Either<AuthFailure, Unit>> revoke(String? id) => _guard(() async {
        await _authorized('DELETE',
            id == null ? 'sessions' : 'sessions/${Uri.encodeComponent(id)}');
        if (id == null || id == _record?['sessionId']) await _clear();
        return unit;
      });
  @override
  Future<Either<AuthFailure, Unit>> logout() => _guard(() async {
        await _authorized('POST', 'auth/logout');
        await _clear();
        return unit;
      });
  @override
  Future<Either<AuthFailure, Unit>> forgetDevice() => _guard(() async {
        await _clear();
        return unit;
      });
}

// Keep the KDF off the UI isolate so the privacy cover remains responsive.
Future<String> derivePinHash(String pin, String salt) async {
  final key =
      await Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: 600000, bits: 256)
          .deriveKey(
              secretKey: SecretKey(utf8.encode(pin)),
              nonce: base64Decode(salt));
  return base64Encode(await key.extractBytes());
}
