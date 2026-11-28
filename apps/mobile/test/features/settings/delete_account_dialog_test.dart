import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/widgets/freeva_button.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/presentation/pages/auth_page.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/profile/presentation/pages/profile_page.dart';

import 'g1_harness.dart';

void tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 1300);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  late G1 g;
  setUp(() async {
    g = await G1.create();
  });
  tearDown(() => g.dispose());

  Future<void> openDialog(WidgetTester tester) async {
    tall(tester);
    await tester.pumpWidget(
      g.app(
        const ProfilePage(),
        routes: [
          GoRoute(
            path: '/me/export',
            builder: (_, __) => const Scaffold(body: Text('màn xuất dữ liệu')),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Xoá tài khoản'));
    await tester.tap(find.text('Xoá tài khoản'));
    await tester.pumpAndSettle();
  }

  Finder field() => find.descendant(
    of: find.byType(Dialog),
    matching: find.byType(TextField),
  );

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(field(), text);
    await tester.pump();
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.text('Xóa vĩnh viễn'));
    await tester.pumpAndSettle();
  }

  /// The red button; its label is replaced by a spinner while it runs.
  VoidCallback? confirmAction(WidgetTester tester) => tester
      .widget<FreevaButton>(
        find.byWidgetPredicate(
          (w) =>
              w is FreevaButton && w.variant == FreevaButtonVariant.destructive,
        ),
      )
      .onPressed;

  testWidgets('one popup: warning, export first, password, two buttons', (
    tester,
  ) async {
    await openDialog(tester);
    expect(find.text('Xóa tài khoản?'), findsOneWidget);
    expect(
      find.text('Mọi dữ liệu của bạn sẽ bị xóa ngay và không khôi phục được.'),
      findsOneWidget,
    );
    expect(find.text('Xuất dữ liệu trước'), findsOneWidget);
    expect(find.text('Huỷ'), findsOneWidget);
    expect(find.text('Xóa vĩnh viễn'), findsOneWidget);
    expect(field(), findsOneWidget);
    // Nothing is sent until a password is typed.
    expect(confirmAction(tester), isNull);
    await type(tester, 'x');
    expect(confirmAction(tester), isNotNull);
    await type(tester, '');
    expect(confirmAction(tester), isNull);
    expect(g.api.lastPath, isNot('account'));
  });

  testWidgets('a wrong password shows under the field and keeps the popup', (
    tester,
  ) async {
    await openDialog(tester);
    g.api.failure = const AuthFailure(AuthError.credentials);
    await type(tester, 'sai-mat-khau-1');
    await confirm(tester);
    expect(find.text('Mật khẩu hiện tại chưa đúng.'), findsOneWidget);
    expect(find.text('Xóa tài khoản?'), findsOneWidget);
    expect(g.api.lastPath, 'account');
    expect(g.api.lastBody, {'password': 'sai-mat-khau-1'});
    expect(g.auth.stage, AuthStage.unlocked);
    // Typing again clears the message and allows another try.
    await type(tester, 'sai-mat-khau-12');
    expect(find.text('Mật khẩu hiện tại chưa đúng.'), findsNothing);
    expect(confirmAction(tester), isNotNull);
  });

  testWidgets('a server limit says how long to wait', (tester) async {
    await openDialog(tester);
    g.api.failure = const AuthFailure(AuthError.rateLimited, retryAfter: 600);
    await type(tester, 'abc');
    await confirm(tester);
    expect(find.text('Thử lại sau 10 phút nhé.'), findsOneWidget);
    expect(find.text('Xóa tài khoản?'), findsOneWidget);
  });

  testWidgets('offline says the data is untouched and lets the person retry', (
    tester,
  ) async {
    await openDialog(tester);
    g.api.failure = const AuthFailure(AuthError.network);
    await type(tester, 'abc');
    await confirm(tester);
    expect(
      find.text('Chưa xóa được. Dữ liệu của bạn vẫn còn nguyên.'),
      findsOneWidget,
    );
    expect(g.auth.stage, AuthStage.unlocked);
    g.api.failure = null;
    await confirm(tester);
    expect(g.auth.stage, AuthStage.signedOut);
  });

  testWidgets('while it runs nothing can close the popup or be pressed again', (
    tester,
  ) async {
    await openDialog(tester);
    final gate = Completer<void>();
    g.api.pending = gate.future;
    await type(tester, 'abc');
    await tester.tap(find.text('Xóa vĩnh viễn'));
    await tester.pump();
    final callsBefore = g.api.calls;
    expect(confirmAction(tester), isNull);
    await tester.tap(find.text('Huỷ'), warnIfMissed: false);
    await tester.pump();
    await tester.tap(find.text('Xuất dữ liệu trước'), warnIfMissed: false);
    await tester.pump();
    expect(find.text('Xóa tài khoản?'), findsOneWidget);
    expect(find.text('màn xuất dữ liệu'), findsNothing);
    expect(g.api.calls, callsBefore);
    gate.complete();
    await tester.pumpAndSettle();
    expect(g.auth.stage, AuthStage.signedOut);
  });

  testWidgets('success: the account is gone and the login says so', (
    tester,
  ) async {
    await openDialog(tester);
    await type(tester, 'password long enough');
    await confirm(tester);
    expect(g.api.lastPath, 'account');
    expect(g.auth.stage, AuthStage.signedOut);
    expect(g.auth.notice, AuthNotice.accountDeleted);
    expect(find.text('Xóa tài khoản?'), findsNothing);
    await tester.pumpWidget(g.app(AuthPage(model: g.auth)));
    await tester.pumpAndSettle();
    expect(find.text('Đã xóa tài khoản.'), findsOneWidget);
  });

  testWidgets(
    'an expired session leaves the popup and says so, not "deleted"',
    (tester) async {
      await openDialog(tester);
      g.api.failure = const AuthFailure(AuthError.expired);
      await type(tester, 'abc');
      await confirm(tester);
      expect(find.text('Xóa tài khoản?'), findsNothing);
      expect(g.auth.stage, AuthStage.signedOut);
      expect(g.auth.notice, isNot(AuthNotice.accountDeleted));
      expect(g.auth.failure?.code, AuthError.expired);
    },
  );

  testWidgets('"Xuất dữ liệu trước" closes the popup and opens the export', (
    tester,
  ) async {
    await openDialog(tester);
    await type(tester, 'abc');
    await tester.tap(find.text('Xuất dữ liệu trước'));
    await tester.pumpAndSettle();
    expect(find.text('màn xuất dữ liệu'), findsOneWidget);
    expect(g.api.lastPath, isNot('account'));
    expect(g.auth.stage, AuthStage.unlocked);
  });

  testWidgets('cancel changes nothing', (tester) async {
    await openDialog(tester);
    await type(tester, 'abc');
    await tester.tap(find.text('Huỷ'));
    await tester.pumpAndSettle();
    expect(find.text('Xóa tài khoản?'), findsNothing);
    expect(g.api.lastPath, isNot('account'));
    expect(g.auth.stage, AuthStage.unlocked);
  });

  testWidgets('fits a small screen at large text in both languages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final dark in [false, true]) {
      await tester.pumpWidget(
        g.app(const ProfilePage(), dark: dark, scale: 1.3),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Xoá tài khoản'));
      await tester.tap(find.text('Xoá tài khoản'));
      await tester.pumpAndSettle();
      g.api.failure = const AuthFailure(AuthError.credentials);
      await tester.enterText(field(), 'abc');
      await tester.pump();
      await tester.tap(find.text('Xóa vĩnh viễn'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'dark=$dark');
      expect(find.text('Mật khẩu hiện tại chưa đúng.'), findsOneWidget);
      await tester.tap(find.text('Huỷ'));
      await tester.pumpAndSettle();
    }
  });
}
