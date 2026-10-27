import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/widgets/freeva_switch.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/profile/presentation/pages/profile_page.dart';
import 'package:mobile/features/settings/domain/app_preferences.dart';
import 'package:mobile/features/settings/presentation/pages/change_password_page.dart';
import 'package:mobile/features/settings/presentation/pages/change_pin_page.dart';
import 'package:mobile/features/settings/presentation/pages/security_page.dart';
import 'package:mobile/features/settings/presentation/pages/sessions_page.dart';
import 'package:mobile/features/settings/presentation/pages/settings_page.dart';

import 'g1_harness.dart';

/// PIN hashing runs in a real isolate, which the fake clock of a widget test
/// never waits for.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void tall(WidgetTester tester, {Size size = const Size(390, 1300)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  late G1 g;

  setUp(() async => g = await G1.create());
  tearDown(() async {
    g.dispose();
    await getIt.reset();
  });

  group('Cá nhân', () {
    testWidgets('shows the profile card and the values of each setting', (
      tester,
    ) async {
      tall(tester);
      await tester.pumpWidget(g.app(const SettingsPage()));
      await tester.pumpAndSettle();
      expect(find.text('Minh'), findsOneWidget);
      expect(find.text('m•••@gmail.com'), findsOneWidget);
      expect(find.text('THIẾT LẬP TÀI CHÍNH'), findsOneWidget);
      expect(find.text('VND'), findsOneWidget);
      expect(find.text('Ngày 1'), findsOneWidget);
      expect(find.text('Sáng'), findsOneWidget);
      expect(find.text('Tiếng Việt'), findsOneWidget);
      expect(find.text('GMT+7'), findsOneWidget);
      expect(find.text('PIN · Sinh trắc'), findsOneWidget);
      expect(find.text('1 đang bật'), findsOneWidget);
      expect(find.text('Định dạng ngày'), findsNothing);
      await tester.drag(find.byType(ListView), const Offset(0, -1200));
      await tester.pumpAndSettle();
      expect(find.text('Điều khoản và quyền riêng tư'), findsOneWidget);
      expect(find.text('Phiên bản 0.0.1'), findsOneWidget);
    });

    testWidgets('picking a currency or a day saves at once', (tester) async {
      tall(tester);
      await tester.pumpWidget(g.app(const SettingsPage()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiền tệ mặc định'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('USD'));
      await tester.pumpAndSettle();
      expect(g.profile.saved?.currency, 'USD');
      await tester.tap(find.text('Tháng tính từ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ngày 15'));
      await tester.pumpAndSettle();
      expect(g.profile.saved?.fiscalDay, 15);
      expect(g.profiles.saves, 2);
    });

    testWidgets('a failed save puts the old value back and says so', (
      tester,
    ) async {
      tall(tester);
      await tester.pumpWidget(g.app(const SettingsPage()));
      await tester.pumpAndSettle();
      g.profiles.failure = const AuthFailure(AuthError.network);
      await tester.tap(find.text('Tiền tệ mặc định'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('USD'));
      await tester.pumpAndSettle();
      expect(g.profile.saved?.currency, 'VND');
      expect(find.text('Chưa lưu được. Thử lại nhé.'), findsOneWidget);
    });

    testWidgets('language switches the app at once', (tester) async {
      tall(tester);
      await tester.pumpWidget(g.app(const SettingsPage()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ngôn ngữ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếng Anh'));
      await tester.pumpAndSettle();
      expect(find.text('Money setup'.toUpperCase()), findsOneWidget);
    });

    testWidgets('appearance sheet applies the theme when a card is tapped', (
      tester,
    ) async {
      tall(tester);
      await tester.pumpWidget(g.app(const SettingsPage()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Giao diện'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tối'));
      await tester.pumpAndSettle();
      expect(g.settings.theme, AppThemePreference.dark);
    });

    testWidgets('hide balances is a switch that takes effect at once', (
      tester,
    ) async {
      tall(tester);
      await tester.pumpWidget(g.app(const SettingsPage()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ẩn số dư'));
      await tester.pumpAndSettle();
      expect(g.settings.balancesHidden, isTrue);
    });

    testWidgets('settings without a screen yet say "Sắp có"', (tester) async {
      tall(tester);
      await tester.pumpWidget(g.app(const SettingsPage()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ngân sách tháng'));
      await tester.pump();
      expect(find.text('Sắp có'), findsOneWidget);
    });

    testWidgets('log out asks first and keeps the session on Huỷ', (
      tester,
    ) async {
      tall(tester, size: const Size(390, 2200));
      await tester.pumpWidget(g.app(const SettingsPage()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      expect(find.text('Đăng xuất khỏi máy này?'), findsOneWidget);
      await tester.tap(find.text('Huỷ'));
      await tester.pumpAndSettle();
      expect(g.auth.stage, AuthStage.unlocked);
      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đăng xuất').last);
      await tester.pumpAndSettle();
      expect(g.auth.stage, AuthStage.signedOut);
    });

    testWidgets('fits 320 pt at 1.3× and 2× text', (tester) async {
      tall(tester, size: const Size(320, 700));
      for (final scale in [1.3, 2.0]) {
        await tester.pumpWidget(g.app(const SettingsPage(), scale: scale));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(ListView), const Offset(0, -2500));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('Hồ sơ', () {
    testWidgets('saving is off until the name changes, then stores it', (
      tester,
    ) async {
      tall(tester);
      await tester.pumpWidget(g.app(const ProfilePage()));
      await tester.pumpAndSettle();
      final save = find.widgetWithText(InkWell, 'Lưu thay đổi');
      expect(tester.widget<InkWell>(save.first).onTap, isNull);
      await tester.enterText(find.byType(TextField), 'Lan');
      await tester.pump();
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();
      expect(g.profile.saved?.displayName, 'Lan');
    });

    testWidgets('a blank name clears it; the email change says "Sắp có"', (
      tester,
    ) async {
      tall(tester);
      await tester.pumpWidget(g.app(const ProfilePage()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đổi'));
      await tester.pump();
      expect(find.text('Sắp có'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();
      expect(g.profile.saved?.displayName, isNull);
    });
  });

  group('Bảo mật', () {
    testWidgets('lists unlock and sign-in settings; biometrics toggle', (
      tester,
    ) async {
      tall(tester);
      await tester.pumpWidget(g.app(const SecurityPage()));
      await tester.pumpAndSettle();
      expect(find.text('Khoá bằng mã PIN'), findsOneWidget);
      expect(find.byType(FreevaSwitch), findsNWidgets(2));
      expect(find.text('Đổi mã PIN'), findsOneWidget);
      await tester.tap(find.text('Mở bằng sinh trắc'));
      await tester.pumpAndSettle();
      expect(g.settings.biometricEnabled, isFalse);
    });

    testWidgets('change PIN: mismatch and "same as before" read clearly', (
      tester,
    ) async {
      tall(tester);
      await tester.pumpWidget(g.app(const ChangePinPage()));
      await tester.pumpAndSettle();
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '123456');
      await tester.enterText(fields.at(1), '654321');
      await tester.enterText(fields.at(2), '654322');
      await tester.tap(find.text('Lưu thay đổi'));
      await settle(tester);
      expect(find.text('Hai mã PIN mới chưa khớp.'), findsOneWidget);
      await tester.enterText(fields.at(1), '123456');
      await tester.enterText(fields.at(2), '123456');
      await tester.tap(find.text('Lưu thay đổi'));
      await settle(tester);
      expect(find.text('Chọn mã PIN khác mã cũ nhé.'), findsOneWidget);
    });

    testWidgets('change password: weak, wrong current, then success', (
      tester,
    ) async {
      tall(tester);
      await tester.pumpWidget(g.app(const ChangePasswordPage()));
      await tester.pumpAndSettle();
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'current password 1');
      await tester.enterText(fields.at(1), 'no digits in this one');
      await tester.enterText(fields.at(2), 'no digits in this one');
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Dùng từ 12 ký tự'), findsOneWidget);
      await tester.enterText(fields.at(1), 'brand new password 7');
      await tester.enterText(fields.at(2), 'brand new password 7');
      g.api.failure = const AuthFailure(AuthError.credentials);
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();
      expect(find.text('Mật khẩu hiện tại chưa đúng.'), findsOneWidget);
      g.api.failure = null;
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();
      expect(g.api.lastPath, 'auth/change-password');
      expect(g.api.lastBody?['newPassword'], 'brand new password 7');
    });
  });

  group('Phiên đăng nhập', () {
    void twoSessions() {
      final now = DateTime(2026, 10, 2).toIso8601String();
      g.api.sessionItems = [
        {
          'id': 'current',
          'createdAt': now,
          'expiresAt': DateTime(2026, 11, 1).toIso8601String(),
          'current': true,
        },
        {
          'id': 'phone',
          'createdAt': DateTime(2026, 10, 18).toIso8601String(),
          'expiresAt': DateTime(2026, 11, 17).toIso8601String(),
          'current': false,
        },
      ];
    }

    testWidgets('this device first with a chip, others with Thu hồi', (
      tester,
    ) async {
      tall(tester);
      twoSessions();
      await tester.pumpWidget(g.app(const SessionsPage()));
      await tester.pumpAndSettle();
      expect(find.text('Máy này'), findsOneWidget);
      expect(find.text('Đang dùng'), findsOneWidget);
      expect(find.text('Từ 02/10 · hết hạn 01/11'), findsOneWidget);
      expect(find.text('Phiên khác'), findsOneWidget);
      expect(find.text('Thu hồi'), findsOneWidget);
    });

    testWidgets('Thu hồi asks first, then drops that device', (tester) async {
      tall(tester);
      twoSessions();
      await tester.pumpWidget(g.app(const SessionsPage()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thu hồi'));
      await tester.pumpAndSettle();
      expect(find.text('Thu hồi phiên này?'), findsOneWidget);
      await tester.tap(find.text('Thu hồi').last);
      await tester.pumpAndSettle();
      expect(g.api.lastPath, 'sessions/phone');
      expect(find.text('Phiên khác'), findsNothing);
    });

    testWidgets('"Đăng xuất mọi máy khác" revokes the others and reloads', (
      tester,
    ) async {
      tall(tester);
      twoSessions();
      await tester.pumpWidget(g.app(const SessionsPage()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đăng xuất mọi máy khác'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đăng xuất mọi máy khác').last);
      await tester.pumpAndSettle();
      expect(g.auth.stage, AuthStage.unlocked);
      expect(g.api.calls, greaterThan(0));
    });
  });
}
