import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/moment_overlay.dart';
import '../../providers/editor_provider.dart';

/// Renders all freehand drawing strokes as a CustomPainter overlay.
class DrawingCanvas extends StatelessWidget {
  final Size canvasSize;
  final bool isDrawMode;

  const DrawingCanvas({
    super.key,
    required this.canvasSize,
    required this.isDrawMode,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorProvider>(
      builder: (context, provider, _) {
        final drawingOverlay = provider.overlays
            .where((o) => o.type == OverlayType.drawing)
            .firstOrNull;

        final drawPoints = drawingOverlay?.drawPoints ?? [];

        return GestureDetector(
          behavior: isDrawMode ? HitTestBehavior.opaque : HitTestBehavior.translucent,
          onPanStart: isDrawMode
              ? (d) => provider.startDrawStroke(d.localPosition)
              : null,
          onPanUpdate: isDrawMode
              ? (d) => provider.continueDrawStroke(d.localPosition)
              : null,
          onPanEnd: isDrawMode ? (_) => provider.endDrawStroke() : null,
          child: CustomPaint(
            size: canvasSize,
            painter: _DrawingPainter(points: drawPoints, brush: provider.brush),
          ),
        );
      },
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<DrawPoint> points;
  final DrawingBrush brush;

  _DrawingPainter({required this.points, required this.brush});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    Paint? currentPaint;
    Path? currentPath;

    for (int i = 0; i < points.length; i++) {
      final point = points[i];

      if (point.isNewStroke || currentPath == null) {
        // Draw previous path
        if (currentPath != null && currentPaint != null) {
          canvas.drawPath(currentPath, currentPaint);
        }

        currentPaint = Paint()
          ..color = point.color
          ..strokeWidth = point.strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke
          ..blendMode = point.color == Colors.transparent
              ? BlendMode.clear
              : BlendMode.srcOver;

        // Add neon glow for bright colors
        if (_isNeonColor(point.color)) {
          currentPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        }

        currentPath = Path()..moveTo(point.point.dx, point.point.dy);
      } else {
        currentPath.lineTo(point.point.dx, point.point.dy);
      }
    }

    // Draw the last path
    if (currentPath != null && currentPaint != null) {
      canvas.drawPath(currentPath, currentPaint);
    }
  }

  bool _isNeonColor(Color c) {
    return c == Colors.cyanAccent ||
        c == Colors.greenAccent ||
        c == Colors.pinkAccent ||
        c == Colors.yellowAccent;
  }

  @override
  bool shouldRepaint(_DrawingPainter old) => old.points != points;
}
