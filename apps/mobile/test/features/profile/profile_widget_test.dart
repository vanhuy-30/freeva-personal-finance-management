import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/auth/presentation/widgets/auth_gate.dart';
import 'package:mobile/features/profile/domain/profile_use_cases.dart';
import 'package:mobile/features/profile/presentation/pages/profile_page.dart';
import 'package:mobile/features/profile/presentation/viewmodels/profile_view_model.dart';
import 'package:mobile/features/profile/presentation/widgets/profile_select.dart';

import '../auth/fakes.dart';
import 'fakes.dart';

void main() {
  late DefaultAuthViewModel auth;
  late DefaultProfileViewModel profile;
  setUp(() async {
    await getIt.reset();
    auth =
        DefaultAuthViewModel(
            DefaultAuthUseCases(
              AuthRepositoryImpl(FakeApi(), MemoryVault(), FakeBiometrics()),
            ),
          )
          ..ready = true
          ..stage = AuthStage.unlocked;
    profile = DefaultProfileViewModel(ProfileUseCases(MemoryProfiles()), auth);
    await profile.load();
    getIt.registerSingleton<AuthViewModel>(auth);
    getIt.registerSingleton<ProfileViewModel>(profile);
  });
  tearDown(() async {
    profile.dispose();
    auth.dispose();
    await getIt.reset();
  });
  Widget app({double scale = 1, Widget? child}) => ListenableBuilder(
    listenable: profile,
    builder: (context, _) => MaterialApp(
      locale: Locale(profile.locale),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: S.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: AuthGate(child: child ?? const ProfilePage()),
    ),
  );
  testWidgets('editing language applies across the app only after saving', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('Hồ sơ tài chính'), findsOneWidget);
    await tester.tap(find.text('Ngôn ngữ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếng Anh'));
    await tester.pumpAndSettle();
    expect(find.text('Hồ sơ tài chính'), findsOneWidget);
    await tester.ensureVisible(find.text('Lưu thay đổi'));
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    expect(find.text('Financial profile'), findsOneWidget);
    expect(find.text('Profile saved.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('both locales fit small screens with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(scale: 2));
    await tester.pumpAndSettle();
    for (final locale in ['vi', 'en']) {
      profile.edit(profile.draft!.copyWith(locale: locale));
      await profile.save();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets('timezone search and its choices disappear on lifecycle lock', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        child: Scaffold(
          body: ProfileSelect(
            label: 'Timezone',
            value: 'UTC',
            enabled: true,
            onChanged: (_) {},
            choices: {
              'UTC': 'UTC',
              for (var i = 0; i < 40; i++) 'Zone/$i': 'Zone/$i',
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Timezone'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Zone/39');
    await tester.pumpAndSettle();
    expect(find.text('Zone/39'), findsNWidgets(2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(find.text('Zone/39'), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Freeva đã khóa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
