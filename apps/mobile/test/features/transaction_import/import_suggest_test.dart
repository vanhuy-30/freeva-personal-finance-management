import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/widgets/freeva_switch.dart';
import 'package:mobile/features/transaction_import/data/import_repository_impl.dart';
import 'package:mobile/features/transaction_import/domain/import_models.dart';
import 'package:mobile/features/transaction_import/presentation/viewmodels/import_view_model.dart';

import 'import_stub.dart';

/// MOB-P5-E03: category suggestions in the import preview (boards R.2, R.3).
void main() {
  group('ImportRepositoryImpl suggestions', () {
    Map<String, dynamic> rowJson({Object? suggestion}) => {
      'rows': [3],
      'status': 'ready',
      'errors': <String>[],
      'type': 'expense',
      'occurredOn': '2026-11-03',
      'amountMinor': '45000',
      'currencyCode': 'VND',
      'merchant': 'Highlands Coffee',
      'notes': null,
      'accountId': 'cash',
      'categoryId': 'coffee',
      'suggestion': suggestion,
    };

    test('a row reads the guess, or none', () {
      final row = ImportRepositoryImpl.parseRow(
        rowJson(
          suggestion: {
            'category': {
              'id': 'coffee',
              'name': 'Cà phê',
              'iconToken': 'coffee',
              'colorToken': null,
            },
            'source': 'remembered',
            'matchCount': 8,
          },
        ),
      );
      expect(row.suggestion!.categoryId, 'coffee');
      expect(row.suggestion!.categoryName, 'Cà phê');
      expect(row.suggestion!.iconToken, 'coffee');
      expect(row.suggestion!.colorToken, isNull);
      expect(row.suggestion!.source, ImportSuggestionSource.remembered);
      expect(row.suggestion!.matchCount, 8);
      expect(row.keepsSuggestion, isTrue);
      expect(ImportRepositoryImpl.parseRow(rowJson()).suggestion, isNull);
    });

    test('the summary carries the Gợi ý count', () {
      final preview = ImportRepositoryImpl.parsePreview({
        'columns': <String, dynamic>{},
        'summary': {
          'rowCount': 3,
          'ready': 3,
          'duplicate': 0,
          'invalid': 0,
          'suggested': 2,
        },
        'unmapped': {'wallets': <String>[], 'categories': <String>[]},
        'rows': [rowJson()],
      });
      expect(preview.summary.suggested, 2);
    });

    test('row and merchant maps are sent only when set', () {
      const bare = ImportRequest(text: 'x', source: ImportSource.freeva);
      final body = ImportRepositoryImpl.body(bare);
      expect(body.containsKey('rowCategoryMap'), isFalse);
      expect(body.containsKey('merchantCategoryMap'), isFalse);
      final full = ImportRepositoryImpl.body(
        const ImportRequest(
          text: 'x',
          source: ImportSource.freeva,
          rowCategoryMap: {12: 'food'},
          merchantCategoryMap: {'Highlands Coffee': 'coffee'},
        ),
      );
      expect(full['rowCategoryMap'], {'12': 'food'});
      expect(full['merchantCategoryMap'], {'Highlands Coffee': 'coffee'});
    });
  });

  group('ImportViewModel suggestions', () {
    late ImportHarness h;
    late DefaultImportViewModel model;

    setUp(() async {
      h = ImportHarness.create(
        [boardSuggestPlan()],
        wallets: boardWallets,
        catalog: boardCatalog,
      );
      model = h.model;
      await model.load();
      await model.chooseFile();
    });

    ImportRow line(int n) =>
        model.preview!.rows.firstWhere((r) => r.rows.first == n);

    test('Gợi ý shows only guessed rows that can be imported', () {
      expect(model.suggestedCount, 18);
      model.selectFilter(ImportFilter.suggested);
      expect(model.shownRows.map((r) => r.merchant), [
        'Highlands Coffee',
        'Grab',
        'Shopee',
        'WinMart',
        'Circle K',
      ]);
    });

    test('guessed rows open the sheet; rows with a file category do not', () {
      expect(model.canPickCategory(line(1)), isTrue);
      expect(model.canPickCategory(line(6)), isFalse);
      // No date: cannot be imported whatever the category.
      expect(model.canPickCategory(line(20)), isFalse);
    });

    test(
      'an expense the file left blank and nobody guessed opens it',
      () async {
        final blank = importRow(
          ImportRowStatus.invalid,
          errors: const [ImportRowError.categoryUnmapped],
          line: 7,
          merchant: 'Chợ',
          category: null,
        );
        final h2 = ImportHarness.create([
          plan(rows: [blank], categories: ['']),
        ], catalog: boardCatalog);
        await h2.model.load();
        await h2.model.chooseFile();
        expect(h2.model.canPickCategory(blank), isTrue);
        final named = plan(rows: [blank], categories: ['Shopping']).rows.single;
        final h3 = ImportHarness.create([
          plan(rows: [named], categories: ['Shopping']),
        ], catalog: boardCatalog);
        await h3.model.load();
        await h3.model.chooseFile();
        expect(h3.model.canPickCategory(named), isFalse);
      },
    );

    test('the sheet counts the same shop and offers three others', () {
      final choice = model.categoryChoice(line(1));
      expect(choice.title, 'Highlands Coffee');
      expect(choice.walletName, 'Tiền mặt');
      expect(choice.selectedId, 'coffee');
      expect(choice.sameMerchantCount, 6);
      expect(choice.quick.map((c) => c.id), ['food', 'market', 'shopping']);
      expect(choice.fitting.map((c) => c.id), isNot(contains('salary')));
      expect(model.categoryChoice(line(2)).sameMerchantCount, 1);
    });

    test('switch on maps the shop and plans again', () async {
      final before = h.useCases.previews.length;
      await model.chooseCategory(line(1), 'food', applyToMerchant: true);
      expect(model.merchantCategoryMap, {'Highlands Coffee': 'food'});
      expect(model.rowCategoryMap, isEmpty);
      expect(h.useCases.previews, hasLength(before + 1));
      expect(h.useCases.previews.last.merchantCategoryMap, {
        'Highlands Coffee': 'food',
      });
    });

    test('switch off maps the one row and replaces the shop pick', () async {
      await model.chooseCategory(line(1), 'food', applyToMerchant: false);
      expect(model.rowCategoryMap, {1: 'food'});
      expect(h.useCases.previews.last.rowCategoryMap, {1: 'food'});
      // The shop pick clears the row picks of that shop.
      await model.chooseCategory(line(1), 'market', applyToMerchant: true);
      expect(model.rowCategoryMap, isEmpty);
      expect(model.merchantCategoryMap, {'Highlands Coffee': 'market'});
    });

    test('picking the suggestion again clears the override', () async {
      await model.chooseCategory(line(2), 'food', applyToMerchant: false);
      expect(model.rowCategoryMap, {2: 'food'});
      await model.chooseCategory(line(2), 'move', applyToMerchant: false);
      expect(model.rowCategoryMap, isEmpty);

      await model.chooseCategory(line(1), 'food', applyToMerchant: true);
      await model.chooseCategory(line(1), 'coffee', applyToMerchant: true);
      expect(model.merchantCategoryMap, isEmpty);
      final sent = h.useCases.previews.last;
      expect(sent.merchantCategoryMap, isEmpty);
      expect(sent.rowCategoryMap, isEmpty);
    });

    test('a row going back to the guess under a shop pick keeps it', () async {
      await model.chooseCategory(line(1), 'food', applyToMerchant: true);
      await model.chooseCategory(line(1), 'coffee', applyToMerchant: false);
      expect(model.merchantCategoryMap, {'Highlands Coffee': 'food'});
      expect(model.rowCategoryMap, {1: 'coffee'});
    });

    test('nothing changed: no new plan', () async {
      final before = h.useCases.previews.length;
      await model.chooseCategory(line(1), 'coffee', applyToMerchant: false);
      expect(h.useCases.previews, hasLength(before));
    });

    test('commit sends the maps the user built', () async {
      await model.chooseCategory(line(3), 'food', applyToMerchant: false);
      await model.chooseCategory(line(1), 'food', applyToMerchant: true);
      await model.commit();
      final sent = h.useCases.commits.single.request;
      expect(sent.rowCategoryMap, {3: 'food'});
      expect(sent.merchantCategoryMap, {'Highlands Coffee': 'food'});
    });

    test('a new file starts with no picks', () async {
      await model.chooseCategory(line(1), 'food', applyToMerchant: true);
      await model.chooseFile();
      expect(model.merchantCategoryMap, isEmpty);
      expect(h.useCases.previews.last.merchantCategoryMap, isEmpty);
    });
  });

  group('R.3 sheet', () {
    tearDown(() => getIt.reset());

    Future<ImportHarness> open(WidgetTester t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final h = ImportHarness.create(
        [boardSuggestPlan()],
        wallets: boardWallets,
        catalog: boardCatalog,
      );
      await t.pumpWidget(importApp(h));
      await t.pump(const Duration(milliseconds: 400));
      await t.runAsync(() async {
        await h.model.load();
        await h.model.chooseFile();
      });
      await t.pump();
      await t.tap(find.text('Highlands Coffee'));
      await t.pumpAndSettle();
      return h;
    }

    testWidgets('another category for the whole shop', (t) async {
      final h = await open(t);
      expect(find.text('GỢI Ý'), findsOneWidget);
      expect(find.text('Áp dụng cho 6 khoản ở đây'), findsOneWidget);
      await t.tap(find.text('Đi chợ').last);
      await t.pump();
      await t.tap(find.text('Xong'));
      await t.pumpAndSettle();
      expect(h.model.merchantCategoryMap, {'Highlands Coffee': 'market'});
      expect(h.useCases.previews.last.merchantCategoryMap, {
        'Highlands Coffee': 'market',
      });
    });

    testWidgets('switch off picks for this row only', (t) async {
      final h = await open(t);
      await t.tap(find.byType(FreevaSwitch).last);
      await t.pump();
      await t.tap(find.text('Ăn uống').last);
      await t.tap(find.text('Xong'));
      await t.pumpAndSettle();
      expect(h.model.rowCategoryMap, {1: 'food'});
      expect(h.model.merchantCategoryMap, isEmpty);
    });

    testWidgets('rows with a file category do not open it', (t) async {
      await open(t);
      await t.tap(find.text('Xong'));
      await t.pumpAndSettle();
      await t.tap(find.text('Phở Thìn'));
      await t.pumpAndSettle();
      expect(find.text('Xong'), findsNothing);
    });
  });
}
