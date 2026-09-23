import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import '../domain/auth_repository.dart';

abstract class AuthApi {
  Future<Map<String, dynamic>> request(String method, String path,
      {Map<String, String>? body, String? token});
}

@LazySingleton(as: AuthApi)
class HttpAuthApi implements AuthApi {
  HttpAuthApi()
      : this.withClient(
            http.Client(), const String.fromEnvironment('API_BASE_URL'));
  HttpAuthApi.withClient(this._client, this._baseUrl);
  final http.Client _client;
  final String _baseUrl;

  @override
  Future<Map<String, dynamic>> request(String method, String path,
      {Map<String, String>? body, String? token}) async {
    final base = Uri.tryParse(_baseUrl);
    if (base == null ||
        base.scheme != 'https' ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment) {
      throw const AuthFailure(AuthError.unavailable);
    }
    try {
      final request = http.Request(method, base.resolve('/api/v1/$path'))
        ..followRedirects = false
        ..headers['Content-Type'] = 'application/json';
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      if (body != null) request.body = jsonEncode(body);
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body.isEmpty
            ? {}
            : jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw AuthFailure(
          switch (response.statusCode) {
            401 => token == null ? AuthError.credentials : AuthError.expired,
            429 => AuthError.rateLimited,
            400 => AuthError.invalidToken,
            _ => AuthError.unavailable,
          },
          retryAfter: int.tryParse(response.headers['retry-after'] ?? ''));
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure(AuthError.network);
    }
  }
}
