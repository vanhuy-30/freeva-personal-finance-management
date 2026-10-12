import 'package:sentry_flutter/sentry_flutter.dart';

const sentryRedactCensor = '[REDACTED]';

final _sensitiveKeys = <String>{
  'email',
  'password',
  'pass',
  'apikey',
  'resend_api_key',
  'smtp_password',
  'auth_secret_key',
  'passwordhash',
  'token',
  'idtoken',
  'challengetoken',
  'nonce',
  'subject',
  'tokenhash',
  'encryptedtoken',
  'refreshtoken',
  'accesstoken',
  'authorization',
  'cookie',
  'set-cookie',
  'accountnumber',
  'iban',
  'database_url',
  'sentry_dsn',
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
};

final _emailPattern = RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}');
final _bearerPattern = RegExp(
  r'Bearer\s+[A-Za-z0-9\-._~+/]+=*',
  caseSensitive: false,
);
final _dsnPattern = RegExp(r'https://[^\s@]+@[^\s]*sentry\.io[^\s]*');

bool isSensitiveKey(String key) {
  final normalized = key.toLowerCase();
  return _sensitiveKeys.contains(normalized) || normalized.endsWith('minor');
}

String scrubString(String value) {
  return value
      .replaceAll(_emailPattern, sentryRedactCensor)
      .replaceAll(_bearerPattern, 'Bearer $sentryRedactCensor')
      .replaceAll(_dsnPattern, sentryRedactCensor);
}

String stripUrl(String url) {
  final query = url.indexOf('?');
  final hash = url.indexOf('#');
  var end = url.length;
  if (query >= 0) {
    end = end < query ? end : query;
  }
  if (hash >= 0 && hash < end) {
    end = hash;
  }
  return url.substring(0, end);
}

dynamic redactValue(dynamic value, [Set<Object>? seen]) {
  if (value is String) {
    return scrubString(value);
  }
  if (value is! Map && value is! List) {
    return value;
  }
  final visited = seen ?? <Object>{};
  if (visited.contains(value)) {
    return sentryRedactCensor;
  }
  visited.add(value);
  if (value is List) {
    return value.map((item) => redactValue(item, visited)).toList();
  }
  final next = <String, dynamic>{};
  for (final entry in (value as Map).entries) {
    final key = entry.key.toString();
    next[key] = isSensitiveKey(key)
        ? sentryRedactCensor
        : redactValue(entry.value, visited);
  }
  return next;
}

dynamic scrubBreadcrumbPayload(dynamic breadcrumb) {
  if (breadcrumb is! Map) {
    return breadcrumb;
  }
  final next = Map<String, dynamic>.from(breadcrumb);
  final message = next['message'];
  if (message is String) {
    next['message'] = scrubString(message);
  }
  final data = next['data'];
  if (data is! Map) {
    return next;
  }
  final type = next['type'];
  final category = next['category'];
  if (type == 'http' || category == 'http') {
    final url = data['url'];
    next['data'] = {
      'method': data['method'],
      'status_code': data['status_code'],
      'url': url is String ? stripUrl(url) : null,
    };
    return next;
  }
  next['data'] = redactValue(data);
  return next;
}

int? responseStatus(Map<String, dynamic> event) {
  final contexts = event['contexts'];
  if (contexts is! Map) {
    return null;
  }
  final response = contexts['response'];
  if (response is! Map) {
    return null;
  }
  final status = response['status_code'];
  return status is int ? status : null;
}

Map<String, dynamic> scrubSentryPayload(Map<String, dynamic> event) {
  final next = Map<String, dynamic>.from(event)..remove('user');
  final request = next['request'];
  if (request is Map) {
    final url = request['url'];
    next['request'] = {
      if (request['method'] != null) 'method': request['method'],
      if (url is String) 'url': stripUrl(url),
    };
  }
  final message = next['message'];
  if (message is String) {
    next['message'] = scrubString(message);
  } else if (message is Map) {
    next['message'] = redactValue(message);
  }
  final exception = next['exception'];
  if (exception is Map) {
    final values = exception['values'];
    if (values is List) {
      next['exception'] = {
        ...exception,
        'values': values.map(_scrubException).toList(),
      };
    }
  }
  for (final key in ['extra', 'contexts', 'tags']) {
    if (next[key] != null) {
      next[key] = redactValue(next[key]);
    }
  }
  final breadcrumbs = next['breadcrumbs'];
  if (breadcrumbs is List) {
    next['breadcrumbs'] = breadcrumbs
        .map(scrubBreadcrumbPayload)
        .toList(growable: false);
  }
  return next;
}

dynamic _scrubException(dynamic item) {
  if (item is! Map) {
    return item;
  }
  final next = Map<String, dynamic>.from(item);
  final value = next['value'];
  if (value is String) {
    next['value'] = scrubString(value);
  }
  final stacktrace = next['stacktrace'];
  if (stacktrace is Map && stacktrace['frames'] is List) {
    next['stacktrace'] = {
      ...stacktrace,
      'frames': (stacktrace['frames'] as List).map((frame) {
        if (frame is! Map) {
          return frame;
        }
        final copy = Map<String, dynamic>.from(frame)..remove('vars');
        return copy;
      }).toList(),
    };
  }
  return next;
}

SentryEvent? scrubSentryEvent(SentryEvent event, Hint hint) {
  final payload = event.toJson();
  final status = responseStatus(payload);
  if (status != null && status < 500) {
    return null;
  }
  try {
    return SentryEvent.fromJson(scrubSentryPayload(payload));
  } catch (_) {
    return null;
  }
}

Breadcrumb? scrubSentryBreadcrumb(Breadcrumb? breadcrumb, Hint hint) {
  if (breadcrumb == null) {
    return null;
  }
  final scrubbed = scrubBreadcrumbPayload(breadcrumb.toJson());
  if (scrubbed is! Map) {
    return null;
  }
  return Breadcrumb.fromJson(Map<String, dynamic>.from(scrubbed));
}
