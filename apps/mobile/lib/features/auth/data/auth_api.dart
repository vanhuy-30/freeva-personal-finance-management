import 'dart:convert';

import '../../../../core/config/app_config.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/logging/log_scrub.dart';
import '../../../../core/network/create_http_client.dart';

import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

import '../domain/auth_repository.dart';

abstract class AuthApi {
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? token,
    Map<String, String>? headers,
  });
}

@LazySingleton(as: AuthApi)
class HttpAuthApi implements AuthApi {
  HttpAuthApi(AppConfig config, AppLogger logger)
    : this.withClient(createHttpClient(config), config.apiBaseUrl, logger);

  HttpAuthApi.withClient(this._client, this._baseUrl, [this._logger]);

  final http.Client _client;
  final String _baseUrl;
  final AppLogger? _logger;

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? token,
    Map<String, String>? headers,
  }) async {
    final base = Uri.tryParse(_baseUrl);
    if (base == null ||
        base.scheme != 'https' ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment) {
      throw const AuthFailure(AuthError.unavailable);
    }
    final started = DateTime.now();
    _logger?.http(
      '→ $method $path body=${summarizePayload(body)}'
      '${token != null ? ' auth=Bearer' : ''}',
    );
    try {
      final request = http.Request(method, base.resolve('/api/v1/$path'))
        ..followRedirects = false
        ..headers['Content-Type'] = 'application/json';
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      if (headers != null) request.headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 20));
      final ms = DateTime.now().difference(started).inMilliseconds;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _logger?.http('← $method $path ${response.statusCode} ${ms}ms');
        return response.body.isEmpty
            ? {}
            : jsonDecode(response.body) as Map<String, dynamic>;
      }
      _logger?.http('← $method $path ${response.statusCode} ${ms}ms');
      throw AuthFailure(switch (response.statusCode) {
        401 => token == null ? AuthError.credentials : AuthError.expired,
        // Signed in but refused: the current password was wrong.
        403 when token != null => AuthError.credentials,
        429 => AuthError.rateLimited,
        400 => AuthError.invalidToken,
        409 => AuthError.conflict,
        _ => AuthError.unavailable,
      }, retryAfter: int.tryParse(response.headers['retry-after'] ?? ''));
    } on AuthFailure {
      rethrow;
    } catch (error, stackTrace) {
      final ms = DateTime.now().difference(started).inMilliseconds;
      _logger?.error('http $method $path failed ${ms}ms', error, stackTrace);
      throw const AuthFailure(AuthError.network);
    }
  }
}
