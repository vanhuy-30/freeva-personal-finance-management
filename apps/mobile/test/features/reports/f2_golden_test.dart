import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/reports/domain/report_range.dart';
import 'package:mobile/features/reports/presentation/pages/report_category_page.dart';
import 'package:mobile/features/reports/presentation/widgets/range_picker_dialog.dart';

import '../../core/widgets/widget_test_app.dart' show loadTestFonts;
import '../auth/fakes.dart';
import '../transactions/c1_stub.dart' show StubTransactionViewModel;
import 'f2_stub.dart';

// macOS only (see core_widgets_golden_test.dart).
// Update: flutter test --update-goldens test/features/reports/f2_golden_test.dart
void main() {
  setUpAll(loadTestFonts);
  tearDown(() => getIt.reset());

  Future<Widget> app(
    Widget Function() page, {
    bool dark = false,
    double scale = 1,
  }) async {
    await getIt.reset();
    getIt.registerSingleton<AuthViewModel>(
      DefaultAuthViewModel(
          DefaultAuthUseCases(
            AuthRepositoryImpl(FakeApi(), MemoryVault(), FakeBiometrics()),
          ),
        )
        ..stage = AuthStage.unlocked
        ..hasPin = true
        ..ready = true,
    );
    await registerF2(FakeTransactionRepository(), StubTransactionViewModel());
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: dark ? AppTheme.dark : AppTheme.light,
      locale: const Locale('vi'),
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: scale,
        maxScaleFactor: scale,
        child: child!,
      ),
      routerConfig: GoRouter(
        routes: [GoRoute(path: '/', builder: (_, __) => page())],
      ),
    );
  }

  Future<void> shot(
    WidgetTester tester,
    Widget widget,
    String name, {
    Size size = const Size(390, 844),
    Future<void> Function()? then,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(widget);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    if (then != null) await then();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/f2_$name.png'),
    );
  }

  testWidgets('category', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      await app(() => ReportCategoryPage(args: f2Args())),
      'category',
    );
  });
  testWidgets('category dark', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      await app(() => ReportCategoryPage(args: f2Args()), dark: true),
      'category_dark',
    );
  });
  testWidgets('category compact', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      await app(() => ReportCategoryPage(args: f2Args()), scale: 1.3),
      'category_compact',
      size: const Size(320, 1100),
    );
  });
  testWidgets('other', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      await app(() => ReportCategoryPage(args: f2Args(index: 3))),
      'other',
    );
  });

  Widget opener({RangeSelection initial = const RangeSelection()}) => Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () =>
              showRangePicker(context, today: '2026-10-21', initial: initial),
          child: const Text('mở'),
        ),
      ),
    ),
  );

  Future<void> openDialog(WidgetTester tester) async {
    await tester.tap(find.text('mở'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('range picked', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      await app(
        () => opener(
          initial: const RangeSelection(from: '2026-10-06', to: '2026-10-19'),
        ),
      ),
      'range',
      then: () => openDialog(tester),
    );
  });
  testWidgets('range picked dark', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      await app(
        () => opener(
          initial: const RangeSelection(from: '2026-10-06', to: '2026-10-19'),
        ),
        dark: true,
      ),
      'range_dark',
      then: () => openDialog(tester),
    );
  });
  testWidgets('range start only', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      await app(() => opener()),
      'range_start',
      then: () async {
        await openDialog(tester);
        await tester.tap(find.text('6'));
        await tester.pump(const Duration(milliseconds: 300));
      },
    );
  });
  testWidgets('range compact', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      await app(
        () => opener(
          initial: const RangeSelection(from: '2026-10-06', to: '2026-10-19'),
        ),
        scale: 1.3,
      ),
      'range_compact',
      size: const Size(320, 700),
      then: () => openDialog(tester),
    );
  });
}
