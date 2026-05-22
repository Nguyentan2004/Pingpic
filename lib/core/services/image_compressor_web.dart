import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

/// High performance image compressor using browser HTML5 Canvas for Flutter Web.
Future<Uint8List> compressAndResizeImage(
  Uint8List bytes, {
  int maxWidth = 1080,
  int maxHeight = 1080,
  int quality = 70,
}) async {
  final completer = Completer<Uint8List>();

  try {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    final image = html.ImageElement();
    image.src = url;

    StreamSubscription? loadSub;
    StreamSubscription? errorSub;

    void cleanup() {
      loadSub?.cancel();
      errorSub?.cancel();
      html.Url.revokeObjectUrl(url);
    }

    loadSub = image.onLoad.listen((_) {
      try {
        int width = image.naturalWidth;
        int height = image.naturalHeight;

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

        final canvas = html.CanvasElement(width: width, height: height);
        final ctx = canvas.context2D;
        
        // Draw image scaled onto canvas
        ctx.drawImageScaled(image, 0, 0, width, height);

        // Export canvas to JPEG format with specified compression quality
        canvas.toBlob('image/jpeg', quality / 100).then((blob) {
          final reader = html.FileReader();
          reader.readAsArrayBuffer(blob);
          reader.onLoadEnd.listen((_) {
            cleanup();
            if (reader.result != null) {
              final res = reader.result;
              if (res is Uint8List) {
                completer.complete(res);
              } else if (res is ByteBuffer) {
                completer.complete(res.asUint8List());
              } else {
                completer.complete(bytes);
              }
            } else {
              completer.complete(bytes);
            }
          });
        }).catchError((err) {
          cleanup();
          completer.complete(bytes); // Fallback to original bytes on error
        });
      } catch (e) {
        cleanup();
        completer.complete(bytes); // Fallback to original bytes on exception
      }
    });

    errorSub = image.onError.listen((_) {
      cleanup();
      completer.complete(bytes); // Fallback to original bytes
    });
  } catch (e) {
    completer.complete(bytes); // Fallback to original bytes
  }

  return completer.future;
}
