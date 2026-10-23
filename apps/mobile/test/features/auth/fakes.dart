import 'package:mobile/features/auth/data/auth_api.dart';
import 'package:mobile/features/auth/data/auth_platform.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';

class MemoryVault implements AuthVault {
  String? value;
  String? seen;
  bool fail = false;
  @override
  Future<String?> read() async {
    if (fail) throw StateError('storage');
    return value;
  }

  @override
  Future<void> write(String value) async {
    if (fail) throw StateError('storage');
    this.value = value;
  }

  @override
  Future<void> clear() async {
    if (fail) throw StateError('storage');
    value = null;
  }

  @override
  Future<String?> readSeenSessions() async {
    if (fail) throw StateError('storage');
    return seen;
  }

  @override
  Future<void> writeSeenSessions(String value) async {
    if (fail) throw StateError('storage');
    seen = value;
  }

  @override
  Future<void> clearSeenSessions() async {
    if (fail) throw StateError('storage');
    seen = null;
  }
}

class FakeBiometrics implements DeviceBiometrics {
  bool supported = true;
  bool accepted = true;
  int calls = 0;
  @override
  Future<bool> available() async => supported;
  @override
  Future<bool> authenticate(String reason) async {
    calls++;
    return accepted;
  }
}

class FakeApi implements AuthApi {
  AuthFailure? failure;
  List<Map<String, dynamic>>? sessionItems;
  String? lastPath;
  Map<String, dynamic>? lastBody;
  int calls = 0;
  Future<void>? pending;
  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? token,
    Map<String, String>? headers,
  }) async {
    calls++;
    lastPath = path;
    lastBody = body;
    if (pending != null) await pending;
    if (failure != null) throw failure!;
    if (path == 'auth/login') {
      return {
        'accessToken': 'a' * 64,
        'tokenType': 'Bearer',
        'expiresAt': DateTime.now()
            .add(const Duration(days: 7))
            .toUtc()
            .toIso8601String(),
        'sessionId': 'current',
      };
    }
    if (path == 'sessions' && method == 'GET') {
      return {
        'sessions':
            sessionItems ??
            [
              {
                'id': 'current',
                'createdAt': DateTime.now().toIso8601String(),
                'expiresAt': DateTime.now()
                    .add(const Duration(days: 7))
                    .toIso8601String(),
                'current': true,
              },
            ],
      };
    }
    return {};
  }
}
