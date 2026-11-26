import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../auth/domain/auth_repository.dart';

/// The profile photo on the account: one small JPEG.
abstract class AvatarRepository {
  /// The photo, or null when the account has none.
  Future<Either<AuthFailure, Uint8List?>> load();

  /// Replaces the photo with [jpeg] (already resized, see [prepareAvatar]).
  Future<Either<AuthFailure, Unit>> save(Uint8List jpeg);

  Future<Either<AuthFailure, Unit>> remove();
}
