import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';

class WebDragDropZone extends StatefulWidget {
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
  State<WebDragDropZone> createState() => _WebDragDropZoneState();
}

class _WebDragDropZoneState extends State<WebDragDropZone> {
  StreamSubscription? _onDragOverSubscription;
  StreamSubscription? _onDragEnterSubscription;
  StreamSubscription? _onDragLeaveSubscription;
  StreamSubscription? _onDropSubscription;

  @override
  void initState() {
    super.initState();
    _initDragDropListeners();
  }

  void _initDragDropListeners() {
    // 1. Prevent default drag/drop navigation globally on document body
    html.document.body?.onDragOver.listen((event) => event.preventDefault());
    html.document.body?.onDrop.listen((event) => event.preventDefault());

    // 2. Attach listeners for the drop target zone on the window in capturing phase
    // This intercepts drag gestures globally before they propagate down.
    _onDragEnterSubscription = html.window.onDragEnter.listen((event) {
      event.preventDefault();
      event.stopPropagation();
      widget.onDragStateChanged(true);
    });

    _onDragOverSubscription = html.window.onDragOver.listen((event) {
      event.preventDefault();
      event.stopPropagation();
    });

    _onDragLeaveSubscription = html.window.onDragLeave.listen((event) {
      event.preventDefault();
      event.stopPropagation();
      // Only reset drag over state if mouse is leaving the window boundaries
      if (event.client.x == 0 && event.client.y == 0) {
        widget.onDragStateChanged(false);
      }
    });

    _onDropSubscription = html.window.onDrop.listen((event) {
      event.preventDefault();
      event.stopPropagation();
      widget.onDragStateChanged(false);

      final files = event.dataTransfer.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        final normalizedType = file.type.toLowerCase();
        
        // Accept PNG, JPG, JPEG, WEBP
        final supported = {'image/png', 'image/jpeg', 'image/jpg', 'image/webp'};
        final isSupported = supported.any((mime) => normalizedType.contains(mime.split('/').last));

        if (isSupported) {
          final reader = html.FileReader();
          reader.onLoadEnd.listen((loadEvent) {
            final result = reader.result;
            if (result != null && result is ByteBuffer) {
              final Uint8List bytes = Uint8List.view(result);
              widget.onFileDropped(bytes, file.name, file.type, file.size);
            }
          });
          reader.readAsArrayBuffer(file);
        }
      }
    });
  }

  @override
  void dispose() {
    _onDragOverSubscription?.cancel();
    _onDragEnterSubscription?.cancel();
    _onDragLeaveSubscription?.cancel();
    _onDropSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
