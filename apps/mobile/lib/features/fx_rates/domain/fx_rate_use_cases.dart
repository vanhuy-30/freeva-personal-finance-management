import 'package:injectable/injectable.dart';

import '../../../core/money/display_converted.dart';
import 'fx_rate_repository.dart';

/// Converted amounts for detail screens. Display only and best effort: a
/// failure or a missing rate just means no converted line.
@injectable
class FxRateUseCases {
  FxRateUseCases(this._repository);

  final FxRateRepository _repository;

  Future<DisplayConverted?> walletConverted(String walletId) async =>
      (await _repository.walletConverted(walletId)).fold((_) => null, (v) => v);

  Future<DisplayConverted?> transactionConverted(String legId) async =>
      (await _repository.transactionConverted(legId)).fold(
        (_) => null,
        (v) => v,
      );
}
