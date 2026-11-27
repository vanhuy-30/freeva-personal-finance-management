import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/profile/domain/profile.dart';
import 'package:mobile/features/profile/presentation/pages/profile_page.dart';

import 'g1_harness.dart';

void tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 1300);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<G1> open(WidgetTester tester, {bool? verified}) async {
  tall(tester);
  final g = await tester.runAsync(() => G1.create(emailVerified: verified));
  await tester.pumpWidget(g!.app(const ProfilePage()));
  await tester.pumpAndSettle();
  return g;
}

void main() {
  testWidgets('a confirmed email says so and shows no banner', (tester) async {
    await open(tester, verified: true);
    expect(find.text('Email · đã xác nhận'), findsOneWidget);
    expect(find.text('Gửi link xác nhận'), findsNothing);
  });

  testWidgets('an unknown state keeps the plain label and no banner', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Gửi link xác nhận'), findsNothing);
  });

  testWidgets('unconfirmed: sends to the device email, then waits a minute', (
    tester,
  ) async {
    final g = await open(tester, verified: false);
    expect(find.text('Email · chưa xác nhận'), findsOneWidget);
    expect(find.text('Cần để lấy lại mật khẩu khi bạn quên.'), findsOneWidget);
    await tester.tap(find.text('Gửi link xác nhận'));
    await tester.pump();
    await tester.pump();
    expect(g.api.lastPath, 'auth/email-verifications');
    expect(g.api.lastBody, {'email': 'minh@gmail.com'});
    expect(
      find.text('Đã gửi link. Kiểm tra email rồi quay lại đây.'),
      findsOneWidget,
    );
    expect(find.text('Gửi link xác nhận'), findsNothing);
    // The message is not left behind for the sign-in screen.
    expect(g.auth.notice, isNull);
    await tester.pump(const Duration(seconds: 61));
    expect(find.text('Gửi link xác nhận'), findsOneWidget);
  });

  testWidgets('a server limit shows the wait and hides the button', (
    tester,
  ) async {
    final g = await open(tester, verified: false);
    g.api.failure = const AuthFailure(AuthError.rateLimited, retryAfter: 600);
    await tester.tap(find.text('Gửi link xác nhận'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Thử lại sau 10 phút nhé.'), findsOneWidget);
    expect(find.text('Gửi link xác nhận'), findsNothing);
    await tester.pump(const Duration(seconds: 601));
  });

  testWidgets('offline: says so and lets the person try again', (tester) async {
    final g = await open(tester, verified: false);
    g.api.failure = const AuthFailure(AuthError.network);
    await tester.tap(find.text('Gửi link xác nhận'));
    await tester.pump();
    await tester.pump();
    expect(
      find.text('Chưa gửi được. Kiểm tra mạng rồi thử lại.'),
      findsOneWidget,
    );
    expect(find.text('Gửi link xác nhận'), findsOneWidget);
  });

  testWidgets('back from the browser: the row follows the server', (
    tester,
  ) async {
    final g = await open(tester, verified: false);
    expect(find.text('Email · chưa xác nhận'), findsOneWidget);
    // Confirmed in the browser meanwhile.
    g.profiles.value = const Profile(
      locale: 'vi',
      currency: 'VND',
      timezone: 'Asia/Ho_Chi_Minh',
      fiscalDay: 1,
      version: 1,
      displayName: 'Minh',
      emailVerified: true,
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Email · đã xác nhận'), findsOneWidget);
    expect(find.text('Gửi link xác nhận'), findsNothing);
  });

  testWidgets('no refresh on resume once the email is confirmed', (
    tester,
  ) async {
    final g = await open(tester, verified: true);
    final loads = g.profiles.loads;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(g.profiles.loads, loads);
  });
}
