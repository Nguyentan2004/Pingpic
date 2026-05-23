import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Real JPEG image compressor using pure Dart 'image' package on mobile/desktop.
Future<Uint8List> compressAndResizeImage(
  Uint8List bytes, {
  int maxWidth = 1080,
  int maxHeight = 1080,
  int quality = 70,
}) async {
  try {
    final image = img.decodeImage(bytes);
    if (image == null) return bytes;

    int width = image.width;
    int height = image.height;

    // Only resize if the image exceeds the maximum dimensions
    if (width > maxWidth || height > maxHeight) {
      final double aspectRatio = width / height;
      if (width > height) {
        width = maxWidth;
        height = (maxWidth / aspectRatio).round();
      } else {
        height = maxHeight;
        width = (maxHeight * aspectRatio).round();
      }
    }

    final resizedImage = img.copyResize(
      image,
      width: width,
      height: height,
      interpolation: img.Interpolation.linear,
    );
    final compressed = img.encodeJpg(resizedImage, quality: quality);
    return Uint8List.fromList(compressed);
  } catch (e) {
    return bytes;
  }
}
