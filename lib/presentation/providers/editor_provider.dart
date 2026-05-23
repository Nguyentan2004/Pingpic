import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/moment_overlay.dart';

enum EditorTool { none, emoji, sticker, gif, text, draw }

class EditorProvider extends ChangeNotifier {
  final _uuid = const Uuid();

  // ── Overlays ──────────────────────────────────────────────────────
  List<MomentOverlay> _overlays = [];
  List<List<MomentOverlay>> _undoStack = [];
  List<List<MomentOverlay>> _redoStack = [];

  // ── Selection ─────────────────────────────────────────────────────
  String? _selectedId;

  // ── Active tool ───────────────────────────────────────────────────
  EditorTool _activeTool = EditorTool.none;

  // ── Drawing brush ─────────────────────────────────────────────────
  DrawingBrush _brush = const DrawingBrush();
  List<DrawPoint> _currentStroke = [];

  // ── Getters ───────────────────────────────────────────────────────
  List<MomentOverlay> get overlays => List.unmodifiable(_overlays);
  String? get selectedId => _selectedId;
  EditorTool get activeTool => _activeTool;
  DrawingBrush get brush => _brush;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  // ── Tool management ───────────────────────────────────────────────

  void setTool(EditorTool tool) {
    if (_activeTool == tool) {
      _activeTool = EditorTool.none;
    } else {
      _activeTool = tool;
    }
    _selectedId = null;
    notifyListeners();
  }

  void closeTool() {
    _activeTool = EditorTool.none;
    notifyListeners();
  }

  // ── Overlay CRUD ──────────────────────────────────────────────────

  void _saveUndoSnapshot() {
    _undoStack.add(List.from(_overlays.map((o) => o.copyWith())));
    if (_undoStack.length > 30) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  void addOverlay(MomentOverlay overlay) {
    _saveUndoSnapshot();
    _overlays.add(overlay);
    _selectedId = overlay.id;
    _activeTool = EditorTool.none;
    notifyListeners();
  }

  void addEmoji(String emoji) {
    addOverlay(MomentOverlay(
      id: _uuid.v4(),
      type: OverlayType.emoji,
      content: emoji,
      position: const Offset(0.5, 0.5),
      scale: 1.0,
      fontSize: 48,
    ));
  }

  void addSticker(String sticker) {
    addOverlay(MomentOverlay(
      id: _uuid.v4(),
      type: OverlayType.sticker,
      content: sticker,
      position: const Offset(0.5, 0.4),
      scale: 1.2,
      fontSize: 56,
    ));
  }

  void addGif(String gifUrl) {
    addOverlay(MomentOverlay(
      id: _uuid.v4(),
      type: OverlayType.gif,
      content: gifUrl,
      position: const Offset(0.5, 0.5),
      scale: 0.5,
    ));
  }

  void addText({
    required String text,
    Color color = Colors.white,
    double fontSize = 28,
    bool bold = false,
    bool italic = false,
    bool hasShadow = true,
    TextStylePreset preset = TextStylePreset.white,
    TextAlign align = TextAlign.center,
  }) {
    addOverlay(MomentOverlay(
      id: _uuid.v4(),
      type: OverlayType.text,
      content: text,
      position: const Offset(0.5, 0.3),
      scale: 1.0,
      color: color,
      fontSize: fontSize,
      bold: bold,
      italic: italic,
      hasShadow: hasShadow,
      textStylePreset: preset,
      textAlign: align,
    ));
  }

  void updateOverlayTransform(
    String id, {
    Offset? position,
    double? scale,
    double? rotation,
  }) {
    final idx = _overlays.indexWhere((o) => o.id == id);
    if (idx == -1) return;
    _overlays[idx] = _overlays[idx].copyWith(
      position: position,
      scale: scale,
      rotation: rotation,
    );
    notifyListeners();
  }

  void updateTextOverlay(String id, MomentOverlay updated) {
    _saveUndoSnapshot();
    final idx = _overlays.indexWhere((o) => o.id == id);
    if (idx == -1) return;
    _overlays[idx] = updated;
    notifyListeners();
  }

  void deleteOverlay(String id) {
    _saveUndoSnapshot();
    _overlays.removeWhere((o) => o.id == id);
    if (_selectedId == id) _selectedId = null;
    notifyListeners();
  }

  void selectOverlay(String? id) {
    _selectedId = id;
    notifyListeners();
  }

  void bringToFront(String id) {
    final idx = _overlays.indexWhere((o) => o.id == id);
    if (idx == -1 || idx == _overlays.length - 1) return;
    final overlay = _overlays.removeAt(idx);
    _overlays.add(overlay);
    notifyListeners();
  }

  // ── Undo / Redo ───────────────────────────────────────────────────

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(List.from(_overlays.map((o) => o.copyWith())));
    _overlays = _undoStack.removeLast();
    _selectedId = null;
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(List.from(_overlays.map((o) => o.copyWith())));
    _overlays = _redoStack.removeLast();
    _selectedId = null;
    notifyListeners();
  }

  void clearAll() {
    _saveUndoSnapshot();
    _overlays.clear();
    _selectedId = null;
    notifyListeners();
  }

  // ── Drawing ───────────────────────────────────────────────────────

  void setBrushColor(Color color) {
    _brush = _brush.copyWith(color: color, isEraser: false);
    notifyListeners();
  }

  void setBrushSize(double size) {
    _brush = _brush.copyWith(strokeWidth: size);
    notifyListeners();
  }

  void setEraser(bool val) {
    _brush = _brush.copyWith(isEraser: val);
    notifyListeners();
  }

  void startDrawStroke(Offset localPos) {
    _currentStroke = [
      DrawPoint(
        point: localPos,
        color: _brush.isEraser ? Colors.transparent : _brush.color,
        strokeWidth: _brush.strokeWidth,
        isNewStroke: true,
      ),
    ];
    _updateDrawingLayer();
  }

  void continueDrawStroke(Offset localPos) {
    _currentStroke.add(DrawPoint(
      point: localPos,
      color: _brush.isEraser ? Colors.transparent : _brush.color,
      strokeWidth: _brush.strokeWidth,
    ));
    _updateDrawingLayer();
  }

  void endDrawStroke() {
    if (_currentStroke.isEmpty) return;
    _saveUndoSnapshot();
    _currentStroke = [];
    // Drawing layer is already committed in _updateDrawingLayer
  }

  void _updateDrawingLayer() {
    // Find or create the drawing overlay
    final existingIdx = _overlays.indexWhere((o) => o.type == OverlayType.drawing);
    final existingPoints = existingIdx != -1 ? (_overlays[existingIdx].drawPoints ?? []) : <DrawPoint>[];
    final allPoints = [...existingPoints, ..._currentStroke];

    final drawOverlay = MomentOverlay(
      id: existingIdx != -1 ? _overlays[existingIdx].id : _uuid.v4(),
      type: OverlayType.drawing,
      content: '',
      position: Offset.zero,
      drawPoints: allPoints,
    );

    if (existingIdx != -1) {
      _overlays[existingIdx] = drawOverlay;
    } else {
      _overlays.insert(0, drawOverlay); // Drawing is always at bottom
    }
    notifyListeners();
  }

  void clearDrawing() {
    _saveUndoSnapshot();
    _overlays.removeWhere((o) => o.type == OverlayType.drawing);
    notifyListeners();
  }

  // ── Reset ─────────────────────────────────────────────────────────

  void reset() {
    _overlays.clear();
    _undoStack.clear();
    _redoStack.clear();
    _selectedId = null;
    _activeTool = EditorTool.none;
    _currentStroke = [];
    _brush = const DrawingBrush();
    notifyListeners();
  }
}
