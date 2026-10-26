/// Redact PII / money before writing to the debug console.
const logRedactCensor = '[REDACTED]';

final _sensitiveKeys = <String>{
  'email',
  'password',
  'pass',
  'token',
  'accesstoken',
  'refreshtoken',
  'idtoken',
  'challengetoken',
  'authorization',
  'cookie',
  'set-cookie',
  'accountnumber',
  'iban',
  'amountminor',
  'initialbalanceminor',
  'creditlimitminor',
  'balanceminor',
  'incomeminor',
  'expenseminor',
  'netminor',
  'transferminor',
  'assetsminor',
  'liabilitiesminor',
  'networthminor',
  'pin',
  'pinhash',
  'salt',
};

bool isSensitiveLogKey(String key) {
  final normalized = key.toLowerCase();
  return _sensitiveKeys.contains(normalized) || normalized.endsWith('minor');
}

/// Summarize a JSON-like map for logs: keys only, sensitive values censored.
String summarizePayload(Map<String, dynamic>? body) {
  if (body == null || body.isEmpty) return '{}';
  final parts = <String>[];
  for (final entry in body.entries) {
    final key = entry.key;
    if (isSensitiveLogKey(key)) {
      parts.add('$key=$logRedactCensor');
    } else if (entry.value is Map || entry.value is List) {
      parts.add('$key=<${entry.value.runtimeType}>');
    } else {
      parts.add('$key=${entry.value}');
    }
  }
  return '{${parts.join(', ')}}';
}
