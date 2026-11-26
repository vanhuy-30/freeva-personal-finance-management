import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../support/server_config_fixture.dart';

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
import 'package:mobile/features/settings/presentation/pages/money_settings_page.dart';
import 'package:mobile/features/settings/presentation/pages/settings_page.dart';

import 'package:mobile/features/profile/domain/avatar_picker.dart';

import '../profile/avatar_fakes.dart';
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
    registerTestServerConfig();
  });

  group('Cá nhân', () {
    testWidgets('shows the profile card and the values of each setting', (
      tester,
    ) async {
      tall(tester);
      await tester.pumpWidget(g.app(const SettingsPage()));
      await tester.pumpAndSettle();
      expect(find.text('Minh'), findsOneWidget);
      expect(find.text('minh@gmail.com'), findsOneWidget);
      expect(find.text('TÀI SẢN'), findsOneWidget);
      expect(find.text('KẾ HOẠCH'), findsOneWidget);
      expect(find.text('THIẾT LẬP'), findsOneWidget);
      expect(find.text('DỮ LIỆU VÀ HỖ TRỢ'), findsOneWidget);
      expect(find.text('Tài sản ròng'), findsOneWidget);
      expect(find.text('VND · ngày 1'), findsOneWidget);
      expect(find.text('Sáng'), findsOneWidget);
      expect(find.text('Tiếng Việt'), findsOneWidget);
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
      await tester.pumpWidget(g.app(const MoneySettingsPage()));
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
      await tester.pumpWidget(g.app(const MoneySettingsPage()));
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
      expect(find.text('ASSETS'), findsOneWidget);
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

    testWidgets('has no time zone or hide balances row', (tester) async {
      tall(tester);
      await tester.pumpWidget(g.app(const SettingsPage()));
      await tester.pumpAndSettle();
      expect(find.text('Múi giờ'), findsNothing);
      expect(find.text('Ẩn số dư'), findsNothing);
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

    testWidgets('the camera button picks a photo, shows it and can remove it', (
      tester,
    ) async {
      tall(tester);
      g.avatarPicker.next = samplePicture();
      await tester.pumpWidget(g.app(const ProfilePage()));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNothing);
      await tester.tap(find.byIcon(LucideIcons.camera));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chọn ảnh từ thư viện'));
      await tester.pumpAndSettle();
      expect(g.avatarPicker.calls, 1);
      expect(g.avatarPicker.lastSource, AvatarSource.library);
      expect(g.avatarRepository.saved, hasLength(1));
      expect(g.avatar.image, isNotNull);
      expect(find.text('Đã cập nhật ảnh đại diện'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.tap(find.byIcon(LucideIcons.camera));
      await tester.pumpAndSettle();
      expect(find.text('Chụp ảnh mới'), findsOneWidget);
      expect(find.text('Chọn ảnh từ thư viện'), findsOneWidget);
      await tester.tap(find.text('Xóa ảnh đại diện'));
      await tester.pumpAndSettle();
      expect(g.avatar.image, isNull);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('SEC-P6-002: delete asks for the password again', (
      tester,
    ) async {
      tall(tester);
      await tester.pumpWidget(g.app(const ProfilePage()));
      await tester.pumpAndSettle();
      Future<void> deleteWith(String password) async {
        await tester.ensureVisible(find.text('Xoá tài khoản'));
        await tester.tap(find.text('Xoá tài khoản'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Xóa vĩnh viễn'));
        await tester.pumpAndSettle();
        expect(find.text('Nhập mật khẩu để tiếp tục'), findsOneWidget);
        await tester.enterText(
          find.descendant(
            of: find.byType(Dialog),
            matching: find.byType(TextField),
          ),
          password,
        );
        await tester.tap(find.text('Xong'));
        await tester.pumpAndSettle();
      }

      g.api.failure = const AuthFailure(AuthError.credentials);
      await deleteWith('sai-mat-khau-1');
      expect(find.text('Mật khẩu hiện tại chưa đúng.'), findsOneWidget);
      expect(g.api.lastPath, 'account');
      expect(g.api.lastBody, {'password': 'sai-mat-khau-1'});
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
      expect(find.textContaining('Dùng từ 8 ký tự'), findsOneWidget);
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
          'lastUsedAt': DateTime.now()
              .subtract(const Duration(days: 2, hours: 1))
              .toIso8601String(),
          'deviceName': 'Pixel 8',
          'platform': 'android',
          'osVersion': '15',
        },
      ];
    }

    testWidgets('one row per device: this one with a chip, others Đăng xuất', (
      tester,
    ) async {
      tall(tester);
      twoSessions();
      await tester.pumpWidget(g.app(const SessionsPage()));
      await tester.pumpAndSettle();
      // This session predates device details: it is still "Máy này".
      expect(find.text('Máy này'), findsOneWidget);
      expect(find.text('Đang dùng'), findsOneWidget);
      expect(find.text('Đăng nhập 02/10'), findsOneWidget);
      expect(find.text('Pixel 8'), findsOneWidget);
      expect(find.text('Android 15 · 2 ngày trước'), findsOneWidget);
      expect(find.text('Đăng xuất'), findsOneWidget);
    });

    testWidgets('Đăng xuất asks first, then drops that device', (tester) async {
      tall(tester);
      twoSessions();
      await tester.pumpWidget(g.app(const SessionsPage()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      expect(find.text('Đăng xuất thiết bị này?'), findsOneWidget);
      await tester.tap(find.text('Đăng xuất').last);
      await tester.pumpAndSettle();
      expect(g.api.lastPath, 'sessions/phone');
      expect(find.text('Pixel 8'), findsNothing);
    });

    testWidgets(
      '"Đăng xuất khỏi mọi thiết bị" revokes the others and reloads',
      (tester) async {
        tall(tester);
        twoSessions();
        await tester.pumpWidget(g.app(const SessionsPage()));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Đăng xuất khỏi mọi thiết bị'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Đăng xuất khỏi mọi thiết bị').last);
        await tester.pumpAndSettle();
        expect(g.auth.stage, AuthStage.unlocked);
        expect(g.api.calls, greaterThan(0));
      },
    );
  });
}
