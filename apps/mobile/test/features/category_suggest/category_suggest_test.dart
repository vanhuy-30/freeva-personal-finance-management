import 'package:dartz/dartz.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/category_suggest/data/category_suggest_repository_impl.dart';
import 'package:mobile/features/category_suggest/domain/category_suggestion.dart';
import 'package:mobile/features/category_suggest/presentation/viewmodels/category_suggest_view_model.dart';
import 'package:mobile/features/server_config/domain/server_config.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';
import 'package:mobile/features/transactions/presentation/widgets/composer/transaction_composer_screen.dart';

import '../auto_suggest/auto_suggest_fakes.dart' show FakeFlags;
import '../profile/fakes.dart' show Transport;
import '../transactions/c1_stub.dart';
import 'category_suggest_fakes.dart';

const _offline = AuthFailure(AuthError.network);

void main() {
  group('data', () {
    Map<String, dynamic> body(String source, int count, int? percent) => {
      'suggestion': {
        'category': {
          'id': 'cat',
          'name': 'Cà phê',
          'iconToken': 'coffee',
          'colorToken': null,
        },
        'source': source,
        'matchCount': count,
        'confidencePercent': percent,
      },
    };

    test('suggest sends merchant or note and reads each source', () async {
      final api = Transport()..response = body('remembered', 8, null);
      final repo = CategorySuggestRepositoryImpl(api);
      final s = (await repo.suggest(
        income: false,
        merchant: 'Highlands Coffee',
      )).getOrElse(() => throw StateError(''))!;
      expect((api.method, api.path), ('POST', 'category-suggestions/suggest'));
      expect(api.body, {
        'merchant': 'Highlands Coffee',
        'note': null,
        'type': 'expense',
      });
      expect(s.categoryId, 'cat');
      expect(s.categoryName, 'Cà phê');
      expect(s.iconToken, 'coffee');
      expect(s.colorToken, isNull);
      expect(s.source, SuggestionSource.remembered);
      expect(s.matchCount, 8);
      expect(s.confidencePercent, isNull);

      api.response = body('history', 5, 83);
      final h = (await repo.suggest(
        income: true,
        note: 'lương',
      )).fold((_) => null, (v) => v)!;
      expect(api.body, {'merchant': null, 'note': 'lương', 'type': 'income'});
      expect(
        (h.source, h.matchCount, h.confidencePercent),
        (SuggestionSource.history, 5, 83),
      );

      api.response = body('common', 0, null);
      final c = (await repo.suggest(
        income: false,
        merchant: 'Grab',
      )).fold((_) => null, (v) => v)!;
      expect((c.source, c.matchCount), (SuggestionSource.common, 0));

      api.response = {'suggestion': null};
      expect(await repo.suggest(income: false, merchant: 'x y'), right(null));

      api.response = {
        'suggestion': {'source': 'magic'},
      };
      expect(
        (await repo.suggest(income: false, merchant: 'xy')).isLeft(),
        true,
      );
    });

    test('feedback posts what was kept', () async {
      final api = Transport();
      final repo = CategorySuggestRepositoryImpl(api);
      final result = await repo.feedback(
        const SuggestionFeedback(
          merchant: 'Highlands Coffee',
          suggestedCategoryId: 'a',
          chosenCategoryId: 'b',
          source: SuggestionSource.common,
          surface: SuggestionSurface.entry,
        ),
      );
      expect(result.isRight(), isTrue);
      expect((api.method, api.path), ('POST', 'category-suggestions/feedback'));
      expect(api.body, {
        'merchant': 'Highlands Coffee',
        'suggestedCategoryId': 'a',
        'chosenCategoryId': 'b',
        'source': 'common',
        'surface': 'entry',
      });
    });
  });

  group('view model', () {
    late FakeCategorySuggest repo;
    late FakeFlags flags;
    late CategorySuggestViewModel vm;

    setUp(() {
      repo = FakeCategorySuggest();
      flags = FakeFlags()..on = {FeatureFlags.categorySuggest};
      vm = CategorySuggestViewModel(repo, flags);
    });

    void type(
      String merchant, {
      String note = '',
      String? category = 'food',
      TransactionType kind = TransactionType.expense,
    }) => vm.update(
      type: kind,
      merchant: merchant,
      note: note,
      categoryId: category,
    );

    const wait = CategorySuggestViewModel.debounce;

    test('debounces typing into one call and shows the card', () {
      fakeAsync((async) {
        for (final text in ['H', 'Hi', 'Hig', 'Highlands', 'Highlands C']) {
          type(text);
          async.elapse(const Duration(milliseconds: 100));
        }
        expect(repo.calls, isEmpty);
        async.elapse(wait);
        expect(repo.calls, hasLength(1));
        expect(repo.calls.single.merchant, 'Highlands C');
        expect(repo.calls.single.note, isNull);
        expect(repo.calls.single.income, isFalse);
        expect(vm.visible?.categoryId, 'coffee');
      });
    });

    test('uses the note only while the merchant is empty; < 2 chars waits', () {
      fakeAsync((async) {
        type('', note: 'c');
        async.elapse(wait);
        expect(repo.calls, isEmpty);
        type('', note: 'cà phê sáng');
        async.elapse(wait);
        expect(repo.calls.single.note, 'cà phê sáng');
        expect(repo.calls.single.merchant, isNull);
        type('H', note: 'cà phê sáng');
        async.elapse(wait);
        expect(repo.calls, hasLength(1));
        expect(vm.visible, isNull);
      });
    });

    test('a stale answer never replaces the latest one', () {
      fakeAsync((async) {
        repo.hold = true;
        type('Highlands');
        async.elapse(wait);
        type('Grab');
        async.elapse(wait);
        expect(repo.calls, hasLength(2));
        repo.calls[1].completer.complete(right(null));
        repo.calls[0].completer.complete(right(boardSuggestion));
        async.flushMicrotasks();
        expect(vm.visible, isNull);
      });
    });

    test('flag off or transfer: no call, no card', () {
      fakeAsync((async) {
        flags.on = {};
        type('Highlands Coffee');
        async.elapse(wait);
        flags.on = {FeatureFlags.categorySuggest};
        type('Highlands Coffee', kind: TransactionType.transfer);
        async.elapse(wait);
        expect(repo.calls, isEmpty);
        expect(vm.visible, isNull);
      });
    });

    test('hidden when it is already the category, or text cleared', () {
      fakeAsync((async) {
        type('Highlands Coffee', category: 'coffee');
        async.elapse(wait);
        expect(vm.visible, isNull);
        type('Highlands Coffee', category: 'food');
        expect(vm.visible?.categoryId, 'coffee');
        type('');
        expect(vm.visible, isNull);
      });
    });

    test('Dùng returns the category and hides the card', () {
      fakeAsync((async) {
        type('Highlands Coffee');
        async.elapse(wait);
        expect(vm.use(), 'coffee');
        expect(vm.visible, isNull);
        expect(vm.use(), isNull);
      });
    });

    test('errors are silent', () {
      fakeAsync((async) {
        repo.failure = _offline;
        type('Highlands Coffee');
        async.elapse(wait);
        expect(vm.visible, isNull);
        expect(vm.shown, isNull);
      });
    });

    test('feedback: accepted, corrected, nothing shown, errors', () {
      fakeAsync((async) {
        void save(String? chosen, {String merchant = 'Highlands Coffee '}) {
          vm.sendFeedback(
            type: TransactionType.expense,
            chosenCategoryId: chosen,
            merchant: merchant,
          );
          async.flushMicrotasks();
        }

        save('food');
        expect(repo.feedbacks, isEmpty);

        type('Highlands Coffee');
        async.elapse(wait);
        save(vm.use());
        expect(repo.feedbacks.single.accepted, isTrue);
        expect(repo.feedbacks.single.merchant, 'Highlands Coffee');
        expect(repo.feedbacks.single.source, SuggestionSource.history);
        expect(repo.feedbacks.single.surface, SuggestionSurface.entry);

        save('food', merchant: '');
        expect(repo.feedbacks.last.accepted, isFalse);
        expect(repo.feedbacks.last.suggestedCategoryId, 'coffee');
        expect(repo.feedbacks.last.chosenCategoryId, 'food');
        expect(repo.feedbacks.last.merchant, isNull);

        repo.throwOnFeedback = true;
        save('food');
        expect(repo.feedbacks, hasLength(2));
      });
    });
  });

  group('form', () {
    testWidgets('card under Cửa hàng; Dùng sets Danh mục; feedback on save', (
      t,
    ) async {
      t.view.physicalSize = const Size(390, 1400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final model = StubTransactionViewModel();
      final repo = FakeCategorySuggest();
      final app = await c1App(
        TransactionComposerScreen(model: model),
        model: model,
      );
      getIt.registerFactory<CategorySuggestViewModel>(
        () => CategorySuggestViewModel(
          repo,
          FakeFlags()..on = {FeatureFlags.categorySuggest},
        ),
      );
      addTearDown(getIt.reset);
      await t.pumpWidget(app);
      await t.tap(find.bySemanticsLabel('5').last);
      await t.tap(find.text('Ghi chú, cửa hàng, nhãn'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).first, 'Highlands Coffee');
      await t.pump(CategorySuggestViewModel.debounce);
      await t.pump();
      expect(repo.calls, hasLength(1));
      expect(find.text('Xếp vào Cà phê?'), findsOneWidget);
      expect(find.text('Như 8 lần trước ở đây'), findsOneWidget);

      await t.tap(find.text('Dùng'));
      await t.pump();
      expect(find.text('Xếp vào Cà phê?'), findsNothing);
      expect(find.text('Cà phê'), findsOneWidget);

      await t.tap(find.text('Lưu khoản chi'));
      await t.pumpAndSettle();
      expect(model.saved.single.categoryId, 'coffee');
      expect(repo.feedbacks.single.accepted, isTrue);
      expect(repo.feedbacks.single.merchant, 'Highlands Coffee');
    });

    testWidgets('editing never asks', (t) async {
      t.view.physicalSize = const Size(390, 1400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final model = StubTransactionViewModel();
      final repo = FakeCategorySuggest();
      final app = await c1App(
        TransactionComposerScreen(model: model, existing: canvasRows().first),
        model: model,
      );
      getIt.registerFactory<CategorySuggestViewModel>(
        () => CategorySuggestViewModel(
          repo,
          FakeFlags()..on = {FeatureFlags.categorySuggest},
        ),
      );
      addTearDown(getIt.reset);
      await t.pumpWidget(app);
      await t.enterText(find.byType(TextField).first, 'Highlands Coffee');
      await t.pump(const Duration(seconds: 1));
      expect(repo.calls, isEmpty);
      expect(find.text('Dùng'), findsNothing);
    });
  });
}
