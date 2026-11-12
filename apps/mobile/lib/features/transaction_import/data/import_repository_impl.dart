import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/data/authorized_api.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/import_models.dart';
import '../domain/import_repository.dart';

@LazySingleton(as: ImportRepository)
class ImportRepositoryImpl implements ImportRepository {
  ImportRepositoryImpl(this._api);
  final AuthorizedApi _api;

  static Map<String, dynamic> body(ImportRequest request) => {
    'text': request.text,
    'preset': request.source.apiName,
    if (request.dateFormat != null) 'dateFormat': request.dateFormat!.apiName,
    if (request.numberFormat != null)
      'numberFormat': request.numberFormat!.apiName,
    if (request.mapping.isNotEmpty)
      'mapping': {
        for (final entry in request.mapping.entries)
          entry.key.apiName: entry.value,
      },
    if (request.walletMap.isNotEmpty) 'walletMap': request.walletMap,
    if (request.categoryMap.isNotEmpty) 'categoryMap': request.categoryMap,
    if (request.defaultAccountId != null)
      'defaultAccountId': request.defaultAccountId,
    if (request.rowCategoryMap.isNotEmpty)
      'rowCategoryMap': {
        for (final entry in request.rowCategoryMap.entries)
          '${entry.key}': entry.value,
      },
    if (request.merchantCategoryMap.isNotEmpty)
      'merchantCategoryMap': request.merchantCategoryMap,
  };

  static ImportSuggestion? parseSuggestion(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final category = raw['category'] as Map<String, dynamic>;
    return ImportSuggestion(
      categoryId: category['id'] as String,
      categoryName: category['name'] as String,
      iconToken: category['iconToken'] as String?,
      colorToken: category['colorToken'] as String?,
      source: ImportSuggestionSource.parse(raw['source'] as String),
      matchCount: raw['matchCount'] as int? ?? 0,
    );
  }

  static ImportRow parseRow(Map<String, dynamic> json) => ImportRow(
    rows: [for (final n in json['rows'] as List) n as int],
    status: ImportRowStatus.parse(json['status'] as String),
    errors: [
      for (final code in json['errors'] as List)
        ImportRowError.parse(code as String),
    ],
    type: json['type'] as String?,
    occurredOn: json['occurredOn'] as String?,
    amountMinor: json['amountMinor'] == null
        ? null
        : BigInt.parse(json['amountMinor'] as String),
    currencyCode: json['currencyCode'] as String?,
    merchant: json['merchant'] as String?,
    notes: json['notes'] as String?,
    accountId: json['accountId'] as String?,
    categoryId: json['categoryId'] as String?,
    suggestion: parseSuggestion(json['suggestion']),
  );

  static List<ImportRow> _rows(Object? raw) => [
    for (final row in raw as List) parseRow(row as Map<String, dynamic>),
  ];

  static ImportBatch parseBatch(Map<String, dynamic> json) => ImportBatch(
    id: json['id'] as String,
    createdCount: json['createdCount'] as int,
    duplicateCount: json['duplicateCount'] as int,
    invalidCount: json['invalidCount'] as int,
    remainingCount: json['remainingCount'] as int,
    undone: json['undoneAt'] != null,
  );

  static ImportPreview parsePreview(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>;
    final unmapped = json['unmapped'] as Map<String, dynamic>;
    return ImportPreview(
      summary: ImportSummary(
        rowCount: summary['rowCount'] as int,
        ready: summary['ready'] as int,
        duplicate: summary['duplicate'] as int,
        invalid: summary['invalid'] as int,
        suggested: summary['suggested'] as int? ?? 0,
      ),
      unmappedWallets: [
        for (final n in unmapped['wallets'] as List) n as String,
      ],
      unmappedCategories: [
        for (final n in unmapped['categories'] as List) n as String,
      ],
      rows: _rows(json['rows']),
      columns: {
        for (final e in (json['columns'] as Map<String, dynamic>).entries)
          e.key: e.value as String,
      },
    );
  }

  Future<Either<AuthFailure, T>> _send<T>(
    String path,
    Map<String, dynamic> payload,
    T Function(Map<String, dynamic>) parse,
  ) async {
    final result = await _api.request('POST', path, body: payload);
    return result.fold(left, (json) {
      try {
        return right(parse(json));
      } catch (_) {
        return left(const AuthFailure(AuthError.unavailable));
      }
    });
  }

  @override
  Future<Either<AuthFailure, ImportPreview>> preview(ImportRequest request) =>
      _send('transactions/import/preview', body(request), parsePreview);

  @override
  Future<Either<AuthFailure, ImportResult>> commit(
    ImportRequest request, {
    required String batchClientId,
    required bool includeDuplicates,
  }) => _send(
    'transactions/import',
    {
      ...body(request),
      'batchClientId': batchClientId,
      'includeDuplicates': includeDuplicates,
    },
    (json) => ImportResult(
      batch: parseBatch(json['batch'] as Map<String, dynamic>),
      rows: json['rows'] == null ? null : _rows(json['rows']),
    ),
  );

  @override
  Future<Either<AuthFailure, ImportUndo>> undo(String batchId) => _send(
    'transactions/import/$batchId/undo',
    const {},
    (json) => ImportUndo(
      batch: parseBatch(json['batch'] as Map<String, dynamic>),
      undoneCount: json['undoneCount'] as int,
    ),
  );
}
