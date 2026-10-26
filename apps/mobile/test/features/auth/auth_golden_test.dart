import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/pages/auth_page.dart';
import 'package:mobile/features/auth/presentation/pages/lock_page.dart';
import 'package:mobile/features/auth/presentation/pages/setup_page.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';

import '../../core/widgets/widget_test_app.dart' show loadTestFonts;
import 'fakes.dart';
import 'setup_deps.dart';

// macOS only. Update: flutter test --update-goldens test/features/auth/auth_golden_test.dart
void main() {
  setUpAll(loadTestFonts);

  Future<void> shot(
    WidgetTester t,
    String name,
    Widget Function(DefaultAuthViewModel m) page, {
    bool dark = false,
    double scale = 1,
    Size size = const Size(390, 844),
    void Function(DefaultAuthViewModel m)? prepare,
    Future<void> Function()? then,
  }) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await getIt.reset();
    final deps = await registerSetupDeps();
    addTearDown(() async {
      deps.settings.dispose();
      await getIt.reset();
    });
    final model = DefaultAuthViewModel(
      DefaultAuthUseCases(
        AuthRepositoryImpl(FakeApi(), MemoryVault(), FakeBiometrics()),
      ),
    );
    addTearDown(model.dispose);
    prepare?.call(model);
    await t.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: dark ? AppTheme.dark : AppTheme.light,
        locale: const Locale('vi'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: ListenableBuilder(
          listenable: model,
          builder: (_, _) => page(model),
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 400));
    if (then != null) await then();
    await t.pump(const Duration(milliseconds: 400));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/a1_$name.png'),
    );
  }

  testWidgets('login', skip: !Platform.isMacOS, (t) async {
    await shot(t, 'login', (m) => AuthPage(model: m));
  });
  testWidgets('login dark', skip: !Platform.isMacOS, (t) async {
    await shot(t, 'login_dark', (m) => AuthPage(model: m), dark: true);
  });
  testWidgets('register', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      'register',
      (m) => AuthPage(model: m),
      size: const Size(390, 900),
      prepare: (m) => m.goTo(AuthStep.register),
      then: () async {
        await t.enterText(find.byType(TextField).at(0), 'lan@gmail.com');
        await t.enterText(find.byType(TextField).at(1), 'maytrangngay7');
        await t.enterText(find.byType(TextField).at(2), 'maytrangngay7');
        await t.tap(find.bySemanticsLabel('Đồng ý điều khoản'));
        await t.pump();
      },
    );
  });
  testWidgets('register compact', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      'register_compact',
      (m) => AuthPage(model: m),
      scale: 1.3,
      size: const Size(320, 1100),
      prepare: (m) => m.goTo(AuthStep.register),
    );
  });
  testWidgets('forgot', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      'forgot',
      (m) => AuthPage(model: m),
      prepare: (m) => m.goTo(AuthStep.forgot),
    );
  });
  testWidgets('new password', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      'reset',
      (m) => AuthPage(model: m),
      prepare: (m) => m.startReset('a' * 64),
    );
  });
  testWidgets('verify email', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      'verify',
      (m) => SetupPage(model: m),
      prepare: (m) => m
        ..stage = AuthStage.setup
        ..email = 'lan@gmail.com',
    );
  });
  testWidgets('pin', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      'pin',
      (m) => SetupPage(model: m),
      prepare: (m) => m.stage = AuthStage.setup,
      then: () async {
        await t.tap(find.text('Xong'));
        await t.pumpAndSettle();
        for (final skip in ['Để sau', 'Để sau', 'Thiết lập sau', 'Bỏ qua']) {
          await t.tap(find.text(skip));
          await t.pumpAndSettle();
        }
        for (final d in ['1', '2', '3', '4']) {
          await t.tap(find.bySemanticsLabel(d));
          await t.pump();
        }
      },
    );
  });
  testWidgets('lock', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      'lock',
      (m) => LockPage(model: m),
      prepare: (m) => m
        ..stage = AuthStage.locked
        ..name = 'Minh'
        ..biometricAvailable = true,
      then: () async {
        await t.tap(find.bySemanticsLabel('1'));
        await t.tap(find.bySemanticsLabel('2'));
        await t.pump();
      },
    );
  });

  testWidgets('welcome', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      'welcome',
      (m) => AuthPage(model: m),
      prepare: (m) => m.step = AuthStep.welcome,
    );
  });
  testWidgets('welcome dark compact', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      'welcome_compact',
      (m) => AuthPage(model: m),
      dark: true,
      scale: 1.3,
      size: const Size(320, 900),
      prepare: (m) => m.step = AuthStep.welcome,
    );
  });
  testWidgets('sign up choice', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      'sign_up',
      (m) => AuthPage(model: m),
      prepare: (m) => m.step = AuthStep.signUp,
    );
  });

  Future<void> toQuestions(WidgetTester t) async {
    await t.tap(find.text('Xong'));
    await t.pumpAndSettle();
  }

  testWidgets('goals', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      'goals',
      (m) => SetupPage(model: m),
      prepare: (m) => m.stage = AuthStage.setup,
      then: () async {
        await toQuestions(t);
        await t.tap(find.text('Theo dõi chi tiêu'));
        await t.tap(find.text('Tiết kiệm nhiều hơn'));
        await t.pump();
      },
    );
  });
  testWidgets('habits', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      'habits',
      (m) => SetupPage(model: m),
      size: const Size(390, 900),
      prepare: (m) => m.stage = AuthStage.setup,
      then: () async {
        await toQuestions(t);
        await t.tap(find.text('Để sau'));
        await t.pumpAndSettle();
        await t.tap(find.text('Dùng Excel hoặc Sheets'));
        await t.tap(find.text('Mỗi tuần'));
        await t.pump();
      },
    );
  });
  testWidgets('budget', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      'budget',
      (m) => SetupPage(model: m),
      prepare: (m) => m.stage = AuthStage.setup,
      then: () async {
        await toQuestions(t);
        await t.tap(find.text('Để sau'));
        await t.pumpAndSettle();
        await t.tap(find.text('Để sau'));
        await t.pumpAndSettle();
        await t.tap(find.text('10tr'));
        await t.pump();
      },
    );
  });

  Future<void> toWallets(WidgetTester t) async {
    await toQuestions(t);
    for (final skip in ['Để sau', 'Để sau', 'Thiết lập sau']) {
      await t.tap(find.text(skip));
      await t.pumpAndSettle();
    }
  }

  testWidgets('setup wallets', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      'wallets',
      (m) => SetupPage(model: m),
      prepare: (m) => m.stage = AuthStage.setup,
      then: () async {
        await toWallets(t);
        // Add cash through the real form.
        await t.tap(find.text('Thêm').first);
        await t.pumpAndSettle();
        await t.enterText(find.byType(TextField).at(0), 'Ví của tôi');
        await t.enterText(find.byType(TextField).at(1), '850000');
        await t.tap(find.text('Lưu ví'));
        await t.pumpAndSettle();
      },
    );
  });
  testWidgets('setup wallet form', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      'wallet_form',
      (m) => SetupPage(model: m),
      prepare: (m) => m.stage = AuthStage.setup,
      then: () async {
        await toWallets(t);
        await t.tap(find.text('Thêm').last);
        await t.pumpAndSettle();
      },
    );
  });
}
