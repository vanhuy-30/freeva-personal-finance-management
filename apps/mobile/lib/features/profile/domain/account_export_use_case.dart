import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/domain/auth_repository.dart';
import 'account_file_sharer.dart';

/// Fetches the account export and hands the body, unchanged, to the OS.
@injectable
class AccountExportUseCase {
  AccountExportUseCase(this._auth, this._sharer);
  final AuthRepository _auth;
  final AccountFileSharer _sharer;

  /// Right(true) when shared, Right(false) when the sheet was dismissed.
  Future<Either<AuthFailure, bool>> call(DateTime now) async {
    final body = await _auth.exportAccount();
    return body.fold((e) => Future.value(left(e)), (text) async {
      final d = now.toUtc();
      String two(int n) => n.toString().padLeft(2, '0');
      final name = 'freeva-export-${d.year}${two(d.month)}${two(d.day)}.json';
      try {
        return right(await _sharer.share(name, text));
      } catch (_) {
        return left(const AuthFailure(AuthError.storage));
      }
    });
  }
}
