import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/features/auth/data/auth_api.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';

void main() {
  test('HTTPS contract path, bearer and body with redirects disabled',
      () async {
    final api = HttpAuthApi.withClient(MockClient((request) async {
      expect(
          request.url.toString(), 'https://api.example.com/api/v1/auth/login');
      expect(request.followRedirects, false);
      expect(request.headers['Authorization'], 'Bearer secret');
      expect(request.body, '{"password":" secret "}');
      return http.Response('{}', 200);
    }), 'https://api.example.com');
    await api.request('POST', 'auth/login',
        body: {'password': ' secret '}, token: 'secret');
  });
  test('rejects insecure or missing endpoint without sending credentials',
      () async {
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      return http.Response('{}', 200);
    });
    for (final base in [
      '',
      'http://api.example.com',
      'https://user:pass@api.example.com'
    ]) {
      await expectLater(
          HttpAuthApi.withClient(client, base).request('POST', 'auth/login'),
          throwsA(isA<AuthFailure>()));
    }
    expect(calls, 0);
  });
  test('maps Retry-After and never surfaces raw server payloads', () async {
    final api = HttpAuthApi.withClient(
        MockClient((_) async => http.Response('sensitive response', 429,
            headers: {'retry-after': '42'})),
        'https://api.example.com');
    await expectLater(
        api.request('POST', 'auth/login'),
        throwsA(isA<AuthFailure>()
            .having((e) => e.code, 'code', AuthError.rateLimited)
            .having((e) => e.retryAfter, 'seconds', 42)));
  });
  test('authenticated 401 maps to expired; login 401 to invalid credentials',
      () async {
    final api = HttpAuthApi.withClient(
        MockClient((_) async => http.Response('', 401)),
        'https://api.example.com');
    await expectLater(
        api.request('GET', 'sessions', token: 'secret'),
        throwsA(isA<AuthFailure>()
            .having((e) => e.code, 'code', AuthError.expired)));
    await expectLater(
        api.request('POST', 'auth/login'),
        throwsA(isA<AuthFailure>()
            .having((e) => e.code, 'code', AuthError.credentials)));
  });
}
