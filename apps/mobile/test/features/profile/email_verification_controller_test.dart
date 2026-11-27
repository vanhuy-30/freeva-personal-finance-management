import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/profile/presentation/viewmodels/email_verification_controller.dart';

void main() {
  late List<AuthFailure?> outcomes;
  late int calls;
  EmailVerificationController make() => EmailVerificationController(
    resend: () async {
      calls++;
      return outcomes.removeAt(0);
    },
  );
  setUp(() {
    outcomes = [];
    calls = 0;
  });

  test('a send goes sending → sent, blocks more sends, then frees after the cooldown', () {
    fakeAsync((async) {
      outcomes = [null, null];
      final c = make();
      final states = <EmailSendState>[];
      c.addListener(() => states.add(c.state));
      unawaited(c.send());
      async.flushMicrotasks();
      expect(states, [EmailSendState.sending, EmailSendState.sent]);
      expect(c.canSend, isFalse);
      unawaited(c.send());
      async.flushMicrotasks();
      expect(calls, 1);
      async.elapse(const Duration(seconds: 59));
      expect(c.canSend, isFalse);
      async.elapse(const Duration(seconds: 2));
      expect(c.state, EmailSendState.idle);
      unawaited(c.send());
      async.flushMicrotasks();
      expect(calls, 2);
      c.dispose();
    });
  });

  test('the server limit shows minutes and holds until it expires', () {
    fakeAsync((async) {
      outcomes = [const AuthFailure(AuthError.rateLimited, retryAfter: 601)];
      final c = make();
      unawaited(c.send());
      async.flushMicrotasks();
      expect(c.state, EmailSendState.limited);
      expect(c.retryMinutes, 11);
      expect(c.canSend, isFalse);
      async.elapse(const Duration(seconds: 600));
      expect(c.state, EmailSendState.limited);
      async.elapse(const Duration(seconds: 2));
      expect(c.state, EmailSendState.idle);
      expect(c.retryMinutes, isNull);
      c.dispose();
    });
  });

  test('a limit without Retry-After falls back to 15 minutes', () {
    fakeAsync((async) {
      outcomes = [const AuthFailure(AuthError.rateLimited)];
      final c = make();
      unawaited(c.send());
      async.flushMicrotasks();
      expect(c.retryMinutes, 15);
      c.dispose();
    });
  });

  test('other failures can be retried straight away', () {
    fakeAsync((async) {
      outcomes = [const AuthFailure(AuthError.network), null];
      final c = make();
      unawaited(c.send());
      async.flushMicrotasks();
      expect(c.state, EmailSendState.failed);
      expect(c.canSend, isTrue);
      unawaited(c.send());
      async.flushMicrotasks();
      expect(c.state, EmailSendState.sent);
      c.dispose();
    });
  });

  test(
    'a send that finishes after dispose does nothing and leaves no timer',
    () {
      fakeAsync((async) {
        final gate = Completer<AuthFailure?>();
        final c = EmailVerificationController(resend: () => gate.future);
        unawaited(c.send());
        async.flushMicrotasks();
        c.dispose();
        gate.complete(null);
        async.flushMicrotasks();
        expect(async.pendingTimers, isEmpty);
      });
    },
  );
}
