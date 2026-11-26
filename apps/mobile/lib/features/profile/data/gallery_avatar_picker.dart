import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';

import '../domain/avatar_picker.dart';

@LazySingleton(as: AvatarPicker)
class GalleryAvatarPicker implements AvatarPicker {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<Uint8List?> pick(AvatarSource source) async {
    // Shrunk here already so a 48-megapixel photo never reaches the decoder.
    try {
      final file = await _picker.pickImage(
        source: switch (source) {
          AvatarSource.camera => ImageSource.camera,
          AvatarSource.library => ImageSource.gallery,
        },
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1024,
        maxHeight: 1024,
        // Only the pixels are needed. With the default (true) iOS asks for
        // access to the whole photo library; false keeps the system picker,
        // which needs no permission.
        requestFullMetadata: false,
      );
      return await file?.readAsBytes();
    } on PlatformException {
      // Camera refused or missing: same as backing out.
      return null;
    }
  }
}
