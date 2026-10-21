import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/core/sentry/sentry_scrub.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  const email = 'user@example.com';
  const secret = 'secret-token';
  const amount = 150000;

  test('scrubs PII from a Sentry event and drops the user', () {
    final event = SentryEvent(
      message: SentryMessage('failed for $email Bearer $secret'),
      user: SentryUser(email: email, ipAddress: '203.0.113.5'),
      request: SentryRequest(
        method: 'POST',
        url: 'https://api.example.com/sync?token=$secret',
        data: const {'email': email, 'amountMinor': amount},
        headers: const {'authorization': 'Bearer $secret'},
      ),
      contexts: Contexts()
        ..['finance'] = {
          'email': email,
          'amountMinor': amount,
          'userId': '11111111-1111-4111-8111-111111111111',
        },
      breadcrumbs: [
        Breadcrumb(
          type: 'http',
          category: 'http',
          message: email,
          data: {
            'method': 'GET',
            'url': 'https://api.example.com/health?email=$email',
            'status_code': 500,
            'request_body_size': 12,
          },
        ),
      ],
      exceptions: [
        SentryException(
          type: 'StateError',
          value: 'smtp failed for $email',
        ),
      ],
    );

    final scrubbed = scrubSentryEvent(event, Hint());
    final serialized = scrubbed!.toJson().toString();

    expect(serialized.contains(email), isFalse);
    expect(serialized.contains(secret), isFalse);
    expect(serialized.contains('$amount'), isFalse);
    expect(serialized.contains('203.0.113.5'), isFalse);
    expect(scrubbed.user, isNull);
    expect(scrubbed.request?.method, 'POST');
    expect(scrubbed.request?.url, 'https://api.example.com/sync');
    expect(scrubbed.request?.data, isNull);
    expect(scrubbed.contexts['finance'], {
      'userId': '11111111-1111-4111-8111-111111111111',
      'email': sentryRedactCensor,
      'amountMinor': sentryRedactCensor,
    });
    expect(
      scrubbed.breadcrumbs?.single.data?['url'],
      'https://api.example.com/health',
    );
    expect(
      scrubbed.breadcrumbs?.single.data?.containsKey('request_body_size'),
      isFalse,
    );
  });

  test('drops client HTTP statuses', () {
    final dropped = scrubSentryPayload({
      'message': {'formatted': 'missing'},
      'contexts': {
        'response': {'status_code': 404},
      },
    });
    expect(responseStatus(dropped), 404);
    expect(
      scrubSentryEvent(
        SentryEvent(
          message: SentryMessage('missing'),
          contexts: Contexts(response: SentryResponse(statusCode: 404)),
        ),
        Hint(),
      ),
      isNull,
    );
  });

  test('validation does not reveal the Sentry DSN', () {
    final config = AppConfig.fromValues(
      environment: 'staging',
      apiBaseUrl: 'http://insecure.example',
      sentryDsn: 'https://secret@o0.ingest.sentry.io/1',
    );

    expect(config.sentryEnabled, isTrue);
    expect(
      () => config.validate(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message.contains('secret'),
          'message',
          isFalse,
        ),
      ),
    );
  });
}
