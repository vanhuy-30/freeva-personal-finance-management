// MOB-P1-001: connection-only probe; sends no credentials or email.
import 'dart:convert';
import 'dart:io';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/core/network/create_http_client.dart';

Future<void> main(List<String> arguments) async {
  final file = arguments.isEmpty ? 'config/dev.json' : arguments.single;
  final values =
      jsonDecode(await File(file).readAsString()) as Map<String, dynamic>;
  final config = AppConfig.fromValues(
    environment: values['APP_ENV'] as String,
    apiBaseUrl: values['API_BASE_URL'] as String,
    devCaCertificate: values['DEV_CA_CERT_BASE64'] as String? ?? '',
  );
  final client = createHttpClient(config);
  try {
    final response = await client
        .get(Uri.parse('${config.apiBaseUrl}/api/health'))
        .timeout(const Duration(seconds: 10));
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || body['database'] != 'up') {
      throw StateError('Local API/database is not ready');
    }
    stdout.writeln(
        'PASS: Dart client verified HTTPS certificate and API/database health.');
  } finally {
    client.close();
  }
}
