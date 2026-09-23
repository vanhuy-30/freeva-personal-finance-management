import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../config/app_config.dart';

http.Client createHttpClient(AppConfig config) {
  config.validate();
  if (config.devCaCertificate.isEmpty) return http.Client();
  try {
    final context = SecurityContext(withTrustedRoots: true)
      ..setTrustedCertificatesBytes(base64Decode(config.devCaCertificate));
    // Normal certificate chain, expiry and hostname checks remain enabled.
    return IOClient(HttpClient(context: context));
  } catch (_) {
    throw StateError('Invalid development CA certificate');
  }
}
