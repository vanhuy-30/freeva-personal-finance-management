import 'dart:typed_data';

enum AvatarSource { camera, library }

/// Lets the person take or choose a photo. Null when they back out (or, for
/// the camera, refuse access or have none).
abstract class AvatarPicker {
  Future<Uint8List?> pick(AvatarSource source);
}
