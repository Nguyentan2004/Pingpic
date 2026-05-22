import 'dart:typed_data';

/// Stub function for compressing and resizing images.
/// Supported platforms will override this via conditional imports.
Future<Uint8List> compressAndResizeImage(
  Uint8List bytes, {
  int maxWidth = 1080,
  int maxHeight = 1080,
  int quality = 70,
}) async {
  // Return original bytes as a fallback
  return bytes;
}
