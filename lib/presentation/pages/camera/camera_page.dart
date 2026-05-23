import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/dummy_data.dart';
import '../../../core/utils/time_formatter.dart';
import '../../../core/services/image_compressor.dart';
import '../../providers/feed_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/friend_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/camera_panel.dart';
import '../editor/moment_editor_page.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  // Camera state
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _selectedCameraIndex = -1;
  FlashMode _flashMode = FlashMode.off;
  bool _isPermissionGranted = false;
  bool _isInitializing = false;
  bool _wasVisible = false;

  // Capture / Upload state
  Uint8List? _capturedImageBytes;
  bool _isUploading = false;
  final TextEditingController _captionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!kIsWeb) {
      _checkPermissionAndInit();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeController();
    _captionController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kIsWeb || _controller == null || !_controller!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _disposeController();
    } else if (state == AppLifecycleState.resumed) {
      final currentPath = GoRouterState.of(context).uri.path;
      if (currentPath == '/camera') {
        _initializeCamera();
      }
    }
  }

  void _disposeController() {
    if (_controller != null) {
      _controller!.dispose();
      _controller = null;
    }
  }

  Future<void> _checkPermissionAndInit() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      setState(() => _isPermissionGranted = true);
      _initializeCamera();
    } else {
      final requestStatus = await Permission.camera.request();
      if (requestStatus.isGranted) {
        setState(() => _isPermissionGranted = true);
        _initializeCamera();
      } else {
        setState(() => _isPermissionGranted = false);
      }
    }
  }

  Future<void> _initializeCamera() async {
    if (_isInitializing) return;
    setState(() => _isInitializing = true);
    _disposeController();

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _isInitializing = false);
        return;
      }

      // Default to front (selfie) camera for social context
      if (_selectedCameraIndex == -1) {
        _selectedCameraIndex = 0;
        for (int i = 0; i < _cameras.length; i++) {
          if (_cameras[i].lensDirection == CameraLensDirection.front) {
            _selectedCameraIndex = i;
            break;
          }
        }
      }

      final camera = _cameras[_selectedCameraIndex];
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      await _controller!.setFlashMode(_flashMode);

      if (mounted) {
        setState(() => _isInitializing = false);
      }
    } catch (e) {
      debugPrint("CAMERA_DEBUG: Error initializing camera: $e");
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  Future<void> _toggleCamera() async {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _initializeCamera();
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final nextMode = switch (_flashMode) {
      FlashMode.off => FlashMode.always,
      FlashMode.always => FlashMode.auto,
      FlashMode.auto => FlashMode.off,
      _ => FlashMode.off,
    };

    try {
      await _controller!.setFlashMode(nextMode);
      setState(() {
        _flashMode = nextMode;
      });
    } catch (e) {
      debugPrint("CAMERA_DEBUG: Error setting flash mode: $e");
    }
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized || _isInitializing) return;

    try {
      final file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();
      
      // Compress immediately client-side
      final compressedBytes = await compressAndResizeImage(
        bytes,
        maxWidth: 1080,
        maxHeight: 1080,
        quality: 70,
      );

      setState(() {
        _capturedImageBytes = compressedBytes;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 70,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      final compressedBytes = await compressAndResizeImage(
        bytes,
        maxWidth: 1080,
        maxHeight: 1080,
        quality: 70,
      );

      setState(() {
        _capturedImageBytes = compressedBytes;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking from gallery: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _openOverlayEditor() async {
    if (_capturedImageBytes == null) return;
    final edited = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => MomentEditorPage(imageBytes: _capturedImageBytes!),
      ),
    );
    if (edited != null) {
      setState(() {
        _capturedImageBytes = edited;
      });
    }
  }

  Future<void> _sendPhoto() async {
    if (_capturedImageBytes == null || _isUploading) return;

    setState(() {
      _isUploading = true;
    });

    final l10n = AppLocalizations.of(context)!;
    try {
      final caption = _captionController.text.trim().isNotEmpty
          ? _captionController.text.trim()
          : null;

      final newPhoto = await context.read<FeedProvider>().addNewMoment(_capturedImageBytes!, caption);
      
      if (newPhoto != null && mounted) {
        final now = DateTime.now();
        final friendsCount = context.read<FriendProvider>().friends.length;
        final newHistoryPhoto = DummyHistoryPhoto(
          id: newPhoto.id,
          imageUrl: newPhoto.imageUrl,
          imageBytes: _capturedImageBytes,
          sentAt: formatMomentTime(now, l10n: AppLocalizations.of(context)),
          sentDate: now,
          caption: caption,
          recipientCount: friendsCount,
          reactionCount: 0,
        );
        context.read<HistoryProvider>().addNewMoment(newHistoryPhoto);
      }

      if (mounted) {
        await context.read<FeedProvider>().fetchNewPhotos();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Text(l10n.cameraPhotoSent, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
        setState(() {
          _capturedImageBytes = null;
          _captionController.clear();
        });
        // Go back to home feed
        context.go('/home');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── Web Fallback Layout ──────────────────────────────────────────
    if (kIsWeb) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: EdgeInsets.all(16),
          child: CameraPanel(),
        ),
      );
    }

    // ── Native Mobile Lifecycle Visibility Check ─────────────────────
    final currentPath = GoRouterState.of(context).uri.path;
    final isVisible = currentPath == '/camera';

    if (isVisible != _wasVisible) {
      _wasVisible = isVisible;
      if (isVisible) {
        _checkPermissionAndInit();
      } else {
        _disposeController();
      }
    }

    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final scaffoldBg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: scaffoldBg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: _capturedImageBytes != null
            ? _buildUploadPreviewLayout(isDark, l10n)
            : _buildViewfinderLayout(isDark, l10n),
      ),
    );
  }

  // ── Viewfinder View ────────────────────────────────────────────────
  Widget _buildViewfinderLayout(bool isDark, AppLocalizations l10n) {
    if (!_isPermissionGranted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_outlined, size: 64, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              Text(
                'Camera Access Required',
                style: TextStyle(color: isDark ? Colors.white : AppColors.textDark, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Please grant camera permissions to capture and share moments with friends.',
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textLight, fontSize: 14),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _checkPermissionAndInit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Grant Camera Access', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double squareWidth = constraints.maxWidth - 40;

        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  const Icon(Icons.photo_camera_rounded, color: AppColors.primary, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    l10n.cameraShareMoment,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Viewfinder frame
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 16,
                          )
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _controller == null || !_controller!.value.isInitialized
                          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                          : LayoutBuilder(
                              builder: (context, boxConstraints) {
                                return FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: boxConstraints.maxWidth,
                                    height: boxConstraints.maxWidth * _controller!.value.aspectRatio,
                                    child: CameraPreview(_controller!),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ),
              ),
            ),

            // Shutter controls
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Flash mode
                  IconButton(
                    onPressed: _toggleFlash,
                    icon: Icon(
                      switch (_flashMode) {
                        FlashMode.off => Icons.flash_off_rounded,
                        FlashMode.always => Icons.flash_on_rounded,
                        FlashMode.auto => Icons.flash_auto_rounded,
                        _ => Icons.flash_off_rounded,
                      },
                      color: _flashMode == FlashMode.off
                          ? (isDark ? Colors.white38 : Colors.black38)
                          : AppColors.primary,
                      size: 26,
                    ),
                  ),

                  // Shutter button
                  GestureDetector(
                    onTap: _takePhoto,
                    child: Container(
                      width: 76,
                      height: 76,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 3.5),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),

                  // Toggle camera front/back
                  IconButton(
                    onPressed: _toggleCamera,
                    icon: Icon(
                      Icons.flip_camera_android_rounded,
                      color: isDark ? Colors.white70 : Colors.black87,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),

            // Import shortcut
            GestureDetector(
              onTap: _pickFromGallery,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_library_rounded, size: 18, color: isDark ? AppColors.textMuted : AppColors.textLight),
                    const SizedBox(width: 8),
                    Text(
                      l10n.cameraUploadPhoto,
                      style: TextStyle(
                        color: isDark ? AppColors.textMuted : AppColors.textLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Preview & Post View ───────────────────────────────────────────
  Widget _buildUploadPreviewLayout(bool isDark, AppLocalizations l10n) {
    final friendsCount = context.watch<FriendProvider>().friends.length;
    final inputBg = isDark ? AppColors.darkCard : Colors.grey[100]!;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _capturedImageBytes = null;
                    });
                  },
                  icon: Icon(Icons.close_rounded, color: isDark ? Colors.white : AppColors.textDark, size: 28),
                ),
                Text(
                  'Post Moment',
                  style: TextStyle(color: isDark ? Colors.white : AppColors.textDark, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: _openOverlayEditor,
                  icon: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 24),
                  tooltip: 'Decorate with Stickers / Text',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Photo Preview Frame
            AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 16,
                    )
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.memory(
                  _capturedImageBytes!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Caption Entry Field
            Container(
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _captionController,
                style: TextStyle(color: isDark ? Colors.white : AppColors.textDark, fontSize: 15),
                maxLines: 2,
                maxLength: 100,
                decoration: InputDecoration(
                  hintText: l10n.cameraAddCaption,
                  hintStyle: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textLight, fontSize: 14),
                  border: InputBorder.none,
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sharing destination summary
            Row(
              children: [
                const Icon(Icons.group_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: l10n.cameraSharingWithCircle,
                          style: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textLight, fontSize: 13),
                        ),
                        TextSpan(
                          text: '$friendsCount ${friendsCount == 1 ? l10n.cameraFriend : l10n.cameraFriends}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Post Button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _sendPhoto,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isUploading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        l10n.cameraSendToFriends,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
