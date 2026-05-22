import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/constants/dummy_data.dart';
import '../../data/repositories/photo_repository.dart';

class FeedProvider extends ChangeNotifier {
  final PhotoRepository _photoRepo = PhotoRepository();
  StreamSubscription<List<DummyPhoto>>? _feedSubscription;
  
  // Danh sách ảnh hiển thị trên feed
  List<DummyPhoto> _photos = [];
  List<DummyPhoto> get photos => _photos;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  FeedProvider() {
    _initFeedStream();
  }

  /// Khởi tạo và lắng nghe Stream realtime từ repository
  void _initFeedStream() {
    _isLoading = true;
    notifyListeners();

    _feedSubscription = _photoRepo.getFeedPhotosStream().listen(
      (newPhotos) {
        _isLoading = false;
        // Chỉ cập nhật và thông báo rebuild khi danh sách thực sự thay đổi nội dung
        if (!_areFeedsEqual(_photos, newPhotos)) {
          _photos = newPhotos;
          notifyListeners();
        }
      },
      onError: (e) {
        _isLoading = false;
        debugPrint('Error in feed stream: $e');
        notifyListeners();
      },
    );
  }

  /// So sánh sâu nội dung hai danh sách ảnh để tránh rebuild UI thừa
  bool _areFeedsEqual(List<DummyPhoto> a, List<DummyPhoto> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].imageUrl != b[i].imageUrl ||
          a[i].caption != b[i].caption ||
          a[i].reactionCount != b[i].reactionCount ||
          a[i].senderName != b[i].senderName ||
          a[i].senderAvatar != b[i].senderAvatar) {
        return false;
      }
    }
    return true;
  }

  /// Làm mới bộ nhớ đệm user profile và tạo loading feedback trực quan
  Future<void> fetchNewPhotos() async {
    _photoRepo.clearUserCache();
    
    _isLoading = true;
    notifyListeners();

    // Giữ loading feedback ngắn (500ms) khi pull-to-refresh
    await Future.delayed(const Duration(milliseconds: 500));
    _isLoading = false;
    notifyListeners();
  }

  /// Thêm ảnh nhận được từ SignalR (giữ tương thích)
  void addPhotoFromRealtime(DummyPhoto photo) {
    if (_photos.any((p) => p.id == photo.id)) return;
    _photos.insert(0, photo);
    notifyListeners();
  }

  /// Gửi ảnh mới (Upload lên Firestore -> stream tự động cập nhật)
  Future<DummyPhoto?> addNewMoment(Uint8List imageBytes, String? caption) async {
    try {
      // Khi upload thành công, Firestore collection thay đổi
      // Stream snapshots sẽ tự động phát hiện và cập nhật Feed mà không cần tác động thủ công
      return await _photoRepo.uploadPhoto(imageBytes, caption);
    } catch (e) {
      debugPrint('Error uploading photo: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _feedSubscription?.cancel();
    super.dispose();
  }
}

