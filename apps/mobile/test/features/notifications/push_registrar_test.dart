import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/session_alert_notifier.dart';
import 'package:mobile/features/notifications/data/fcm_push_registrar.dart';
import 'package:mobile/features/notifications/domain/push_registrar.dart';

class _Tokens implements PushTokenRepository {
  int puts = 0;
  int removes = 0;

  @override
  Future<Either<AuthFailure, Unit>> put(String token, String platform) async {
    puts += 1;
    return right(unit);
  }

  @override
  Future<Either<AuthFailure, Unit>> remove() async {
    removes += 1;
    return right(unit);
  }
}

class _Permission implements SessionAlertNotifier {
  _Permission(this.current);

  NotificationAccess current;
  int requests = 0;

  @override
  Future<NotificationAccess> access() async => current;

  @override
  Future<NotificationAccess> requestAccess() async {
    requests += 1;
    return current;
  }

  @override
  Future<void> show({required String title, required String body}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('does not ask for permission nor register when not requested', () async {
    final tokens = _Tokens();
    final permission = _Permission(NotificationAccess.denied);
    await FcmPushRegistrar(tokens, permission).sync();
    expect(permission.requests, 0);
    expect(tokens.puts, 0);
  });

  test('asks once when a kind is turned on and stops if refused', () async {
    final tokens = _Tokens();
    final permission = _Permission(NotificationAccess.denied);
    await FcmPushRegistrar(tokens, permission).sync(requestPermission: true);
    expect(permission.requests, 1);
    expect(tokens.puts, 0);
  });

  test('without Firebase config it stays off and never throws', () async {
    final tokens = _Tokens();
    final permission = _Permission(NotificationAccess.granted);
    final registrar = FcmPushRegistrar(tokens, permission);
    await registrar.sync();
    await registrar.clear();
    expect(tokens.puts, 0);
  });
}
