import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Renders the editor canvas (RepaintBoundary) into Uint8List PNG bytes.
class ImageComposer {
  /// Captures the widget tree under [repaintKey] and returns PNG bytes.
  /// [pixelRatio] controls output resolution (3.0 = 3x device pixels).
  static Future<List<int>> compose({
    required GlobalKey repaintKey,
    double pixelRatio = 3.0,
  }) async {
    final context = repaintKey.currentContext;
    if (context == null) throw Exception('RepaintBoundary context is null');

    final boundary = context.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) throw Exception('Could not find RenderRepaintBoundary');

    // Wait for any pending frames
    await Future.delayed(const Duration(milliseconds: 50));

    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) throw Exception('Failed to convert image to bytes');
    return byteData.buffer.asUint8List();
  }
}
