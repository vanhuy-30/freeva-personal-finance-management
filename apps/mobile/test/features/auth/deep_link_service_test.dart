import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/auth_link.dart';
import 'package:mobile/features/auth/domain/deep_link_service.dart';

import '../settings/fakes.dart';

class FakeLinkSource implements LinkSource {
  Uri? initial;
  Object? initialError;
  int listeners = 0;
  final controller = StreamController<Uri>.broadcast();

  @override
  Future<Uri?> initialLink() async {
    if (initialError != null) throw initialError!;
    return initial;
  }

  @override
  Stream<Uri> get links => controller.stream
      .map((uri) => uri)
      .asBroadcastStream(onListen: (_) => listeners++);
}

void main() {
  final token = 'ab12' * 16;
  final other = 'cd34' * 16;
  Uri reset(String value) => Uri.parse('freeva://reset-password?token=$value');

  late FakeLinkSource source;
  late RecordingLogger logger;
  late DeepLinkService service;
  setUp(() {
    source = FakeLinkSource();
    logger = RecordingLogger();
    service = DeepLinkService(source, logger);
  });
  tearDown(() async {
    service.dispose();
    await source.controller.close();
  });

  String? pendingToken() {
    final link = service.pending;
    return link is ResetPasswordLink ? link.token : null;
  }

  test('keeps the launch link until someone consumes it', () async {
    source.initial = reset(token);
    var notified = 0;
    service.addListener(() => notified++);
    await service.start();
    expect(pendingToken(), token);
    expect(notified, 1);
    final link = service.pending!;
    expect(service.consume(link), isTrue);
    expect(service.pending, isNull);
    expect(service.consume(link), isFalse);
  });

  test('picks up links that arrive while the app runs', () async {
    await service.start();
    expect(service.pending, isNull);
    source.controller.add(reset(token));
    await pumpEventQueue();
    expect(pendingToken(), token);
  });

  test(
    'a newer link replaces the older one and the old handle is stale',
    () async {
      await service.start();
      source.controller.add(reset(token));
      await pumpEventQueue();
      final first = service.pending!;
      source.controller.add(reset(other));
      await pumpEventQueue();
      expect(pendingToken(), other);
      expect(service.consume(first), isFalse);
      expect(pendingToken(), other);
    },
  );

  test('the same token delivered twice is one pending link', () async {
    source.initial = reset(token);
    await service.start();
    final first = service.pending!;
    var notified = 0;
    service.addListener(() => notified++);
    source.controller.add(reset(token.toUpperCase()));
    await pumpEventQueue();
    expect(identical(service.pending, first), isTrue);
    expect(notified, 0);
  });

  test(
    'a malformed reset link becomes an invalid link, unrelated ones vanish',
    () async {
      await service.start();
      source.controller.add(Uri.parse('freeva://reset-password?token=abc'));
      await pumpEventQueue();
      expect(service.pending, isA<InvalidAuthLink>());
      service.consume(service.pending!);
      source.controller.add(Uri.parse('freeva://open'));
      source.controller.add(Uri.parse('https://example.test/other'));
      await pumpEventQueue();
      expect(service.pending, isNull);
    },
  );

  test('start twice listens once', () async {
    await service.start();
    await service.start();
    source.controller.add(reset(token));
    await pumpEventQueue();
    expect(pendingToken(), token);
    expect(source.controller.hasListener, isTrue);
  });

  test('a failing link channel is logged and never throws', () async {
    source.initialError = StateError('no channel');
    await service.start();
    expect(service.pending, isNull);
    expect(logger.messages, contains('deep link start failed'));
  });

  test('never logs the URI or the token', () async {
    source.initial = reset(token);
    await service.start();
    source.controller.add(reset(other));
    await pumpEventQueue();
    expect(logger.messages.join(' '), isNot(contains(token)));
    expect(logger.messages.join(' '), isNot(contains(other)));
    expect(logger.messages.join(' '), isNot(contains('reset-password')));
  });

  test('ignores links after dispose', () async {
    await service.start();
    service.dispose();
    service.handle(reset(token));
    expect(service.pending, isNull);
    // Disposed in tearDown again; make that a no-op for the test harness.
    service = DeepLinkService(source, logger);
  });
}
