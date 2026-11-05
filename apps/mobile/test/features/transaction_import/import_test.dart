import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/transaction_import/data/import_repository_impl.dart';
import 'package:mobile/features/transaction_import/domain/csv_peek.dart';
import 'package:mobile/features/transaction_import/domain/import_models.dart';
import 'package:mobile/features/transaction_import/presentation/viewmodels/import_view_model.dart';

import 'import_stub.dart';

void main() {
  group('CsvPeek', () {
    test('reads header, row count and first row', () {
      final peek = CsvPeek.parse(sampleCsv);
      expect(peek.headers.first, 'Ngay');
      expect(peek.headers, hasLength(6));
      expect(peek.rowCount, 3);
      expect(peek.firstRow[1], '65.000');
    });

    test('ignores a BOM, blank lines and reads semicolons', () {
      final peek = CsvPeek.parse('﻿a;b\r\n\r\n1;2\r\n3;4\r\n');
      expect(peek.headers, ['a', 'b']);
      expect(peek.rowCount, 2);
      expect(peek.firstRow, ['1', '2']);
    });

    test('quoted cells keep commas, quotes and line breaks', () {
      final peek = CsvPeek.parse('a,b\n"x, ""y""\nz",2\n');
      expect(peek.rowCount, 1);
      expect(peek.firstRow, ['x, "y"\nz', '2']);
    });

    test('empty and header-only files are empty', () {
      expect(CsvPeek.parse('').isEmpty, isTrue);
      expect(CsvPeek.parse('a,b\n').isEmpty, isTrue);
    });

    test('flags more rows than the API takes', () {
      final text = 'a\n${List.filled(importMaxRows + 1, '1').join('\n')}';
      expect(CsvPeek.parse(text).tooManyRows, isTrue);
      final ok = 'a\n${List.filled(importMaxRows, '1').join('\n')}';
      expect(CsvPeek.parse(ok).tooManyRows, isFalse);
    });
  });

  group('ImportRepositoryImpl', () {
    test('request body carries only what was chosen', () {
      expect(
        ImportRepositoryImpl.body(
          const ImportRequest(text: 'x', source: ImportSource.moneyLover),
        ),
        {'text': 'x', 'preset': 'money_lover'},
      );
      expect(
        ImportRepositoryImpl.body(
          const ImportRequest(
            text: 'x',
            source: ImportSource.other,
            dateFormat: ImportDateFormat.dmy,
            numberFormat: ImportNumberFormat.dotThousands,
            mapping: {ImportField.date: 'Ngay', ImportField.amount: 'Tien'},
            walletMap: {'Ví': 'w1'},
            categoryMap: {'Ăn': 'c1'},
            defaultAccountId: 'w2',
          ),
        ),
        {
          'text': 'x',
          'preset': 'custom',
          'dateFormat': 'dmy',
          'numberFormat': 'dot_thousands',
          'mapping': {'date': 'Ngay', 'amount': 'Tien'},
          'walletMap': {'Ví': 'w1'},
          'categoryMap': {'Ăn': 'c1'},
          'defaultAccountId': 'w2',
        },
      );
    });

    test('rows keep money as exact minor units', () {
      final row = ImportRepositoryImpl.parseRow({
        'rows': [3, 4],
        'status': 'skipped_duplicate',
        'errors': ['TRANSFER_UNPAIRED', 'SOMETHING_NEW'],
        'type': 'transfer',
        'occurredOn': '2026-11-02',
        'occurredTime': null,
        'accountId': 'a',
        'toAccountId': 'b',
        'currencyCode': 'VND',
        'amountMinor': '9007199254740993',
        'categoryId': null,
        'merchant': null,
        'notes': 'n',
        'duplicateOfId': null,
      });
      expect(row.rows, [3, 4]);
      expect(row.status, ImportRowStatus.skippedDuplicate);
      expect(row.errors, [
        ImportRowError.transferUnpaired,
        ImportRowError.other,
      ]);
      expect(row.amountMinor, BigInt.parse('9007199254740993'));
    });

    test('preview and batch parse', () {
      final preview = ImportRepositoryImpl.parsePreview({
        'preset': 'money_lover',
        'columns': {'date': 'Ngay'},
        'summary': {'rowCount': 8, 'ready': 5, 'duplicate': 2, 'invalid': 1},
        'unmapped': {
          'wallets': ['A'],
          'categories': ['B', 'C'],
        },
        'rows': <Object>[],
      });
      expect(preview.summary.ready, 5);
      expect(preview.unmappedCount, 3);
      final b = ImportRepositoryImpl.parseBatch({
        'id': 'x',
        'createdCount': 1,
        'duplicateCount': 2,
        'invalidCount': 3,
        'remainingCount': 1,
        'undoneAt': '2026-11-05T00:00:00Z',
      });
      expect(b.undone, isTrue);
    });
  });

  group('ImportViewModel', () {
    late ImportHarness h;
    late ImportViewModel model;
    tearDown(() => model.dispose());

    Future<void> start(List<ImportPreview> plans) async {
      h = ImportHarness.create(plans);
      model = h.model;
      await model.load();
    }

    test('load keeps active wallets and categories', () async {
      await start([plan()]);
      expect(model.wallets.map((w) => w.id), ['cash', 'tcb']);
      expect(model.categories.map((c) => c.id), ['food', 'salary']);
    });

    test(
      'a preset file with nothing to match goes straight to preview',
      () async {
        await start([plan()]);
        await model.chooseFile();
        expect(model.step, ImportStep.preview);
        expect(model.fileName, 'so-chi-tieu.csv');
        final request = h.useCases.previews.single;
        expect(request.source, ImportSource.moneyLover);
        expect(request.mapping, isEmpty);
        expect(request.dateFormat, isNull);
        expect(model.importCount, 241);
      },
    );

    test('names left to match open the mapping and are sent back', () async {
      await start([
        plan(wallets: ['Vi tien mat'], categories: ['An sang', 'Luong']),
        plan(),
      ]);
      await model.chooseFile();
      expect(model.step, ImportStep.map);
      expect(model.unmappedCount, 3);
      model.mapWallet('Vi tien mat', 'cash');
      model.mapCategory('An sang', 'food');
      expect(model.unmappedCount, 1);
      model.mapCategory('Luong', 'salary');
      expect(model.unmappedCount, 0);
      await model.showPreview();
      expect(model.step, ImportStep.preview);
      final request = h.useCases.previews.last;
      expect(request.walletMap, {'Vi tien mat': 'cash'});
      expect(request.categoryMap, {'An sang': 'food', 'Luong': 'salary'});
      // Names stay listed after the server stops reporting them.
      expect(model.walletNames, ['Vi tien mat']);
    });

    test('no wallet column asks for one wallet for every row', () async {
      await start([plan(columns: const {}), plan(columns: const {})]);
      await model.chooseFile();
      expect(model.needsDefaultWallet, isTrue);
      expect(model.step, ImportStep.map);
      expect(model.unmappedCount, 1);
      model.selectDefaultWallet('tcb');
      await model.showPreview();
      expect(h.useCases.previews.last.defaultAccountId, 'tcb');
    });

    test('other source guesses columns, then the user continues', () async {
      await start([plan()]);
      model.selectSource(ImportSource.other);
      await model.chooseFile();
      expect(model.step, ImportStep.columns);
      expect(h.useCases.previews, isEmpty);
      expect(model.mapping[ImportField.date], 'Ngay');
      expect(model.mapping[ImportField.amount], 'So tien');
      expect(model.mapping[ImportField.type], 'Loai');
      expect(model.mapping[ImportField.category], 'Nhom');
      expect(model.mapping[ImportField.wallet], 'Tai khoan');
      expect(model.mapping[ImportField.notes], 'Ghi chu');
      expect(model.canContinueColumns, isTrue);

      model.mapColumn(ImportField.date, null);
      expect(model.canContinueColumns, isFalse);
      model.mapColumn(ImportField.date, 'Ngay');
      model.selectDateFormat(ImportDateFormat.mdy);
      await model.continueFromColumns();
      final request = h.useCases.previews.single;
      expect(request.source, ImportSource.other);
      expect(request.dateFormat, ImportDateFormat.mdy);
      expect(request.numberFormat, ImportNumberFormat.dotThousands);
      expect(request.mapping[ImportField.amount], 'So tien');
    });

    test('files the API would refuse never leave the phone', () async {
      await start([plan()]);
      h.picker.text = '';
      await model.chooseFile();
      expect(model.problem, ImportFileProblem.empty);

      h.picker.text = 'a\n${List.filled(importMaxRows + 1, '1').join('\n')}';
      await model.chooseFile();
      expect(model.problem, ImportFileProblem.tooManyRows);

      h.picker.text = 'a\n${'x' * importMaxChars}';
      await model.chooseFile();
      expect(model.problem, ImportFileProblem.tooLarge);

      h.picker.raw = Uint8List.fromList([0xff, 0xfe, 0x00]);
      await model.chooseFile();
      expect(model.problem, ImportFileProblem.unreadable);

      expect(h.useCases.previews, isEmpty);
      expect(model.step, ImportStep.source);
    });

    test('backing out of the picker changes nothing', () async {
      await start([plan()]);
      h.picker.text = null;
      await model.chooseFile();
      expect(model.step, ImportStep.source);
      expect(model.problem, isNull);
    });

    test('filters and the duplicate switch change what is imported', () async {
      await start([plan()]);
      await model.chooseFile();
      expect(model.shownRows, hasLength(4));
      model.selectFilter(ImportFilter.duplicate);
      expect(model.shownRows.single.merchant, 'Grab');
      model.selectFilter(ImportFilter.invalid);
      expect(model.shownRows.single.merchant, 'Siêu thị');
      expect(model.importCount, 241);
      model.toggleDuplicates(true);
      expect(model.importCount, 246);
    });

    test('commit sends one batch id and reaches the done step', () async {
      await start([plan()]);
      await model.chooseFile();
      model.toggleDuplicates(true);
      expect(await model.commit(), isTrue);
      final sent = h.useCases.commits.single;
      expect(sent.dup, isTrue);
      expect(sent.batchClientId, matches(RegExp(r'^[0-9a-f-]{36}$')));
      expect(model.step, ImportStep.done);
      expect(model.result!.batch.createdCount, 241);
    });

    test('nothing to import cannot be committed', () async {
      await start([plan(ready: 0, duplicate: 3, invalid: 0, rows: [])]);
      await model.chooseFile();
      expect(model.importCount, 0);
      expect(await model.commit(), isFalse);
      expect(h.useCases.commits, isEmpty);
    });

    test('a failed commit stays on preview and keeps the batch id', () async {
      await start([plan()]);
      await model.chooseFile();
      h.useCases.failure = const AuthFailure(AuthError.network);
      expect(await model.commit(), isFalse);
      expect(model.step, ImportStep.preview);
      expect(model.failure?.code, AuthError.network);
      h.useCases.failure = null;
      await model.commit();
      expect(h.useCases.commits, hasLength(2));
      expect(
        h.useCases.commits[0].batchClientId,
        h.useCases.commits[1].batchClientId,
      );
    });

    test('a new file gets a new batch id', () async {
      await start([plan()]);
      await model.chooseFile();
      await model.commit();
      await model.chooseFile();
      await model.commit();
      final ids = h.useCases.commits.map((c) => c.batchClientId).toSet();
      expect(ids, hasLength(2));
    });

    test('undo reports how many came back', () async {
      await start([plan()]);
      await model.chooseFile();
      await model.commit();
      expect(await model.undo(), 241);
      expect(h.useCases.undone, ['batch-1']);
    });

    test('an expired session is reported', () async {
      await start([plan()]);
      h.useCases.failure = const AuthFailure(AuthError.expired);
      await model.chooseFile();
      expect(h.auth.expired, 1);
      expect(model.step, ImportStep.source);
    });

    test('back walks the flow and stops at the ends', () async {
      await start([
        plan(wallets: ['W']),
        plan(),
      ]);
      expect(model.back(), isFalse);
      await model.chooseFile();
      expect(model.step, ImportStep.map);
      model.mapWallet('W', 'cash');
      await model.showPreview();
      expect(model.step, ImportStep.preview);
      expect(model.back(), isTrue);
      expect(model.step, ImportStep.map);
      expect(model.back(), isTrue);
      expect(model.step, ImportStep.source);
      expect(model.back(), isFalse);
    });

    test('money digits follow the currency', () async {
      await start([plan()]);
      await model.load();
      expect(model.digitsOf('VND'), 0);
      expect(model.digitsOf('USD'), 2);
      expect(model.digitsOf('JPY'), 2);
    });
  });
}
