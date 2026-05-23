import 'package:flutter/material.dart';

/// Types of overlays that can be added to a moment
enum OverlayType { emoji, text, gif, sticker, drawing }

/// Text style preset names
enum TextStylePreset { normal, neon, glow, dark, white, gradient }

/// Represents a single point in a drawing stroke
class DrawPoint {
  final Offset point;
  final Color color;
  final double strokeWidth;
  final bool isNewStroke; // true = start of a new stroke

  const DrawPoint({
    required this.point,
    required this.color,
    required this.strokeWidth,
    this.isNewStroke = false,
  });

  DrawPoint copyWith({
    Offset? point,
    Color? color,
    double? strokeWidth,
    bool? isNewStroke,
  }) {
    return DrawPoint(
      point: point ?? this.point,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      isNewStroke: isNewStroke ?? this.isNewStroke,
    );
  }
}

/// A single overlay element placed on the moment image
class MomentOverlay {
  final String id;
  final OverlayType type;

  /// Content:
  /// - emoji: the emoji character e.g. "😊"
  /// - text: the text string
  /// - gif: the GIF URL
  /// - sticker: the sticker emoji/character
  /// - drawing: not used (drawing uses drawPoints)
  final String content;

  /// Position as fraction of the canvas (0.0 - 1.0)
  Offset position;

  /// Scale multiplier (1.0 = original size)
  double scale;

  /// Rotation in radians
  double rotation;

  // ── Text-specific fields ──────────────────────────────────────────
  Color? color;
  double? fontSize;
  bool bold;
  bool italic;
  bool hasShadow;
  TextStylePreset textStylePreset;
  TextAlign textAlign;

  // ── Drawing layer ─────────────────────────────────────────────────
  List<DrawPoint>? drawPoints;

  MomentOverlay({
    required this.id,
    required this.type,
    required this.content,
    required this.position,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.color,
    this.fontSize,
    this.bold = false,
    this.italic = false,
    this.hasShadow = false,
    this.textStylePreset = TextStylePreset.normal,
    this.textAlign = TextAlign.center,
    this.drawPoints,
  });

  MomentOverlay copyWith({
    String? content,
    Offset? position,
    double? scale,
    double? rotation,
    Color? color,
    double? fontSize,
    bool? bold,
    bool? italic,
    bool? hasShadow,
    TextStylePreset? textStylePreset,
    TextAlign? textAlign,
    List<DrawPoint>? drawPoints,
  }) {
    return MomentOverlay(
      id: id,
      type: type,
      content: content ?? this.content,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      color: color ?? this.color,
      fontSize: fontSize ?? this.fontSize,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      hasShadow: hasShadow ?? this.hasShadow,
      textStylePreset: textStylePreset ?? this.textStylePreset,
      textAlign: textAlign ?? this.textAlign,
      drawPoints: drawPoints ?? this.drawPoints,
    );
  }
}

/// Current drawing brush state
class DrawingBrush {
  final Color color;
  final double strokeWidth;
  final bool isEraser;

  const DrawingBrush({
    this.color = Colors.white,
    this.strokeWidth = 4.0,
    this.isEraser = false,
  });

  DrawingBrush copyWith({Color? color, double? strokeWidth, bool? isEraser}) {
    return DrawingBrush(
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      isEraser: isEraser ?? this.isEraser,
    );
  }
}
