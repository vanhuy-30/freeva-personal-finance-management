import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/domain/auth_repository.dart';
import 'import_models.dart';
import 'import_repository.dart';

/// `MOB-P3-011`: plan, write and undo a CSV import.
abstract class ImportUseCases {
  Future<Either<AuthFailure, ImportPreview>> preview(ImportRequest request);
  Future<Either<AuthFailure, ImportResult>> commit(
    ImportRequest request, {
    required String batchClientId,
    required bool includeDuplicates,
  });
  Future<Either<AuthFailure, ImportUndo>> undo(String batchId);
}

@LazySingleton(as: ImportUseCases)
class DefaultImportUseCases implements ImportUseCases {
  DefaultImportUseCases(this._repository);
  final ImportRepository _repository;

  @override
  Future<Either<AuthFailure, ImportPreview>> preview(ImportRequest request) =>
      _repository.preview(request);

  @override
  Future<Either<AuthFailure, ImportResult>> commit(
    ImportRequest request, {
    required String batchClientId,
    required bool includeDuplicates,
  }) => _repository.commit(
    request,
    batchClientId: batchClientId,
    includeDuplicates: includeDuplicates,
  );

  @override
  Future<Either<AuthFailure, ImportUndo>> undo(String batchId) =>
      _repository.undo(batchId);
}
