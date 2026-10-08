import 'package:dartz/dartz.dart';

import '../../auth/domain/auth_repository.dart';
import 'transaction.dart';

abstract class TransactionRepository {
  Future<Either<AuthFailure, TransactionListPage>> list(TransactionQuery query);
  Future<Either<AuthFailure, TransactionBundle>> read(String id);
  Future<Either<AuthFailure, TransactionBundle>> create(
    TransactionCommand command,
  );
  Future<Either<AuthFailure, TransactionBundle>> update(
    String id,
    TransactionCommand command,
  );
  Future<Either<AuthFailure, Unit>> remove(String id, int version);
  Future<Either<AuthFailure, TransactionBundle>> restore(
    String id,
    int version,
  );
}
