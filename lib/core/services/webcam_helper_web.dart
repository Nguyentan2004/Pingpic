import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'image_service.dart';
import 'image_compressor.dart';
import '../constants/app_colors.dart';

class WebcamHelper {
  static Future<ImagePickResult?> takePhotoWithWebcam(BuildContext context) async {
    return showDialog<ImagePickResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const WebcamDialog(),
    );
  }
}

class WebcamDialog extends StatefulWidget {
  const WebcamDialog({super.key});

  @override
  State<WebcamDialog> createState() => _WebcamDialogState();
}

class _WebcamDialogState extends State<WebcamDialog> {
  html.VideoElement? _videoElement;
  html.MediaStream? _mediaStream;
  String _viewId = '';
  bool _isCameraReady = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _viewId = 'webcam-${DateTime.now().millisecondsSinceEpoch}';
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _videoElement = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';

      // Register platform view factory
      ui_web.platformViewRegistry.registerViewFactory(_viewId, (int id) => _videoElement!);

      _mediaStream = await html.window.navigator.mediaDevices?.getUserMedia({'video': {
        'facingMode': 'user',
        'width': {'ideal': 1280},
        'height': {'ideal': 720}
      }});
      
      if (_mediaStream != null && _videoElement != null) {
        _videoElement!.srcObject = _mediaStream;
        _videoElement!.onLoadedMetadata.listen((_) {
          if (mounted) {
            setState(() {
              _isCameraReady = true;
            });
          }
        });
      } else {
        setState(() {
          _error = 'Không tìm thấy camera hoặc thiết bị của bạn không có camera.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Không thể truy cập camera. Vui lòng kiểm tra quyền camera trong cài đặt trình duyệt của bạn.';
      });
    }
  }

  void _stopCamera() {
    if (_mediaStream != null) {
      for (var track in _mediaStream!.getTracks()) {
        track.stop();
      }
      _mediaStream = null;
    }
    if (_videoElement != null) {
      _videoElement!.srcObject = null;
      _videoElement = null;
    }
  }

  @override
  void dispose() {
    _stopCamera();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_videoElement == null || !_isCameraReady) return;

    final width = _videoElement!.videoWidth;
    final height = _videoElement!.videoHeight;

    if (width == 0 || height == 0) return;

    final canvas = html.CanvasElement(width: width, height: height);
    final context2d = canvas.context2D;
    
    // Mirror the captured image to match the front-facing camera preview
    context2d.translate(width, 0);
    context2d.scale(-1, 1);
    context2d.drawImage(_videoElement!, 0, 0);

    final dataUrl = canvas.toDataUrl('image/jpeg', 0.9);
    final base64String = dataUrl.split(',').last;
    final bytes = base64.decode(base64String);

    // Compress using Canvas/HTML helper
    final compressedBytes = await compressAndResizeImage(
      bytes,
      maxWidth: 1080,
      maxHeight: 1080,
      quality: 70,
    );

    final result = ImagePickResult(
      bytes: compressedBytes,
      fileName: 'webcam_capture_${DateTime.now().millisecondsSinceEpoch}.jpg',
      mimeType: 'image/jpeg',
      fileSize: compressedBytes.length,
    );

    _stopCamera();
    if (mounted) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        width: 420,
        height: 540,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Camera',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () {
                    _stopCamera();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  color: Colors.black,
                  width: double.infinity,
                  child: _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                            ),
                          ),
                        )
                      : !_isCameraReady
                          ? const Center(
                              child: CircularProgressIndicator(color: AppColors.primary),
                            )
                          : Stack(
                              children: [
                                Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.rotationY(3.14159), // Mirror camera preview
                                  child: HtmlElementView(viewType: _viewId),
                                ),
                              ],
                            ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_error == null && _isCameraReady)
              GestureDetector(
                onTap: _capture,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 72),
          ],
        ),
      ),
    );
  }
}
