import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/dummy_data.dart';
import '../../core/services/image_service.dart';
import '../../core/services/webcam_helper.dart';
import 'package:provider/provider.dart';
import '../providers/feed_provider.dart';
import '../providers/history_provider.dart';
import '../providers/friend_provider.dart';
import '../providers/theme_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/time_formatter.dart';

/// Camera / Upload panel — sử dụng ImageService thật (image_picker).
/// Hiển thị preview ảnh bằng Image.memory() — web-compatible.
class CameraPanel extends StatefulWidget {
  const CameraPanel({super.key});

  @override
  State<CameraPanel> createState() => _CameraPanelState();
}

class _CameraPanelState extends State<CameraPanel>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  Uint8List? _imageBytes;       // Raw bytes của ảnh đã chọn
  String? _fileName;             // Tên file
  String? _fileSize;             // Kích thước đã format
  bool _isLoading = false;       // Đang xử lý image picker
  bool _isUploading = false;     // Đang upload ảnh
  String? _errorMessage;         // Thông báo lỗi
  bool _isDragOver = false;      // Hover drag-and-drop zone

  final TextEditingController _captionController = TextEditingController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  // ── Image picking logic ────────────────────────────────────────────────────

  Future<void> _handleTakePhoto() async {
    if (kIsWeb) {
      await _pickImage(() => WebcamHelper.takePhotoWithWebcam(context));
    } else {
      await _pickImage(() => ImageService.takePhoto());
    }
  }

  Future<void> _handlePickFromGallery() async {
    await _pickImage(() => ImageService.pickFromGallery());
  }

  /// Template method: gọi [picker], xử lý kết quả và lỗi.
  Future<void> _pickImage(
    Future<ImagePickResult?> Function() picker,
  ) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await picker();

      if (result == null) {
        // Người dùng huỷ — không hiển thị lỗi
        setState(() => _isLoading = false);
        return;
      }

      setState(() {
        _imageBytes = result.bytes;
        _fileName = result.fileName;
        _fileSize = result.fileSizeFormatted;
        _isLoading = false;
      });
    } on CameraPermissionDeniedException {
      _showError(
        '📷 Camera access denied',
        'Please click the camera icon in your browser\'s address bar and allow access, then try again.',
        isPermissionError: true,
      );
    } on FileTooLargeException catch (e) {
      _showError('⚠️ File too large', e.toString());
    } on UnsupportedFormatException catch (e) {
      _showError('❌ Unsupported format', e.toString());
    } on ImageServiceException catch (e) {
      _showError('Something went wrong', e.toString());
    } catch (e) {
      _showError('Unexpected error', e.toString());
    }
  }

  void _showError(String title, String message,
      {bool isPermissionError = false}) {
    setState(() {
      _isLoading = false;
      _errorMessage = '$title\n$message';
    });

    // Auto-dismiss lỗi sau 6 giây (trừ permission error)
    if (!isPermissionError) {
      Future.delayed(const Duration(seconds: 6), () {
        if (mounted) setState(() => _errorMessage = null);
      });
    }
  }

  void _clearImage() {
    setState(() {
      _imageBytes = null;
      _fileName = null;
      _fileSize = null;
      _errorMessage = null;
      _captionController.clear();
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.07),
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPanelHeader(isDark, l10n),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double viewportHeight = constraints.maxHeight;
                  // Deduct estimated height of action button (56px) + spacing (12px)
                  final double scrollViewportHeight = (viewportHeight - 68.0).clamp(0.0, double.infinity);

                  return Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: scrollViewportHeight,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_imageBytes != null)
                                  AspectRatio(
                                    aspectRatio: 1.0,
                                    child: _buildPhotoPreview(isDark, l10n),
                                  )
                                else
                                  _buildUploadZone(scrollViewportHeight, isDark, l10n),
                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 12),
                                  _buildErrorBanner(isDark),
                                ],
                                if (_imageBytes != null) ...[
                                  const SizedBox(height: 16),
                                  _buildCaptionField(isDark, l10n),
                                  const SizedBox(height: 12),
                                  _buildRecipientsRow(isDark, l10n),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildActionButtons(l10n),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelHeader(bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.cameraShareMoment,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  l10n.cameraBroadcastDesc,
                  style: TextStyle(
                    color: isDark ? AppColors.textMuted : AppColors.textLight,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Upload zone (khi chưa có ảnh) ─────────────────────────────────────────

  Widget _buildUploadZone(double availableHeight, bool isDark, AppLocalizations l10n) {
    // Dynamically calculate the target height. Deduct height of error banner if visible.
    final double targetHeight = _errorMessage != null
        ? (availableHeight - 90.0).clamp(280.0, double.infinity)
        : availableHeight.clamp(280.0, double.infinity);

    return MouseRegion(
      onEnter: (_) => setState(() => _isDragOver = true),
      onExit: (_) => setState(() => _isDragOver = false),
      child: GestureDetector(
        onTap: _handlePickFromGallery,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: targetHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isDragOver
                  ? AppColors.primary
                  : (isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.12)),
              width: _isDragOver ? 2 : 1.5,
            ),
            color: _isDragOver
                ? AppColors.primary.withOpacity(0.08)
                : (isDark ? AppColors.darkCard : Colors.grey[50]!),
          ),
          child: _isLoading
              ? _buildLoadingIndicator(isDark, l10n)
              : _buildUploadContent(isDark, l10n),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(bool isDark, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.localeName == 'vi' ? 'Đang mở máy ảnh...' : 'Opening camera...',
            style: TextStyle(
              color: isDark ? AppColors.textMuted : AppColors.textLight,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadContent(bool isDark, AppLocalizations l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated icon
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, child) => Transform.scale(
            scale: _isDragOver ? 1.15 : _pulseAnim.value,
            child: child,
          ),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.2),
                  AppColors.primaryLight.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.add_photo_alternate_rounded,
              color: AppColors.primary,
              size: 38,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _isDragOver 
              ? (l10n.localeName == 'vi' ? 'Buông ra để tải lên!' : 'Release to upload!') 
              : l10n.cameraUploadPhoto,
          style: TextStyle(
            color: _isDragOver ? AppColors.primary : (isDark ? Colors.white : AppColors.textDark),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'PNG, JPG, WEBP up to 10MB',
          style: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textLight, fontSize: 12),
        ),
        const SizedBox(height: 20),
        // Divider
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 48, height: 1,
                color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.12)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                l10n.localeName == 'vi' ? 'hoặc' : 'or',
                style: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textLight, fontSize: 12),
              ),
            ),
            Container(
                width: 48, height: 1,
                color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.12)),
          ],
        ),
        const SizedBox(height: 16),
        // Take photo button — triggers camera
        OutlinedButton.icon(
          onPressed: _handleTakePhoto,
          icon: const Icon(Icons.camera_alt_rounded, size: 18),
          label: Text(l10n.cameraTakePhoto),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  // ── Photo preview (khi đã có ảnh) ─────────────────────────────────────────

  Widget _buildPhotoPreview(bool isDark, AppLocalizations l10n) {
    return Stack(
      children: [
        // Ảnh preview thật từ bytes
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Image.memory(
              _imageBytes!,
              fit: BoxFit.cover,
              // Fallback nếu bytes corrupt
              errorBuilder: (_, __, ___) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image_rounded,
                        color: isDark ? AppColors.textMuted : AppColors.textLight, size: 48),
                    const SizedBox(height: 8),
                    Text(l10n.localeName == 'vi' ? 'Không thể hiển thị ảnh' : 'Could not display image',
                        style: TextStyle(
                            color: isDark ? AppColors.textMuted : AppColors.textLight, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Overlay top: file info
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.65),
                  Colors.transparent,
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _fileName ?? 'image',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_fileSize != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _fileSize!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Close button (xoá ảnh)
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: _clearImage,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),

        // Replace button
        Positioned(
          bottom: 10,
          left: 10,
          child: GestureDetector(
            onTap: _handlePickFromGallery,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_horiz_rounded,
                      color: Colors.white.withOpacity(0.9), size: 14),
                  const SizedBox(width: 5),
                  Text(
                    l10n.localeName == 'vi' ? 'Thay thế' : 'Replace',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Error banner ───────────────────────────────────────────────────────────

  Widget _buildErrorBanner(bool isDark) {
    final lines = _errorMessage!.split('\n');
    final title = lines.first;
    final detail = lines.length > 1 ? lines.sublist(1).join('\n') : null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    style: TextStyle(
                      color: isDark ? Colors.white.withOpacity(0.7) : AppColors.textLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _errorMessage = null),
            child: Icon(Icons.close_rounded,
                color: isDark ? Colors.white.withOpacity(0.5) : AppColors.textLight, size: 16),
          ),
        ],
      ),
    );
  }

  // ── Caption field ──────────────────────────────────────────────────────────

  Widget _buildCaptionField(bool isDark, AppLocalizations l10n) {
    return TextField(
      controller: _captionController,
      maxLines: 2,
      maxLength: 100,
      style: TextStyle(color: isDark ? Colors.white : AppColors.textDark, fontSize: 14),
      decoration: InputDecoration(
        hintText: l10n.cameraAddCaption,
        hintStyle: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textLight, fontSize: 14),
        filled: true,
        fillColor: isDark ? AppColors.darkCard : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: AppColors.primary.withOpacity(0.6), width: 1.5),
        ),
        prefixIcon:
            Icon(Icons.edit_rounded, color: isDark ? AppColors.textMuted : AppColors.textLight, size: 18),
        counterStyle:
            TextStyle(color: isDark ? AppColors.textMuted : AppColors.textLight, fontSize: 11),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildRecipientsRow(bool isDark, AppLocalizations l10n) {
    final friendsCount = context.watch<FriendProvider>().friends.length;
    return Row(
      children: [
        Icon(Icons.group_rounded, color: isDark ? AppColors.textMuted : AppColors.textLight, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
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
    );
  }

  // ── Action buttons ─────────────────────────────────────────────────────────

  Widget _buildActionButtons(AppLocalizations l10n) {
    return _SendButton(
      enabled: _imageBytes != null && !_isLoading && !_isUploading,
      isUploading: _isUploading,
      onSend: () async {
        setState(() {
          _isUploading = true;
        });

        try {
          final caption = _captionController.text.trim().isNotEmpty
              ? _captionController.text.trim()
              : null;

          // Gọi hàm mới của FeedProvider (đã tích hợp Repository API)
          final newPhoto = await context.read<FeedProvider>().addNewMoment(_imageBytes!, caption);
          
          if (newPhoto != null) {
            final now = DateTime.now();
            final friendsCount = context.read<FriendProvider>().friends.length;
            final newHistoryPhoto = DummyHistoryPhoto(
              id: newPhoto.id,
              imageUrl: newPhoto.imageUrl,
              imageBytes: _imageBytes,
              sentAt: formatMomentTime(now, l10n: AppLocalizations.of(context)),
              sentDate: now,
              caption: caption,
              recipientCount: friendsCount,
              reactionCount: 0,
            );
            context.read<HistoryProvider>().addNewMoment(newHistoryPhoto);
          }

          // Làm mới dữ liệu feed sau khi upload
          if (mounted) {
            await context.read<FeedProvider>().fetchNewPhotos();
            _showSentSnackBar(l10n);
          }
        } catch (e) {
          // Lỗi sẽ được ErrorInterceptor bắt và hiển thị SnackBar
        } finally {
          if (mounted) {
            setState(() {
              _isUploading = false;
            });
          }
        }
      },
    );
  }

  void _showSentSnackBar(AppLocalizations l10n) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Text(l10n.cameraPhotoSent,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
      ),
    );
    _clearImage();
    // Chỉ đóng nếu CameraPanel đang nằm trong một Modal (như trên Mobile)
    // Trên Desktop, CameraPanel được nhúng trực tiếp nên không được pop()
    if (mounted) {
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      }
    }
  }
}

// ── Animated send button ───────────────────────────────────────────────────────
class _SendButton extends StatefulWidget {
  final bool enabled;
  final bool isUploading;
  final VoidCallback? onSend;

  const _SendButton({
    required this.enabled,
    this.isUploading = false,
    this.onSend,
  });

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final l10n = AppLocalizations.of(context)!;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()
          ..translate(
            0.0,
            _isHovered && widget.enabled ? -2.0 : 0.0,
            0.0,
          ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: widget.enabled
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: widget.enabled
              ? null
              : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
          boxShadow: widget.enabled && _isHovered
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.45),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.enabled ? widget.onSend : null,
            borderRadius: BorderRadius.circular(16),
            splashColor: Colors.white.withOpacity(0.15),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isUploading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  else
                    Icon(
                      Icons.send_rounded,
                      color: widget.enabled ? Colors.white : (isDark ? AppColors.textMuted : AppColors.textLight),
                      size: 20,
                    ),
                  const SizedBox(width: 10),
                  Text(
                    widget.isUploading ? l10n.cameraSending : l10n.cameraSendToFriends,
                    style: TextStyle(
                      color: widget.enabled ? Colors.white : (isDark ? AppColors.textMuted : AppColors.textLight),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
