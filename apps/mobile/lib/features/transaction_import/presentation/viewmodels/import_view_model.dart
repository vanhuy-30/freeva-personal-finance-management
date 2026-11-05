import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../categories/domain/category_use_cases.dart';
import '../../../categories/domain/finance_category.dart';
import '../../../sync/domain/sync_queue.dart';
import '../../../wallets/domain/wallet.dart';
import '../../../wallets/domain/wallet_use_cases.dart';
import '../../domain/csv_peek.dart';
import '../../domain/import_file_picker.dart';
import '../../domain/import_models.dart';
import '../../domain/import_use_cases.dart';

/// Screens of the flow, in order (boards `ImportSource` … `ImportDone`).
enum ImportStep { source, columns, map, preview, done }

/// Why the picked file was not taken.
enum ImportFileProblem { unreadable, empty, tooManyRows, tooLarge }

/// Rows the preview list shows.
enum ImportFilter { all, duplicate, invalid }

/// `MOB-P3-011`: Nhập giao dịch. One instance drives all five screens; the
/// server plans every step (`preview`), so nothing here parses money.
abstract class ImportViewModel extends ChangeNotifier {
  ImportStep get step;
  ImportSource get source;
  String? get fileName;
  CsvPeek? get peek;
  ImportFileProblem? get problem;
  bool get busy;
  bool get committing;
  AuthFailure? get failure;

  // Custom file.
  Map<ImportField, String> get mapping;
  ImportDateFormat get dateFormat;
  ImportNumberFormat get numberFormat;
  bool get canContinueColumns;

  // Mapping.
  List<Wallet> get wallets;
  List<FinanceCategory> get categories;
  List<String> get walletNames;
  List<String> get categoryNames;
  Map<String, String> get walletMap;
  Map<String, String> get categoryMap;

  /// True when the file has no wallet column: one wallet takes every row.
  bool get needsDefaultWallet;
  String? get defaultWalletId;
  int get unmappedCount;
  bool get canPreview;

  // Preview and result.
  ImportPreview? get preview;
  ImportFilter get filter;
  List<ImportRow> get shownRows;
  bool get includeDuplicates;
  int get importCount;
  ImportResult? get result;
  int digitsOf(String currency);

  Future<void> load();
  void selectSource(ImportSource value);

  /// Opens the picker and reads the file; moves to the next step on success.
  Future<void> chooseFile();
  void mapColumn(ImportField field, String? header);
  void selectDateFormat(ImportDateFormat value);
  void selectNumberFormat(ImportNumberFormat value);
  Future<void> continueFromColumns();
  void mapWallet(String name, String walletId);
  void mapCategory(String name, String categoryId);
  void selectDefaultWallet(String walletId);
  Future<void> showPreview();
  void selectFilter(ImportFilter value);
  void toggleDuplicates(bool value);

  /// True when the batch was written.
  Future<bool> commit();

  /// Rows the undo left alone; null on failure.
  Future<int?> undo();

  /// Back one step; false when already on the first.
  bool back();
}

@injectable
class DefaultImportViewModel extends ImportViewModel {
  DefaultImportViewModel(
    this._useCases,
    this._wallets,
    this._categories,
    this._picker,
    this._auth,
  );
  final ImportUseCases _useCases;
  final WalletUseCases _wallets;
  final CategoryUseCases _categories;
  final ImportFilePicker _picker;
  final AuthViewModel _auth;

  bool _disposed = false;
  int _epoch = 0;
  String _text = '';
  String _batchClientId = newSyncOpId();
  List<WalletCurrency> _currencies = const [];
  final List<String> _walletSeen = [];
  final List<String> _categorySeen = [];

  @override
  ImportStep step = ImportStep.source;
  @override
  ImportSource source = ImportSource.moneyLover;
  @override
  String? fileName;
  @override
  CsvPeek? peek;
  @override
  ImportFileProblem? problem;
  @override
  bool busy = false;
  @override
  bool committing = false;
  @override
  AuthFailure? failure;
  @override
  Map<ImportField, String> mapping = {};
  @override
  ImportDateFormat dateFormat = ImportDateFormat.dmy;
  @override
  ImportNumberFormat numberFormat = ImportNumberFormat.dotThousands;
  @override
  List<Wallet> wallets = const [];
  @override
  List<FinanceCategory> categories = const [];
  @override
  Map<String, String> walletMap = {};
  @override
  Map<String, String> categoryMap = {};
  @override
  String? defaultWalletId;
  @override
  ImportPreview? preview;
  @override
  ImportFilter filter = ImportFilter.all;
  @override
  bool includeDuplicates = false;
  @override
  ImportResult? result;

  @override
  List<String> get walletNames => List.unmodifiable(_walletSeen);
  @override
  List<String> get categoryNames => List.unmodifiable(_categorySeen);

  @override
  bool get canContinueColumns =>
      mapping.containsKey(ImportField.date) &&
      mapping.containsKey(ImportField.amount);

  @override
  bool get needsDefaultWallet =>
      preview != null && !preview!.columns.containsKey('wallet');

  @override
  int get unmappedCount =>
      _walletSeen.where((n) => !walletMap.containsKey(n)).length +
      _categorySeen.where((n) => !categoryMap.containsKey(n)).length +
      (needsDefaultWallet && defaultWalletId == null ? 1 : 0);

  @override
  bool get canPreview => !busy;

  @override
  List<ImportRow> get shownRows {
    final rows = preview?.rows ?? const <ImportRow>[];
    return switch (filter) {
      ImportFilter.all => rows,
      ImportFilter.duplicate => [
        for (final r in rows)
          if (r.status == ImportRowStatus.duplicate) r,
      ],
      ImportFilter.invalid => [
        for (final r in rows)
          if (r.status == ImportRowStatus.invalid) r,
      ],
    };
  }

  @override
  int get importCount {
    final summary = preview?.summary;
    if (summary == null) return 0;
    return summary.ready + (includeDuplicates ? summary.duplicate : 0);
  }

  @override
  int digitsOf(String currency) =>
      _currencies
          .where((item) => item.code == currency)
          .firstOrNull
          ?.minorDigits ??
      (currency == 'VND' ? 0 : 2);

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _fail(AuthFailure error) {
    failure = error;
    if (error.code == AuthError.expired) _auth.sessionExpired();
  }

  @override
  Future<void> load() async {
    final wallets = await _wallets.load();
    final currencies = await _wallets.currencies();
    final catalog = await _categories.load();
    if (_disposed) return;
    wallets.fold(_fail, (value) {
      this.wallets = [
        for (final w in value)
          if (!w.archived) w,
      ];
    });
    currencies.fold((_) {}, (value) => _currencies = value);
    catalog.fold(_fail, (value) {
      categories = [
        for (final c in value.all)
          if (!c.archived) c,
      ];
    });
    _notify();
  }

  @override
  void selectSource(ImportSource value) {
    if (source == value) return;
    source = value;
    _notify();
  }

  @override
  Future<void> chooseFile() async {
    if (busy) return;
    final PickedImportFile? file;
    try {
      file = await _picker.pick();
    } catch (_) {
      problem = ImportFileProblem.unreadable;
      _notify();
      return;
    }
    if (file == null || _disposed) return;
    problem = null;
    failure = null;
    final String text;
    try {
      text = utf8.decode(file.bytes);
    } on FormatException {
      problem = ImportFileProblem.unreadable;
      _notify();
      return;
    }
    final read = CsvPeek.parse(text);
    if (read.isEmpty) {
      problem = ImportFileProblem.empty;
    } else if (read.tooManyRows) {
      problem = ImportFileProblem.tooManyRows;
    } else if (text.length > importMaxChars) {
      problem = ImportFileProblem.tooLarge;
    }
    if (problem != null) {
      _notify();
      return;
    }
    _text = text;
    peek = read;
    fileName = file.name;
    _resetPlan();
    _batchClientId = newSyncOpId();
    if (source == ImportSource.other) {
      mapping = _guessColumns(read.headers);
      step = ImportStep.columns;
      _notify();
      return;
    }
    await _plan(firstLook: true);
  }

  void _resetPlan() {
    preview = null;
    result = null;
    walletMap = {};
    categoryMap = {};
    defaultWalletId = wallets.length == 1 ? wallets.single.id : null;
    _walletSeen.clear();
    _categorySeen.clear();
    includeDuplicates = false;
    filter = ImportFilter.all;
  }

  @override
  void mapColumn(ImportField field, String? header) {
    final next = {...mapping};
    if (header == null) {
      next.remove(field);
    } else {
      next[field] = header;
    }
    mapping = next;
    _notify();
  }

  @override
  void selectDateFormat(ImportDateFormat value) {
    dateFormat = value;
    _notify();
  }

  @override
  void selectNumberFormat(ImportNumberFormat value) {
    numberFormat = value;
    _notify();
  }

  @override
  Future<void> continueFromColumns() async {
    if (!canContinueColumns || busy) return;
    await _plan(firstLook: true);
  }

  ImportRequest get _request => ImportRequest(
    text: _text,
    source: source,
    dateFormat: source == ImportSource.other ? dateFormat : null,
    numberFormat: source == ImportSource.other ? numberFormat : null,
    mapping: source == ImportSource.other ? mapping : const {},
    walletMap: walletMap,
    categoryMap: categoryMap,
    defaultAccountId: defaultWalletId,
  );

  /// Asks the server for a plan. The first look goes to the mapping screen
  /// when names are left to match, otherwise straight to the preview.
  Future<void> _plan({required bool firstLook}) async {
    final epoch = ++_epoch;
    busy = true;
    failure = null;
    _notify();
    final response = await _useCases.preview(_request);
    if (epoch != _epoch) return;
    busy = false;
    response.fold(_fail, (plan) {
      preview = plan;
      _remember(_walletSeen, plan.unmappedWallets);
      _remember(_categorySeen, plan.unmappedCategories);
      if (firstLook) {
        step = unmappedCount > 0 ? ImportStep.map : ImportStep.preview;
      } else {
        step = ImportStep.preview;
      }
    });
    _notify();
  }

  void _remember(List<String> seen, List<String> names) {
    for (final name in names) {
      if (!seen.contains(name)) seen.add(name);
    }
  }

  @override
  void mapWallet(String name, String walletId) {
    walletMap = {...walletMap, name: walletId};
    _notify();
  }

  @override
  void mapCategory(String name, String categoryId) {
    categoryMap = {...categoryMap, name: categoryId};
    _notify();
  }

  @override
  void selectDefaultWallet(String walletId) {
    defaultWalletId = walletId;
    _notify();
  }

  @override
  Future<void> showPreview() async {
    if (busy) return;
    await _plan(firstLook: false);
  }

  @override
  void selectFilter(ImportFilter value) {
    filter = value;
    _notify();
  }

  @override
  void toggleDuplicates(bool value) {
    includeDuplicates = value;
    _notify();
  }

  @override
  Future<bool> commit() async {
    if (committing || importCount == 0) return false;
    final epoch = _epoch;
    committing = true;
    failure = null;
    _notify();
    final response = await _useCases.commit(
      _request,
      batchClientId: _batchClientId,
      includeDuplicates: includeDuplicates,
    );
    if (epoch != _epoch || _disposed) return false;
    committing = false;
    var written = false;
    response.fold(_fail, (value) {
      result = value;
      step = ImportStep.done;
      written = true;
    });
    _notify();
    return written;
  }

  @override
  Future<int?> undo() async {
    final batch = result?.batch;
    if (batch == null || busy) return null;
    busy = true;
    failure = null;
    _notify();
    final response = await _useCases.undo(batch.id);
    if (_disposed) return null;
    busy = false;
    int? done;
    response.fold(_fail, (value) => done = value.undoneCount);
    _notify();
    return done;
  }

  @override
  bool back() {
    if (busy || committing) return true;
    switch (step) {
      case ImportStep.source:
        return false;
      case ImportStep.columns:
        step = ImportStep.source;
      case ImportStep.map:
        step = source == ImportSource.other
            ? ImportStep.columns
            : ImportStep.source;
      case ImportStep.preview:
        step =
            _walletSeen.isEmpty && _categorySeen.isEmpty && !needsDefaultWallet
            ? (source == ImportSource.other
                  ? ImportStep.columns
                  : ImportStep.source)
            : ImportStep.map;
      case ImportStep.done:
        return false;
    }
    _notify();
    return true;
  }

  /// First header that looks like each field, ignoring case and accents.
  static Map<ImportField, String> _guessColumns(List<String> headers) {
    const hints = {
      ImportField.date: ['ngay', 'date'],
      ImportField.amount: ['so tien', 'sotien', 'amount', 'tien'],
      ImportField.type: ['loai', 'thu chi', 'type'],
      ImportField.category: ['danh muc', 'nhom', 'category'],
      ImportField.wallet: ['vi', 'tai khoan', 'wallet', 'account'],
      ImportField.notes: ['ghi chu', 'ghichu', 'note', 'memo', 'description'],
    };
    final result = <ImportField, String>{};
    for (final entry in hints.entries) {
      for (final hint in entry.value) {
        final match = headers.where((h) => _plain(h) == hint).firstOrNull;
        if (match != null) {
          result[entry.key] = match;
          break;
        }
      }
    }
    return result;
  }

  static String _plain(String value) {
    const from =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const to =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    final lower = value.trim().toLowerCase();
    final out = StringBuffer();
    for (final rune in lower.runes) {
      final ch = String.fromCharCode(rune);
      final at = from.indexOf(ch);
      out.write(at >= 0 ? to[at] : ch);
    }
    return out.toString();
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    super.dispose();
  }
}
