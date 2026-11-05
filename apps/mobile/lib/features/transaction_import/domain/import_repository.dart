import 'package:dartz/dartz.dart';

import '../../auth/domain/auth_repository.dart';
import 'import_models.dart';

abstract class ImportRepository {
  /// Plans the import without writing anything.
  Future<Either<AuthFailure, ImportPreview>> preview(ImportRequest request);

  /// Writes the ready rows as one batch. Repeating [batchClientId] is safe:
  /// the stored batch comes back and nothing is written twice.
  Future<Either<AuthFailure, ImportResult>> commit(
    ImportRequest request, {
    required String batchClientId,
    required bool includeDuplicates,
  });

  Future<Either<AuthFailure, ImportUndo>> undo(String batchId);
}
