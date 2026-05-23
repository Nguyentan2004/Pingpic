import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/image_composer.dart';
import '../../../data/models/moment_overlay.dart';
import '../../providers/editor_provider.dart';
import '../../widgets/editor/drawing_canvas.dart';
import '../../widgets/editor/draggable_overlay.dart';
import '../../widgets/editor/emoji_picker_panel.dart';
import '../../widgets/editor/gif_picker_panel.dart';
import '../../widgets/editor/sticker_picker_panel.dart';
import '../../widgets/editor/text_editor_panel.dart';

/// Full-screen Locket-style moment editor.
/// Returns final composited [Uint8List] via [Navigator.pop].
class MomentEditorPage extends StatefulWidget {
  final Uint8List imageBytes;

  const MomentEditorPage({super.key, required this.imageBytes});

  @override
  State<MomentEditorPage> createState() => _MomentEditorPageState();
}

class _MomentEditorPageState extends State<MomentEditorPage> {
  final _repaintKey = GlobalKey();
  bool _isExporting = false;
  bool _isSquareMode = false;
  double _imageAspectRatio = 1.0;
  final TransformationController _transformationController = TransformationController();

  static const _brushColors = [
    Colors.white,
    Colors.black,
    Colors.red,
    Colors.cyanAccent,
    Colors.yellowAccent,
    Colors.greenAccent,
    Colors.pinkAccent,
    Colors.orangeAccent,
  ];

  @override
  void initState() {
    super.initState();
    _loadImageAspectRatio();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _loadImageAspectRatio() {
    decodeImageFromList(widget.imageBytes).then((image) {
      if (mounted) {
        setState(() {
          _imageAspectRatio = image.width / image.height;
        });
      }
    });
  }

  Future<void> _handleDone(BuildContext innerContext) async {
    setState(() => _isExporting = true);
    try {
      // Deselect all overlays before capturing
      innerContext.read<EditorProvider>().selectOverlay(null);
      await Future.delayed(const Duration(milliseconds: 100));

      final bytes = await ImageComposer.compose(
        repaintKey: _repaintKey,
        pixelRatio: 3.0,
      );
      if (mounted) {
        Navigator.of(context).pop(Uint8List.fromList(bytes));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPanel(BuildContext context, Widget panel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black38,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<EditorProvider>(),
        child: panel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditorProvider(),
      child: Builder(
        builder: (innerContext) {
          return _EditorBody(
            imageBytes: widget.imageBytes,
            repaintKey: _repaintKey,
            isExporting: _isExporting,
            onDone: () => _handleDone(innerContext),
            onCancel: () => Navigator.of(context).pop(),
            onShowPanel: _showPanel,
            brushColors: _brushColors,
            isSquareMode: _isSquareMode,
            imageAspectRatio: _imageAspectRatio,
            transformationController: _transformationController,
            onToggleSquareMode: () {
              setState(() {
                _isSquareMode = !_isSquareMode;
                _transformationController.value = Matrix4.identity();
              });
            },
          );
        },
      ),
    );
  }
}

class _EditorBody extends StatelessWidget {
  final Uint8List imageBytes;
  final GlobalKey repaintKey;
  final bool isExporting;
  final VoidCallback onDone;
  final VoidCallback onCancel;
  final void Function(BuildContext, Widget) onShowPanel;
  final List<Color> brushColors;
  final bool isSquareMode;
  final double imageAspectRatio;
  final TransformationController transformationController;
  final VoidCallback onToggleSquareMode;

  const _EditorBody({
    required this.imageBytes,
    required this.repaintKey,
    required this.isExporting,
    required this.onDone,
    required this.onCancel,
    required this.onShowPanel,
    required this.brushColors,
    required this.isSquareMode,
    required this.imageAspectRatio,
    required this.transformationController,
    required this.onToggleSquareMode,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditorProvider>();
    final isDrawMode = provider.activeTool == EditorTool.draw;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => provider.selectOverlay(null),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context, provider),
              Expanded(
                child: Center(
                  child: _buildCanvas(context, provider, isDrawMode),
                ),
              ),
              if (isDrawMode)
                _buildDrawToolbar(context, provider)
              else
                _buildBottomToolbar(context, provider),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top bar ──────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context, EditorProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Cancel
          _glassButton(
            child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
            onTap: onCancel,
          ),
          const SizedBox(width: 8),

          // Fit / Crop toggle button
          _glassButton(
            child: Icon(
              isSquareMode ? Icons.crop_free_rounded : Icons.crop_din_rounded,
              color: Colors.white,
              size: 20,
            ),
            onTap: onToggleSquareMode,
          ),
          const Spacer(),

          // Undo
          Opacity(
            opacity: provider.canUndo ? 1.0 : 0.3,
            child: _glassButton(
              child: const Icon(Icons.undo_rounded, color: Colors.white, size: 20),
              onTap: provider.canUndo ? provider.undo : () {},
            ),
          ),
          const SizedBox(width: 8),

          // Redo
          Opacity(
            opacity: provider.canRedo ? 1.0 : 0.3,
            child: _glassButton(
              child: const Icon(Icons.redo_rounded, color: Colors.white, size: 20),
              onTap: provider.canRedo ? provider.redo : () {},
            ),
          ),
          const SizedBox(width: 12),

          // Done
          GestureDetector(
            onTap: isExporting ? null : onDone,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF4B1F)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B35).withAlpha(100),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Done',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Canvas ───────────────────────────────────────────────────────────

  Widget _buildCanvas(BuildContext context, EditorProvider provider, bool isDrawMode) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxSize = constraints.biggest;
        
        // Calculate canvas size keeping the aspect ratio (Fit mode) or Square mode
        double canvasWidth = maxSize.width;
        double canvasHeight = isSquareMode
            ? maxSize.width
            : (maxSize.width / imageAspectRatio);

        // Clamp inside vertical screen size if too tall
        if (canvasHeight > maxSize.height) {
          canvasHeight = maxSize.height;
          canvasWidth = maxSize.height * imageAspectRatio;
        }

        final canvasSize = Size(canvasWidth, canvasHeight);

        return SizedBox(
          width: canvasSize.width,
          height: canvasSize.height,
          child: RepaintBoundary(
            key: repaintKey,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // Base image with pan/zoom (cropping) support
                Positioned.fill(
                  child: InteractiveViewer(
                    transformationController: transformationController,
                    minScale: 1.0,
                    maxScale: 5.0,
                    panEnabled: !isDrawMode,
                    scaleEnabled: !isDrawMode,
                    child: Image.memory(
                      imageBytes,
                      fit: isSquareMode ? BoxFit.cover : BoxFit.fill,
                      gaplessPlayback: true,
                    ),
                  ),
                ),

                // Drawing layer (behind other overlays but above image)
                Positioned.fill(
                  child: DrawingCanvas(
                    canvasSize: canvasSize,
                    isDrawMode: isDrawMode,
                  ),
                ),

                // Overlay widgets (emoji, text, stickers, GIFs)
                ...provider.overlays
                    .where((o) => o.type != OverlayType.drawing)
                    .map((overlay) => DraggableOverlay(
                          key: ValueKey(overlay.id),
                          overlay: overlay,
                          canvasSize: canvasSize,
                        )),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Bottom toolbar ───────────────────────────────────────────────────

  Widget _buildBottomToolbar(BuildContext context, EditorProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _toolButton(
            label: 'Emoji',
            icon: '😊',
            isActive: provider.activeTool == EditorTool.emoji,
            onTap: () => onShowPanel(context, const EmojiPickerPanel()),
          ),
          _toolButton(
            label: 'Sticker',
            icon: '⭐',
            isActive: provider.activeTool == EditorTool.sticker,
            onTap: () => onShowPanel(context, const StickerPickerPanel()),
          ),
          _toolButton(
            label: 'GIF',
            icon: '🎬',
            isActive: provider.activeTool == EditorTool.gif,
            onTap: () => onShowPanel(context, const GifPickerPanel()),
          ),
          _toolButton(
            label: 'Text',
            iconWidget: const Icon(Icons.text_fields_rounded, color: Colors.white, size: 22),
            isActive: provider.activeTool == EditorTool.text,
            onTap: () => onShowPanel(context, const TextEditorPanel()),
          ),
          _toolButton(
            label: 'Draw',
            iconWidget: const Icon(Icons.draw_rounded, color: Colors.white, size: 22),
            isActive: provider.activeTool == EditorTool.draw,
            onTap: () => provider.setTool(EditorTool.draw),
          ),
        ],
      ),
    );
  }

  // ── Draw toolbar ─────────────────────────────────────────────────────

  Widget _buildDrawToolbar(BuildContext context, EditorProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Color row + eraser + done drawing
          Row(
            children: [
              // Brush colors
              ...brushColors.map((c) => GestureDetector(
                onTap: () => provider.setBrushColor(c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: provider.brush.color == c && !provider.brush.isEraser
                          ? Colors.white
                          : Colors.white24,
                      width: provider.brush.color == c && !provider.brush.isEraser ? 3 : 1.5,
                    ),
                  ),
                ),
              )),
              // Eraser
              GestureDetector(
                onTap: () => provider.setEraser(!provider.brush.isEraser),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: provider.brush.isEraser ? const Color(0xFFFF6B35) : Colors.white24,
                      width: provider.brush.isEraser ? 3 : 1.5,
                    ),
                  ),
                  child: const Icon(Icons.auto_fix_high_rounded, color: Colors.white70, size: 14),
                ),
              ),
              const Spacer(),
              // Done drawing
              GestureDetector(
                onTap: () => provider.setTool(EditorTool.none),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Brush size slider
          Row(
            children: [
              const Icon(Icons.circle, color: Colors.white54, size: 8),
              Expanded(
                child: Slider(
                  value: provider.brush.strokeWidth,
                  min: 2,
                  max: 24,
                  activeColor: const Color(0xFFFF6B35),
                  inactiveColor: Colors.white12,
                  onChanged: provider.setBrushSize,
                ),
              ),
              const Icon(Icons.circle, color: Colors.white, size: 18),
            ],
          ),

          // Clear drawing button
          TextButton.icon(
            onPressed: provider.clearDrawing,
            icon: const Icon(Icons.delete_outline_rounded, size: 16),
            label: const Text('Clear drawing', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(foregroundColor: Colors.white38),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  Widget _glassButton({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(30),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withAlpha(50)),
        ),
        child: Center(child: child),
      ),
    );
  }

  Widget _toolButton({
    required String label,
    String? icon,
    Widget? iconWidget,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFFFF6B35).withAlpha(40)
              : Colors.white.withAlpha(15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? const Color(0xFFFF6B35) : Colors.white.withAlpha(30),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Text(icon, style: const TextStyle(fontSize: 22))
            else if (iconWidget != null)
              iconWidget,
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? const Color(0xFFFF6B35) : Colors.white70,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
