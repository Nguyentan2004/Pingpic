import 'dart:typed_data';

/// Fallback for mobile and desktop.
/// On native platforms, [ImagePicker] already implements maxWidth, maxHeight, and imageQuality constraints.
Future<Uint8List> compressAndResizeImage(
  Uint8List bytes, {
  int maxWidth = 1080,
  int maxHeight = 1080,
  int quality = 70,
}) async {
  // Mobile platform image picker already applies constraints, so return as is.
  return bytes;
}
