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
import 'package:mobile/features/categories/presentation/pages/category_editor_page.dart';
import 'package:mobile/features/categories/domain/category_expansion_repository.dart';
import 'package:mobile/features/categories/presentation/pages/category_page.dart';
import 'package:mobile/features/categories/presentation/pages/hidden_categories_page.dart';

import '../auth/fakes.dart';
import 'category_test.dart' show CategoryTransport, categoryJson;

class _Expansion implements CategoryExpansionRepository {
  Set<String> stored = {};
  @override
  Future<Set<String>> read() async => stored;
  @override
  Future<void> write(Set<String> ids) async => stored = ids;
}

void main() {
  late CategoryTransport api;
  late _Expansion expansion;
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
    expansion = _Expansion();
    model = DefaultCategoryViewModel(
      DefaultCategoryUseCases(CategoryRepositoryImpl(api)),
      auth,
      expansion,
    );
    getIt.registerSingleton<CategoryViewModel>(model);
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

  testWidgets('list starts collapsed; the round button opens and is kept', (
    tester,
  ) async {
    await tester.pumpWidget(app(const CategoryPage()));
    await tester.pump();
    expect(find.text('Ăn uống'), findsOneWidget);
    expect(find.text('1 danh mục con'), findsOneWidget);
    expect(find.text('Cà phê'), findsNothing);
    expect(find.text('Quà'), findsNothing);
    await tester.tap(
      find.bySemanticsLabel('Ăn uống: mở hoặc thu danh mục con'),
    );
    await tester.pump();
    expect(find.text('Cà phê'), findsOneWidget);
    expect(expansion.stored, {'food'});
    expect(find.bySemanticsLabel('Danh mục đã ẩn, 1'), findsOneWidget);
  });

  testWidgets('Chi and Thu tabs follow kind; both shows in each', (
    tester,
  ) async {
    api.rows[0]['kind'] = 'expense';
    api.rows.add(categoryJson('salary', name: 'Lương')..['kind'] = 'income');
    api.rows.add(categoryJson('gifts', name: 'Quà tặng')..['kind'] = 'both');
    await model.load();
    await tester.pumpWidget(app(const CategoryPage()));
    await tester.pump();
    expect(find.text('Lương'), findsNothing);
    expect(find.text('Quà tặng'), findsOneWidget);
    await tester.tap(find.text('Thu'));
    await tester.pump();
    expect(find.text('Lương'), findsOneWidget);
    expect(find.text('Quà tặng'), findsOneWidget);
    expect(find.text('Ăn uống'), findsNothing);
  });

  testWidgets('hidden page restores a main category with a toast', (
    tester,
  ) async {
    await tester.pumpWidget(app(const HiddenCategoriesPage()));
    expect(find.text('Giao dịch cũ vẫn giữ danh mục này.'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Khôi phục Quà'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(model.categories.firstWhere((c) => c.id == 'gift').archived, false);
    expect(find.text('Đã khôi phục Quà'), findsOneWidget);
  });

  testWidgets('locking closes the editor and discards the draft', (
    tester,
  ) async {
    await tester.pumpWidget(app(const CategoryPage()));
    await tester.pump();
    await tester.tap(find.text('Ăn uống'));
    await tester.pumpAndSettle();
    expect(find.byType(CategoryEditorPage), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Private draft');
    auth.lock();
    await tester.pumpAndSettle();
    expect(find.byType(CategoryEditorPage), findsNothing);
    expect(find.text('Private draft'), findsNothing);
    expect(model.categories, isEmpty);
    expect(tester.takeException(), isNull);
  });

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('empty name keeps the draft at 320 pt with 2× text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(CategoryEditorPage(model: model), scale: 2));
    await tester.tap(find.text('Lưu danh mục'));
    await tester.pump();
    expect(api.writes, 0);
    expect(find.text('Đặt tên cho danh mục nhé.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adds a subcategory with colour and icon; its parent opens', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(app(CategoryEditorPage(model: model)));
    await tester.enterText(find.byType(TextField).first, 'Trà sữa');
    await tester.tap(find.text('Danh mục con'));
    await tester.pump();
    await tester.tap(find.text('Lưu danh mục'));
    await tester.pump();
    expect(find.text('Chọn danh mục chính nhé.'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Thuộc, Chọn danh mục chính'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Ăn uống').last);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Xanh lá'));
    await tester.tap(find.bySemanticsLabel('Cà phê'));
    await tester.pump();
    await tester.tap(find.text('Lưu danh mục'));
    await tester.pumpAndSettle();
    final body = api.calls.last.body!;
    expect(body, containsPair('parentId', 'food'));
    expect(body, containsPair('colorToken', 'color.semantic.success'));
    expect(body, containsPair('iconToken', 'coffee'));
    expect(body, containsPair('kind', 'expense'));
    expect(model.expanded, contains('food'));
  });

  testWidgets('a main category with subcategories cannot hide or delete', (
    tester,
  ) async {
    phone(tester);
    final food = model.categories.firstWhere((c) => c.id == 'food');
    await tester.pumpWidget(
      app(CategoryEditorPage(model: model, category: food)),
    );
    expect(find.text('Còn 1 danh mục con'), findsOneWidget);
    expect(find.text('Danh mục con'), findsNothing);
    final hide = tester.widget<TextButton>(
      find.ancestor(
        of: find.text('Ẩn'),
        matching: find.byWidgetPredicate((w) => w is TextButton),
      ),
    );
    expect(hide.onPressed, isNull);
  });

  testWidgets('delete moves the transactions to the parent by default', (
    tester,
  ) async {
    phone(tester);
    api.usageCount = 12;
    final coffee = model.categories.firstWhere((c) => c.id == 'coffee');
    CategoryEditResult? result;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await openCategoryEditor(
              context,
              model,
              category: coffee,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xoá'));
    await tester.pumpAndSettle();
    expect(find.text('Xoá “Cà phê”?'), findsOneWidget);
    expect(
      find.text('Không khôi phục được. 12 giao dịch sẽ chuyển sang:'),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(of: find.byType(Dialog), matching: find.text('Xoá')),
    );
    await tester.pumpAndSettle();
    expect(api.calls.last.path, contains('replacementCategoryId=food'));
    expect(result, CategoryEditResult.deleted);
    expect(model.categories.any((c) => c.id == 'coffee'), isFalse);
  });

  testWidgets('"Ẩn" hides at once and closes the editor', (tester) async {
    phone(tester);
    final coffee = model.categories.firstWhere((c) => c.id == 'coffee');
    CategoryEditResult? result;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await openCategoryEditor(
              context,
              model,
              category: coffee,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ẩn'));
    await tester.pumpAndSettle();
    expect(result, CategoryEditResult.hidden);
    expect(model.categories.firstWhere((c) => c.id == 'coffee').archived, true);
  });
}
