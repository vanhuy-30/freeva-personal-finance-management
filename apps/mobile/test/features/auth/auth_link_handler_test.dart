import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/domain/deep_link_service.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_link_handler.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';

import '../../support/server_config_fixture.dart';
import '../settings/fakes.dart';
import 'deep_link_service_test.dart' show FakeLinkSource;
import 'fakes.dart';

void main() {
  final token = 'ab12' * 16;
  final other = 'cd34' * 16;
  const password = 'correct horse battery 7';
  Uri reset(String value) => Uri.parse('freeva://reset-password?token=$value');

  late FakeApi api;
  late DefaultAuthViewModel auth;
  late FakeLinkSource source;
  late DeepLinkService service;
  late AuthLinkHandler handler;
  late List<String> events;
  late Future<bool> Function() confirm;

  setUp(() {
    api = FakeApi();
    auth = DefaultAuthViewModel(
      DefaultAuthUseCases(
        AuthRepositoryImpl(
          api,
          MemoryVault(),
          FakeBiometrics(),
          testServerConfigModel(),
        ),
        testServerConfigModel(),
      ),
    );
    source = FakeLinkSource();
    service = DeepLinkService(source, RecordingLogger());
    events = [];
    confirm = () async {
      events.add('confirm');
      return true;
    };
    handler = AuthLinkHandler(
      service: service,
      auth: auth,
      confirmSignOut: () => confirm(),
      onInvalidLink: () => events.add('invalid'),
      onSignOutFailed: () => events.add('signOutFailed'),
    );
  });
  tearDown(() async {
    auth.dispose();
    service.dispose();
    await source.controller.close();
  });

  Future<void> signIn() async {
    await auth.initialize();
    await auth.login('user@example.com', password);
    expect(auth.stage, AuthStage.unlocked);
  }

  group('signed out', () {
    test(
      'opens the new-password screen with the token once auth is ready',
      () async {
        service.handle(reset(token));
        await handler.process();
        // Not ready: the stored session has not been read, so nothing happens.
        expect(auth.step, isNot(AuthStep.reset));
        expect(service.pending, isNotNull);

        await auth.initialize();
        await handler.process();
        expect(auth.step, AuthStep.reset);
        expect(service.pending, isNull);
        expect(events, isEmpty);

        await auth.resetPassword('', password, password);
        expect(api.lastPath, 'auth/reset-password');
        expect(api.lastBody?['token'], token);
        expect(auth.step, AuthStep.login);
      },
    );

    test('wins over the Welcome screen of a fresh install', () async {
      service.handle(reset(token));
      await auth.initialize();
      auth.goTo(AuthStep.welcome);
      await handler.process();
      expect(auth.step, AuthStep.reset);
    });

    test('waits while a request is running, then applies', () async {
      await auth.initialize();
      final gate = Completer<void>();
      api.pending = gate.future;
      final running = auth.requestReset('user@example.com');
      await pumpEventQueue();
      expect(auth.loading, isTrue);
      service.handle(reset(token));
      await handler.process();
      expect(auth.step, isNot(AuthStep.reset));
      expect(service.pending, isNotNull);
      gate.complete();
      await running;
      await handler.process();
      expect(auth.step, AuthStep.reset);
    });

    test('a newer link replaces the token on the reset screen', () async {
      await auth.initialize();
      service.handle(reset(token));
      await handler.process();
      service.handle(reset(other));
      await handler.process();
      expect(auth.step, AuthStep.reset);
      await auth.resetPassword('', password, password);
      expect(api.lastBody?['token'], other);
    });

    test('no pending link does nothing', () async {
      await auth.initialize();
      await handler.process();
      expect(auth.step, AuthStep.login);
      expect(events, isEmpty);
    });
  });

  group('signed in', () {
    test('asks first, then signs out and opens the reset screen', () async {
      await signIn();
      service.handle(reset(token));
      await handler.process();
      expect(events, ['confirm']);
      expect(api.calls, greaterThan(1));
      expect(auth.stage, AuthStage.signedOut);
      expect(auth.step, AuthStep.reset);
      expect(service.pending, isNull);
      await auth.resetPassword('', password, password);
      expect(api.lastBody?['token'], token);
    });

    test('cancel keeps the session and drops the link', () async {
      await signIn();
      confirm = () async {
        events.add('confirm');
        return false;
      };
      service.handle(reset(token));
      await handler.process();
      expect(events, ['confirm']);
      expect(auth.stage, AuthStage.unlocked);
      expect(auth.step, isNot(AuthStep.reset));
      expect(service.pending, isNull);
      await handler.process();
      expect(events, ['confirm']);
    });

    test('also asks in the first-run setup stage', () async {
      await auth.initialize();
      await auth.register(
        'new@example.com',
        password,
        password,
        termsAccepted: true,
      );
      expect(auth.stage, AuthStage.setup);
      service.handle(reset(token));
      await handler.process();
      expect(events, ['confirm']);
      expect(auth.stage, AuthStage.signedOut);
      expect(auth.step, AuthStep.reset);
    });

    test('also asks when the app is locked', () async {
      await signIn();
      await auth.setupPin('123456', '123456', false, 'unlock');
      auth.lock();
      expect(auth.stage, AuthStage.locked);
      service.handle(reset(token));
      await handler.process();
      expect(events, ['confirm']);
      expect(auth.stage, AuthStage.signedOut);
      expect(auth.step, AuthStep.reset);
    });

    test(
      'tells the person when sign-out failed and keeps the session',
      () async {
        await signIn();
        api.failure = const AuthFailure(AuthError.network);
        service.handle(reset(token));
        await handler.process();
        expect(events, ['confirm', 'signOutFailed']);
        expect(auth.stage, AuthStage.unlocked);
        expect(auth.step, isNot(AuthStep.reset));
        expect(service.pending, isNull);
      },
    );

    test(
      'skips sign-out when the session already ended behind the dialog',
      () async {
        await signIn();
        confirm = () async {
          events.add('confirm');
          auth.sessionExpired();
          return true;
        };
        final callsBefore = api.calls;
        service.handle(reset(token));
        await handler.process();
        expect(auth.stage, AuthStage.signedOut);
        expect(auth.step, AuthStep.reset);
        expect(api.calls, callsBefore);
      },
    );

    test(
      'a link that replaces the one in the dialog gets its own question',
      () async {
        await signIn();
        final answers = <Completer<bool>>[];
        confirm = () {
          events.add('confirm');
          final answer = Completer<bool>();
          answers.add(answer);
          return answer.future;
        };
        service.handle(reset(token));
        final first = handler.process();
        await pumpEventQueue();
        expect(answers, hasLength(1));
        service.handle(reset(other));
        answers.first.complete(true);
        await pumpEventQueue();
        // The yes was for the old link: nothing was signed out for it.
        expect(auth.stage, AuthStage.unlocked);
        expect(answers, hasLength(2));
        answers.last.complete(true);
        await first;
        await pumpEventQueue();
        expect(auth.stage, AuthStage.signedOut);
        expect(auth.step, AuthStep.reset);
        await auth.resetPassword('', password, password);
        expect(api.lastBody?['token'], other);
      },
    );

    test(
      'a second call during the dialog does not open another dialog',
      () async {
        await signIn();
        final answer = Completer<bool>();
        confirm = () {
          events.add('confirm');
          return answer.future;
        };
        service.handle(reset(token));
        final first = handler.process();
        await handler.process();
        await handler.process();
        expect(events, ['confirm']);
        answer.complete(false);
        await first;
      },
    );
  });

  group('invalid links', () {
    test('show a notice once, in any state', () async {
      await signIn();
      service.handle(Uri.parse('freeva://reset-password?token=abc'));
      await handler.process();
      expect(events, ['invalid']);
      expect(service.pending, isNull);
      await handler.process();
      expect(events, ['invalid']);
      expect(auth.stage, AuthStage.unlocked);
    });
  });
}
