import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/categories/domain/finance_category.dart';
import 'package:mobile/features/categories/presentation/viewmodels/category_form.dart';

import 'e1_stub.dart';

void main() {
  final all = canvasCategories();
  FinanceCategory byId(String id) => all.firstWhere((c) => c.id == id);
  CategoryForm form({
    FinanceCategory? category,
    CategoryKind tab = CategoryKind.expense,
  }) => CategoryForm(
    categories: all,
    clientId: 'c',
    tabKind: tab,
    category: category,
  );

  test('new main category takes the tab kind; empty name is an error', () {
    final f = form(tab: CategoryKind.income);
    expect(f.build('  '), isNull);
    expect(f.errors, {CategoryFormError.name});
    final draft = f.build(' Thưởng Tết ')!;
    expect(
      (draft.name, draft.kind, draft.parentId),
      ('Thưởng Tết', CategoryKind.income, null),
    );
  });

  test('a subcategory needs a parent from the same tab', () {
    final f = form()..setChild(true);
    expect(f.build('Trà sữa'), isNull);
    expect(f.errors, {CategoryFormError.parent});
    final names = f.parentChoices.map((c) => c.id);
    expect(names, containsAll(['food', 'bills', 'gift']));
    expect(names, isNot(contains('salary')));
    expect(names, isNot(contains('snack')));
    expect(names, isNot(contains('school')));
    f.setParent('food');
    expect(f.build('Trà sữa')!.parentId, 'food');
    f.setChild(false);
    expect(f.build('Trà sữa')!.parentId, isNull);
  });

  test('a main category with subcategories stays main; edits keep fields', () {
    final food = form(category: byId('food'));
    expect(food.canBeChild, isFalse);
    food.setChild(true);
    expect(food.child, isFalse);
    final snack = form(category: byId('snack'));
    expect(
      (snack.child, snack.parentId, snack.colorToken),
      (true, 'food', 'color.brand.accent'),
    );
    expect(snack.parentChoices.map((c) => c.id), isNot(contains('snack')));
  });
}
