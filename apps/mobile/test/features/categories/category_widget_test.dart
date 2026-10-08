import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/categories/data/category_repository_impl.dart';
import 'package:mobile/features/categories/domain/category_use_cases.dart';
import 'package:mobile/features/categories/presentation/viewmodels/category_view_model.dart';
import 'package:mobile/features/categories/presentation/widgets/category_editor.dart';
import 'package:mobile/features/categories/presentation/widgets/category_editor_form.dart';
import 'package:mobile/features/categories/presentation/widgets/category_list.dart';

import '../auth/fakes.dart';
import 'category_test.dart' show CategoryTransport;

void main() {
  late CategoryTransport api;
  late DefaultAuthViewModel auth;
  late DefaultCategoryViewModel model;
  setUp(() async {
    await getIt.reset();
    api = CategoryTransport();
    auth =
        DefaultAuthViewModel(
            DefaultAuthUseCases(
              AuthRepositoryImpl(FakeApi(), MemoryVault(), FakeBiometrics()),
            ),
          )
          ..stage = AuthStage.unlocked
          ..ready = true;
    getIt.registerSingleton<AuthViewModel>(auth);
    model = DefaultCategoryViewModel(
      DefaultCategoryUseCases(CategoryRepositoryImpl(api)),
      auth,
    );
    await model.load();
  });
  tearDown(() async {
    model.dispose();
    auth.dispose();
    await getIt.reset();
  });

  Widget app(Widget child, {String locale = 'vi', double scale = 1}) =>
      MaterialApp(
        theme: AppTheme.light,
        locale: Locale(locale),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Scaffold(body: child),
        ),
      );

  testWidgets('tree indents children and hidden filter omits active rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        ListenableBuilder(
          listenable: model,
          builder: (_, _) => CategoryList(model: model, archived: false),
        ),
      ),
    );
    final food = tester.widget<Card>(find.byKey(const ValueKey('food')));
    final coffee = tester.widget<Card>(find.byKey(const ValueKey('coffee')));
    expect(
      (coffee.margin! as EdgeInsets).left,
      greaterThan((food.margin! as EdgeInsets).left),
    );
    expect(find.text('Danh mục mặc định'), findsOneWidget);
    await tester.tap(find.text('Ẩn danh mục').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('danh mục con'), findsOneWidget);
    expect(api.writes, 0);
    await tester.pumpWidget(
      app(CategoryList(model: model, archived: true), locale: 'en'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Quà'), findsOneWidget);
    expect(find.text('Restore category'), findsOneWidget);
    expect(find.text('Ăn uống'), findsNothing);
  });

  testWidgets('locking closes the editor and discards the draft', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        ListenableBuilder(
          listenable: model,
          builder: (_, _) => CategoryList(model: model, archived: false),
        ),
      ),
    );
    await tester.tap(find.text('Sửa danh mục').first);
    await tester.pumpAndSettle();
    expect(find.byType(CategoryEditorForm), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Private draft');
    auth.lock();
    await tester.pumpAndSettle();
    expect(find.byType(CategoryEditor), findsNothing);
    expect(find.text('Private draft'), findsNothing);
    expect(model.categories, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editor keeps an invalid draft on a narrow large-text screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(CategoryEditorForm(model: model), scale: 2));
    await tester.enterText(find.byType(TextField).first, '   ');
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(api.writes, 0);
    expect(find.text('   '), findsOneWidget);
    expect(find.textContaining('1–100'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
