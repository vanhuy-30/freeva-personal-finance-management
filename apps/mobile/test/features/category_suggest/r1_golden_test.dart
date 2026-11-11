import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/features/category_suggest/presentation/viewmodels/category_suggest_view_model.dart';
import 'package:mobile/features/server_config/domain/server_config.dart';
import 'package:mobile/features/transactions/presentation/widgets/composer/transaction_composer_screen.dart';

import '../../core/widgets/widget_test_app.dart' show loadTestFonts;
import '../auto_suggest/auto_suggest_fakes.dart' show FakeFlags;
import '../transactions/c1_stub.dart';
import 'category_suggest_fakes.dart';

/// Board clock: "Hôm nay, 08:15".
class _MorningModel extends StubTransactionViewModel {
  @override
  String? nowTime() => '08:15';
}

// Board R.1 SugExpense (390×844). macOS only.
// Update: flutter test --update-goldens test/features/category_suggest/r1_golden_test.dart
void main() {
  setUpAll(loadTestFonts);
  tearDown(() => getIt.reset());

  Future<void> shot(WidgetTester t, String name, {bool dark = false}) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final model = _MorningModel();
    final app = await c1App(
      TransactionComposerScreen(model: model),
      model: model,
      dark: dark,
    );
    getIt.registerFactory<CategorySuggestViewModel>(
      () => CategorySuggestViewModel(
        FakeCategorySuggest(),
        FakeFlags()..on = {FeatureFlags.categorySuggest},
      ),
    );
    await t.pumpWidget(app);
    await t.pump(const Duration(milliseconds: 300));
    for (final key in ['4', '5', '000']) {
      await t.tap(find.bySemanticsLabel(key).last);
    }
    await t.tap(find.text('Ghi chú, cửa hàng, nhãn'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).first, 'Highlands Coffee');
    await t.pump(CategorySuggestViewModel.debounce);
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('R.1 suggestion card', skip: !Platform.isMacOS, (t) async {
    await shot(t, 'r1_sug_expense');
  });
  testWidgets('R.1 suggestion card dark', skip: !Platform.isMacOS, (t) async {
    await shot(t, 'r1_sug_expense_dark', dark: true);
  });
}
