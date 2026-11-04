import 'package:dartz/dartz.dart';
import 'package:mobile/core/money/display_converted.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/fx_rates/domain/fx_rate.dart';
import 'package:mobile/features/fx_rates/domain/fx_rate_repository.dart';
import 'package:mobile/features/wallets/domain/wallet.dart';
import 'package:mobile/features/wallets/domain/wallet_repository.dart';

import '../home/fixtures.dart' show wallet;

/// Wallets of the given currencies (an archived one counts too). Defaults to
/// two currencies so converted lines are allowed.
class FxWallets implements WalletRepository {
  FxWallets([this.codes = const ['VND', 'USD']]);

  final List<String> codes;
  AuthFailure? failure;

  @override
  Future<Either<AuthFailure, List<Wallet>>> load() async => failure != null
      ? left(failure!)
      : right([
          for (var i = 0; i < codes.length; i++)
            wallet('w$i', 'W$i', currency: codes[i], archived: i > 0),
        ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// In-memory rates. [wallet] and [transaction] are what the server would
/// send as `converted`, by id; a missing id means no exact conversion.
class MemoryFxRates implements FxRateRepository {
  final saved = <String>[];
  final wallet = <String, DisplayConverted>{};
  final transaction = <String, DisplayConverted>{};
  AuthFailure? failure;

  @override
  Future<Either<AuthFailure, List<FxRate>>> list() async => right(const []);

  @override
  Future<Either<AuthFailure, FxRate>> put(
    String from,
    String to,
    String rate,
  ) async {
    if (failure != null) return left(failure!);
    saved.add('$from>$to=$rate');
    return right(
      FxRate(from: from, to: to, rate: rate, quotedAt: DateTime(2026, 10, 30)),
    );
  }

  @override
  Future<Either<AuthFailure, Unit>> remove(String from, String to) async =>
      right(unit);

  @override
  Future<Either<AuthFailure, DisplayConverted?>> walletConverted(
    String id,
  ) async => failure != null ? left(failure!) : right(wallet[id]);

  @override
  Future<Either<AuthFailure, DisplayConverted?>> transactionConverted(
    String legId,
  ) async => failure != null ? left(failure!) : right(transaction[legId]);
}
