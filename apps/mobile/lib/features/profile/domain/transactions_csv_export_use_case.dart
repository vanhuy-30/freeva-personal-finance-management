import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/domain/auth_repository.dart';
import '../../transactions/domain/transaction_filter.dart';
import 'account_file_sharer.dart';

/// Most rows the API exports in one file (`CSV_EXPORT_MAX_ROWS`).
const csvExportMaxRows = 50000;

/// `MOB-P3-010`: downloads the transactions CSV for a date range and wallets
/// and hands it, bytes unchanged, to the OS.
@injectable
class TransactionsCsvExportUseCase {
  TransactionsCsvExportUseCase(this._auth, this._sharer);
  final AuthRepository _auth;
  final AccountFileSharer _sharer;

  /// Right(true) when shared, Right(false) when the sheet was dismissed.
  Future<Either<AuthFailure, bool>> call({
    required DateTime now,
    DateRange? range,
    Set<String> accountIds = const {},
  }) async {
    final query = [
      if (range != null) 'from=${range.from}&to=${range.to}',
      for (final id in accountIds.toList()..sort())
        'accountId=${Uri.encodeQueryComponent(id)}',
    ].join('&');
    final body = await _auth.exportTransactionsCsv(query);
    return body.fold((e) => Future.value(left(e)), (bytes) async {
      try {
        return right(
          await _sharer.shareBytes(
            exportFileName('freeva-transactions', 'csv', now),
            bytes,
            'text/csv',
          ),
        );
      } catch (_) {
        return left(const AuthFailure(AuthError.storage));
      }
    });
  }
}
