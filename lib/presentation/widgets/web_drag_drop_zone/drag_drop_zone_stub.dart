import 'dart:typed_data';
import 'package:flutter/material.dart';

class WebDragDropZone extends StatelessWidget {
  final Widget child;
  final Function(Uint8List bytes, String name, String mimeType, int size) onFileDropped;
  final Function(bool isDragOver) onDragStateChanged;

  const WebDragDropZone({
    super.key,
    required this.child,
    required this.onFileDropped,
    required this.onDragStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Non-web platforms don't support browser drag-and-drop, so simply return child
    return child;
  }
}
