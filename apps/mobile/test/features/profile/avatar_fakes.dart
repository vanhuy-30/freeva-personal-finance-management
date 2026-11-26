import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:image/image.dart' as img;
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/profile/domain/avatar_image.dart';
import 'package:mobile/features/profile/domain/avatar_picker.dart';
import 'package:mobile/features/profile/domain/avatar_repository.dart';
import 'package:mobile/features/profile/presentation/viewmodels/avatar_view_model.dart';

/// A real picture of [width]×[height] as PNG bytes, to feed the resizer.
Uint8List samplePicture({int width = 800, int height = 600}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(30, 120, 220));
  return Uint8List.fromList(img.encodePng(image));
}

class FakeAvatarRepository implements AvatarRepository {
  Uint8List? stored;
  AuthFailure? failure;
  int loads = 0;
  final saved = <Uint8List>[];

  @override
  Future<Either<AuthFailure, Uint8List?>> load() async {
    loads++;
    return failure == null ? right(stored) : left(failure!);
  }

  @override
  Future<Either<AuthFailure, Unit>> save(Uint8List jpeg) async {
    if (failure != null) return left(failure!);
    saved.add(jpeg);
    stored = jpeg;
    return right(unit);
  }

  @override
  Future<Either<AuthFailure, Unit>> remove() async {
    if (failure != null) return left(failure!);
    stored = null;
    return right(unit);
  }
}

class FakeAvatarPicker implements AvatarPicker {
  Uint8List? next;
  int calls = 0;
  AvatarSource? lastSource;

  @override
  Future<Uint8List?> pick(AvatarSource source) async {
    calls++;
    lastSource = source;
    return next;
  }
}

AvatarViewModel avatarViewModel(
  AuthViewModel auth, {
  FakeAvatarRepository? repository,
  FakeAvatarPicker? picker,
}) => AvatarViewModel(
  repository ?? FakeAvatarRepository(),
  picker ?? FakeAvatarPicker(),
  auth,
  prepare: (bytes) async => prepareAvatar(bytes),
);
