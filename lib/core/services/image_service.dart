import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'image_compressor.dart';

// ── Result model ──────────────────────────────────────────────────────────────
/// Kết quả trả về sau khi người dùng chọn/chụp ảnh thành công.
class ImagePickResult {
  /// Raw bytes của ảnh — dùng Image.memory(bytes) để hiển thị trên Web.
  final Uint8List bytes;

  /// Tên file gốc (VD: "photo.jpg")
  final String fileName;

  /// MIME type (VD: "image/jpeg", "image/png")
  final String mimeType;

  /// Kích thước file tính bằng bytes
  final int fileSize;

  const ImagePickResult({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
  });

  /// Kích thước file được format dạng đọc được (VD: "2.3 MB")
  String get fileSizeFormatted {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

// ── Exception types ───────────────────────────────────────────────────────────
sealed class ImageServiceException implements Exception {
  const ImageServiceException();
}

/// Người dùng từ chối cấp quyền camera / storage
class CameraPermissionDeniedException extends ImageServiceException {
  const CameraPermissionDeniedException();

  @override
  String toString() =>
      'Camera permission denied. Please allow camera access in your browser settings.';
}

/// File được chọn quá lớn
class FileTooLargeException extends ImageServiceException {
  final int maxMb;
  const FileTooLargeException(this.maxMb);

  @override
  String toString() => 'File is too large. Maximum allowed size is ${maxMb}MB.';
}

/// Định dạng file không được hỗ trợ
class UnsupportedFormatException extends ImageServiceException {
  final String mimeType;
  const UnsupportedFormatException(this.mimeType);

  @override
  String toString() =>
      'Unsupported file format: $mimeType. Please use JPG, PNG, or WEBP.';
}

/// Lỗi không xác định
class UnknownImageException extends ImageServiceException {
  final String message;
  const UnknownImageException(this.message);

  @override
  String toString() => 'Image error: $message';
}

// ── ImageService ──────────────────────────────────────────────────────────────
/// Service xử lý chụp ảnh và chọn ảnh từ thiết bị.
///
/// Web-compatible: trả về [ImagePickResult] với raw bytes thay vì file path.
///
/// Sử dụng:
/// ```dart
/// try {
///   final result = await ImageService.takePhoto();
///   if (result != null) {
///     // result.bytes — dùng Image.memory(result.bytes)
///   }
/// } on CameraPermissionDeniedException catch (e) {
///   // Hiển thị thông báo hướng dẫn cấp quyền
/// } on ImageServiceException catch (e) {
///   // Các lỗi khác
/// }
/// ```
class ImageService {
  ImageService._(); // Không khởi tạo — chỉ dùng static methods

  static final ImagePicker _picker = ImagePicker();

  /// Giới hạn kích thước file tối đa: 10 MB
  static const int _maxFileSizeBytes = 10 * 1024 * 1024;

  /// Các MIME type được hỗ trợ
  static const Set<String> _supportedMimeTypes = {
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
    'image/heic',
    'image/heif',
  };

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Mở webcam của trình duyệt để chụp ảnh.
  ///
  /// Trên Web: trình duyệt sẽ hỏi xin quyền truy cập camera.
  /// Nếu từ chối → ném [CameraPermissionDeniedException].
  ///
  /// Trả về [ImagePickResult] nếu thành công, null nếu người dùng huỷ.
  static Future<ImagePickResult?> takePhoto() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,      // Giới hạn chiều rộng tối ưu cho Mobile/Web
        maxHeight: 1920,     // Giới hạn chiều cao tối ưu cho Mobile/Web
        imageQuality: 70,    // Nén chất lượng xuống 70% để tiết kiệm băng thông
        preferredCameraDevice: CameraDevice.front, // Selfie cam mặc định
      );

      if (file == null) return null; // Người dùng huỷ

      return await _processXFile(file);
    } on Exception catch (e) {
      throw _mapException(e);
    }
  }

  /// Mở hộp thoại chọn file ảnh từ máy tính / thư viện ảnh.
  ///
  /// Trên Web: mở file picker của trình duyệt, chỉ cho phép chọn file ảnh.
  ///
  /// Trả về [ImagePickResult] nếu thành công, null nếu người dùng huỷ.
  static Future<ImagePickResult?> pickFromGallery() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 70,
      );

      if (file == null) return null; // Người dùng huỷ / đóng dialog

      return await _processXFile(file);
    } on Exception catch (e) {
      throw _mapException(e);
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Đọc XFile thành bytes và nén/resize tối ưu.
  static Future<ImagePickResult> _processXFile(XFile file) async {
    final Uint8List rawBytes = await file.readAsBytes();

    // Validate kích thước file gốc
    if (rawBytes.length > _maxFileSizeBytes) {
      throw const FileTooLargeException(10);
    }

    // Xác định MIME type gốc
    final mimeType = file.mimeType ?? _inferMimeType(file.name);

    // Validate định dạng gốc
    final normalizedMime = mimeType.toLowerCase();
    if (!_supportedMimeTypes.any((m) => normalizedMime.contains(m.split('/').last))) {
      throw UnsupportedFormatException(mimeType);
    }

    // Nén và resize ảnh về chất lượng tối ưu trước khi sử dụng/upload
    final Uint8List compressedBytes = await compressAndResizeImage(
      rawBytes,
      maxWidth: 1080,
      maxHeight: 1080,
      quality: 70,
    );

    // Ảnh sau khi nén bằng HTML Canvas sẽ có định dạng image/jpeg
    final baseName = file.name.contains('.')
        ? file.name.substring(0, file.name.lastIndexOf('.'))
        : file.name;

    return ImagePickResult(
      bytes: compressedBytes,
      fileName: '$baseName.jpg',
      mimeType: 'image/jpeg',
      fileSize: compressedBytes.length,
    );
  }

  /// Suy ra MIME type từ phần mở rộng tên file.
  static String _inferMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png'           => 'image/png',
      'webp'          => 'image/webp',
      'heic'          => 'image/heic',
      _               => 'image/jpeg', // Fallback
    };
  }

  /// Map lỗi platform thành [ImageServiceException].
  static ImageServiceException _mapException(Exception e) {
    final msg = e.toString().toLowerCase();

    // Các từ khoá thường xuất hiện khi bị từ chối quyền camera
    if (msg.contains('permission') ||
        msg.contains('denied') ||
        msg.contains('notallowed') ||
        msg.contains('not allowed') ||
        msg.contains('camera_access_denied')) {
      return const CameraPermissionDeniedException();
    }

    return UnknownImageException(e.toString());
  }
}
