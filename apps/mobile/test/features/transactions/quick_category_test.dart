import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/categories/domain/category_repository.dart';
import 'package:mobile/features/categories/domain/category_use_cases.dart';
import 'package:mobile/features/categories/domain/finance_category.dart';
import 'package:mobile/features/transactions/presentation/widgets/composer/category_picker_sheet.dart';

import '../../core/widgets/widget_test_app.dart';
import '../../support/server_config_fixture.dart';

class _Repository implements CategoryRepository {
  AuthFailure? failure;
  final created = <CategoryDraft>[];

  @override
  Future<Either<AuthFailure, FinanceCategory>> save(
    CategoryDraft draft, {
    FinanceCategory? category,
    required String clientId,
  }) async {
    if (failure != null) return left(failure!);
    created.add(draft);
    return right(
      FinanceCategory(
        id: 'new-${created.length}',
        name: draft.name,
        parentId: null,
        kind: draft.kind,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Repository repository;
  late DefaultCategoryUseCases cases;
  const food = FinanceCategory(id: 'food', name: 'Ăn uống', parentId: null);

  setUpAll(loadTestFonts);
  setUp(() async {
    await getIt.reset();
    registerTestServerConfig();
    repository = _Repository();
    cases = DefaultCategoryUseCases(repository, testServerConfigModel());
    getIt.registerSingleton<CategoryUseCases>(cases);
  });
  tearDown(() async {
    await getIt.reset();
    registerTestServerConfig();
  });

  test('saving a category tells listeners; a failed save does not', () async {
    var events = 0;
    final sub = cases.changes.listen((_) => events++);
    await cases.save(
      const CategoryDraft(name: 'Cà phê'),
      const [],
      const CategoryOptions(),
      clientId: 'a',
    );
    await Future<void>.delayed(Duration.zero);
    expect(events, 1);
    repository.failure = const AuthFailure(AuthError.network);
    await cases.save(
      const CategoryDraft(name: 'Trà'),
      const [],
      const CategoryOptions(),
      clientId: 'b',
    );
    await Future<void>.delayed(Duration.zero);
    expect(events, 1);
    await sub.cancel();
  });

  Future<String?> open(WidgetTester t, {CategoryKind? kind}) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    String? picked;
    await t.pumpWidget(
      testApp(
        Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async => picked = await showCategoryPicker(
                context,
                categories: const [food],
                frequent: const [],
                selected: null,
                createKind: kind,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    return picked;
  }

  testWidgets('no create row unless the caller asks for it', (t) async {
    await open(t);
    expect(find.text('Tạo danh mục mới'), findsNothing);
  });

  testWidgets('creates a category from the picker and picks it', (t) async {
    await open(t, kind: CategoryKind.expense);
    expect(find.text('Tạo danh mục mới'), findsOneWidget);
    await t.tap(find.text('Tạo danh mục mới'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).last, 'Cà phê');
    await t.tap(find.text('Tạo và chọn'));
    await t.pumpAndSettle();
    expect(repository.created.single.name, 'Cà phê');
    expect(repository.created.single.kind, CategoryKind.expense);
    // Both sheets are closed again.
    expect(find.text('Tạo và chọn'), findsNothing);
    expect(find.text('Chọn danh mục'), findsNothing);
  });

  testWidgets('a name already used is refused without a request', (t) async {
    await open(t, kind: CategoryKind.expense);
    await t.tap(find.text('Tạo danh mục mới'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).last, 'ăn uống');
    await t.tap(find.text('Tạo và chọn'));
    await t.pumpAndSettle();
    expect(find.text('Đã có danh mục tên này'), findsOneWidget);
    expect(repository.created, isEmpty);
  });

  testWidgets('typing in search turns the row into "Tạo “…”"', (t) async {
    await open(t, kind: CategoryKind.income);
    await t.enterText(find.byType(TextField).first, 'Freelance');
    await t.pump();
    expect(find.text('Tạo “Freelance”'), findsOneWidget);
    await t.tap(find.text('Tạo “Freelance”'));
    await t.pumpAndSettle();
    expect(tester(t).controller.text, 'Freelance');
  });
}

({TextEditingController controller}) tester(WidgetTester t) =>
    (controller: t.widget<TextField>(find.byType(TextField).last).controller!);
