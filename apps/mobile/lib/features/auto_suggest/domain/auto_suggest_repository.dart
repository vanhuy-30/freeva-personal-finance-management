import 'package:dartz/dartz.dart';

import '../../auth/domain/auth_repository.dart';
import 'merchant_mapping.dart';

/// The Gợi ý tự động switch and the merchants learned for category
/// suggestions. The switch value itself is read with the profile.
abstract class AutoSuggestRepository {
  /// Turns category suggestions, insights and the forecast on or off for the
  /// user. Turning it off keeps the remembered merchants.
  Future<Either<AuthFailure, Unit>> setEnabled(bool enabled);

  /// Remembered merchants, newest first.
  Future<Either<AuthFailure, List<MerchantMapping>>> mappings();

  /// Forgets one merchant.
  Future<Either<AuthFailure, Unit>> forget(String id);

  /// Forgets every merchant. Transactions are not touched.
  Future<Either<AuthFailure, Unit>> clear();
}
