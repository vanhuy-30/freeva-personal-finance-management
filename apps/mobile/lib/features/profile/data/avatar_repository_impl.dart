import 'dart:convert';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/data/authorized_api.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/avatar_repository.dart';

@LazySingleton(as: AvatarRepository)
class AvatarRepositoryImpl implements AvatarRepository {
  AvatarRepositoryImpl(this._api);

  final AuthorizedApi _api;

  @override
  Future<Either<AuthFailure, Uint8List?>> load() async {
    // The profile says whether there is a photo, so "none" is not a failed call.
    final profile = await _api.request('GET', 'profile');
    return profile.fold(left, (json) async {
      if (json['avatarUpdatedAt'] is! String) return right(null);
      final photo = await _api.request('GET', 'profile/avatar');
      return photo.fold(left, (body) {
        try {
          return right(base64Decode(body['imageBase64'] as String));
        } catch (_) {
          return left(const AuthFailure(AuthError.unavailable));
        }
      });
    });
  }

  @override
  Future<Either<AuthFailure, Unit>> save(Uint8List jpeg) async =>
      (await _api.request(
        'PUT',
        'profile/avatar',
        body: {'imageBase64': base64Encode(jpeg)},
      )).map((_) => unit);

  @override
  Future<Either<AuthFailure, Unit>> remove() async =>
      (await _api.request('DELETE', 'profile/avatar')).map((_) => unit);
}
