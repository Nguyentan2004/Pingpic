import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';
import '../../../data/models/moment_overlay.dart';
import '../../providers/editor_provider.dart';

/// Wraps a single overlay with drag, pinch-to-zoom, rotate, and delete.
class DraggableOverlay extends StatefulWidget {
  final MomentOverlay overlay;
  final Size canvasSize;

  const DraggableOverlay({
    super.key,
    required this.overlay,
    required this.canvasSize,
  });

  @override
  State<DraggableOverlay> createState() => _DraggableOverlayState();
}

class _DraggableOverlayState extends State<DraggableOverlay> {
  // Track gesture start values for delta calculations
  double _startScale = 1.0;
  double _startRotation = 0.0;
  Offset _startFocalPoint = Offset.zero;
  Offset _startPosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditorProvider>();
    final isSelected = provider.selectedId == widget.overlay.id;
    final overlay = widget.overlay;
    final cs = widget.canvasSize;

    // Convert normalized position to pixel
    final pixelPos = Offset(overlay.position.dx * cs.width, overlay.position.dy * cs.height);

    return Positioned(
      left: pixelPos.dx - _overlayWidth(overlay) / 2,
      top: pixelPos.dy - _overlayHeight(overlay) / 2,
      child: Listener(
        onPointerSignal: (pointerSignal) {
          if (pointerSignal is PointerScrollEvent) {
            final dy = pointerSignal.scrollDelta.dy;
            if (dy != 0) {
              // Auto-select this overlay and bring to front
              provider.selectOverlay(overlay.id);
              provider.bringToFront(overlay.id);

              final double scaleChange = dy > 0 ? 0.95 : 1.05;
              final newScale = (overlay.scale * scaleChange).clamp(0.2, 5.0);

              provider.updateOverlayTransform(
                overlay.id,
                scale: newScale,
              );
            }
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            provider.selectOverlay(overlay.id);
            provider.bringToFront(overlay.id);
          },
          onDoubleTap: overlay.type == OverlayType.text
              ? () => _openTextEditor(context, overlay)
              : null,
          onScaleStart: (details) {
            _startScale = overlay.scale;
            _startRotation = overlay.rotation;
            _startFocalPoint = details.focalPoint;
            _startPosition = pixelPos;
            provider.selectOverlay(overlay.id);
            provider.bringToFront(overlay.id);
          },
          onScaleUpdate: (details) {
            // Pan: move with focal point delta
            final delta = details.focalPoint - _startFocalPoint;
            final newPixelPos = _startPosition + delta;
            final newNorm = Offset(
              (newPixelPos.dx / cs.width).clamp(0.0, 1.0),
              (newPixelPos.dy / cs.height).clamp(0.0, 1.0),
            );

            // Scale & rotate
            final newScale = (_startScale * details.scale).clamp(0.2, 5.0);
            final newRotation = _startRotation + details.rotation;

            provider.updateOverlayTransform(
              overlay.id,
              position: newNorm,
              scale: newScale,
              rotation: newRotation,
            );
          },
          child: Transform.rotate(
            angle: overlay.rotation,
            child: Transform.scale(
              scale: overlay.scale,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // The overlay content
                  _buildContent(overlay),

                  // Selection border + delete button
                  if (isSelected) ...[
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white.withAlpha(200),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    // Delete button (top-right)
                    Positioned(
                      top: -14,
                      right: -14,
                      child: GestureDetector(
                        onTap: () => provider.deleteOverlay(overlay.id),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(MomentOverlay overlay) {
    switch (overlay.type) {
      case OverlayType.emoji:
      case OverlayType.sticker:
        return Text(
          overlay.content,
          style: TextStyle(fontSize: (overlay.fontSize ?? 48)),
          textAlign: TextAlign.center,
        );

      case OverlayType.text:
        return _buildTextContent(overlay);

      case OverlayType.gif:
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            overlay.content,
            width: 160,
            height: 160,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              width: 120,
              height: 80,
              color: Colors.black26,
              child: const Icon(Icons.gif_box_rounded, color: Colors.white, size: 40),
            ),
          ),
        );

      case OverlayType.drawing:
        return const SizedBox.shrink(); // Drawing is rendered by DrawingCanvas
    }
  }

  Widget _buildTextContent(MomentOverlay overlay) {
    final style = _buildTextStyle(overlay);
    final text = Text(
      overlay.content,
      textAlign: overlay.textAlign,
      style: style,
    );

    switch (overlay.textStylePreset) {
      case TextStylePreset.neon:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: text,
        );
      case TextStylePreset.dark:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(180),
            borderRadius: BorderRadius.circular(8),
          ),
          child: text,
        );
      case TextStylePreset.white:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(220),
            borderRadius: BorderRadius.circular(8),
          ),
          child: text,
        );
      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: text,
        );
    }
  }

  TextStyle _buildTextStyle(MomentOverlay overlay) {
    Color textColor = overlay.color ?? Colors.white;
    List<Shadow>? shadows;

    switch (overlay.textStylePreset) {
      case TextStylePreset.neon:
        textColor = overlay.color ?? Colors.cyanAccent;
        shadows = [
          Shadow(color: textColor.withAlpha(200), blurRadius: 8),
          Shadow(color: textColor.withAlpha(120), blurRadius: 20),
          Shadow(color: textColor.withAlpha(60), blurRadius: 40),
        ];
      case TextStylePreset.glow:
        textColor = overlay.color ?? Colors.white;
        shadows = [
          Shadow(color: Colors.white.withAlpha(200), blurRadius: 12),
          Shadow(color: Colors.white.withAlpha(80), blurRadius: 30),
        ];
      case TextStylePreset.dark:
        textColor = Colors.white;
      case TextStylePreset.white:
        textColor = Colors.black87;
      default:
        if (overlay.hasShadow) {
          shadows = [
            const Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(1, 1)),
          ];
        }
    }

    return TextStyle(
      color: textColor,
      fontSize: overlay.fontSize ?? 28,
      fontWeight: overlay.bold ? FontWeight.bold : FontWeight.w600,
      fontStyle: overlay.italic ? FontStyle.italic : FontStyle.normal,
      shadows: shadows,
      height: 1.2,
    );
  }

  double _overlayWidth(MomentOverlay overlay) {
    switch (overlay.type) {
      case OverlayType.emoji:
      case OverlayType.sticker:
        return (overlay.fontSize ?? 48) + 16;
      case OverlayType.text:
        return 200;
      case OverlayType.gif:
        return 160;
      default:
        return 80;
    }
  }

  double _overlayHeight(MomentOverlay overlay) {
    switch (overlay.type) {
      case OverlayType.emoji:
      case OverlayType.sticker:
        return (overlay.fontSize ?? 48) + 16;
      case OverlayType.text:
        return 60;
      case OverlayType.gif:
        return 160;
      default:
        return 80;
    }
  }

  void _openTextEditor(BuildContext context, MomentOverlay overlay) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuickTextEditSheet(overlay: overlay),
    );
  }
}

/// Quick inline text editor shown on double-tap
class _QuickTextEditSheet extends StatefulWidget {
  final MomentOverlay overlay;
  const _QuickTextEditSheet({required this.overlay});

  @override
  State<_QuickTextEditSheet> createState() => _QuickTextEditSheetState();
}

class _QuickTextEditSheetState extends State<_QuickTextEditSheet> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.overlay.content);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _ctrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter text...',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.read<EditorProvider>().updateTextOverlay(
                    widget.overlay.id,
                    widget.overlay.copyWith(content: _ctrl.text),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Done', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
