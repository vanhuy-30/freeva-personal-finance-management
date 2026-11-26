import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Longest the API accepts (`AVATAR_MAX_BYTES`).
const avatarMaxBytes = 65536;

/// Side of the square photo kept on the account: sharp at 96 pt on a 3×
/// screen, about 20 KB as a JPEG.
const avatarSide = 320;

/// Centre square of [source] (any format the phone gives: JPEG, PNG, WebP…),
/// scaled to [avatarSide] and saved as a JPEG under [avatarMaxBytes]. Null when
/// the bytes are not a picture. Run it off the UI thread: it decodes pixels.
Uint8List? prepareAvatar(Uint8List source) {
  final decoded = img.decodeImage(source);
  if (decoded == null) return null;
  final baked = img.bakeOrientation(decoded);
  final side = baked.width < baked.height ? baked.width : baked.height;
  final square = img.copyCrop(
    baked,
    x: (baked.width - side) ~/ 2,
    y: (baked.height - side) ~/ 2,
    width: side,
    height: side,
  );
  final fitted = side > avatarSide
      ? img.copyResize(
          square,
          width: avatarSide,
          height: avatarSide,
          interpolation: img.Interpolation.average,
        )
      : square;
  for (final quality in const [85, 70, 55, 40]) {
    final jpeg = Uint8List.fromList(img.encodeJpg(fitted, quality: quality));
    if (jpeg.length <= avatarMaxBytes) return jpeg;
  }
  return null;
}
