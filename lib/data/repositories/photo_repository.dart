import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/dummy_data.dart';

class _UserCacheEntry {
  final String fullName;
  final String avatarUrl;
  final DateTime fetchedAt;

  _UserCacheEntry({
    required this.fullName,
    required this.avatarUrl,
    required this.fetchedAt,
  });
}

class _PhotoWithDate {
  final DummyPhoto photo;
  final DateTime date;
  _PhotoWithDate(this.photo, this.date);
}

class PhotoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static final Map<String, _UserCacheEntry> _userCache = {};

  /// Xoá bộ nhớ đệm user để tải lại profile mới
  void clearUserCache() {
    _userCache.clear();
  }

  /// Phân tách danh sách thành các danh sách con có kích thước size
  List<List<T>> _partitionList<T>(List<T> list, int size) {
    List<List<T>> chunks = [];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(list.sublist(i, i + size > list.length ? list.length : i + size));
    }
    return chunks;
  }

  /// Lấy Stream realtime của Feed ảnh (không giới hạn whereIn, có cache user)
  Stream<List<DummyPhoto>> getFeedPhotosStream() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    late StreamController<List<DummyPhoto>> controller;
    StreamSubscription? friendshipsSub;
    List<StreamSubscription> momentsSubs = [];

    controller = StreamController<List<DummyPhoto>>(
      onListen: () {
        friendshipsSub = _firestore.collection('friendships')
            .where('status', isEqualTo: 'accepted')
            .where(Filter.or(
              Filter('requesterId', isEqualTo: currentUserId),
              Filter('receiverId', isEqualTo: currentUserId)
            ))
            .snapshots()
            .listen((friendshipsSnapshot) {
              // 1. Thu thập ID bạn bè
              final friendIds = friendshipsSnapshot.docs.map((doc) {
                final data = doc.data();
                return data['requesterId'] == currentUserId
                    ? data['receiverId'] as String
                    : data['requesterId'] as String;
              }).toList();

              // Thêm chính mình vào feed
              friendIds.add(currentUserId);

              // 2. Hủy các sub-subscription moments cũ để tránh trùng lặp/leak
              for (var sub in momentsSubs) {
                sub.cancel();
              }
              momentsSubs.clear();

              // 3. Phân tách danh sách thành các nhóm nhỏ (tối đa 30 phần tử) để tránh giới hạn whereIn của Firestore
              final chunks = _partitionList(friendIds, 30);
              final Map<int, List<_PhotoWithDate>> chunkPhotos = {};

              for (int i = 0; i < chunks.length; i++) {
                final chunk = chunks[i];

                final sub = _firestore.collection('moments')
                    .where('userId', whereIn: chunk)
                    .orderBy('createdAt', descending: true)
                    .limit(20)
                    .snapshots()
                    .listen((momentsSnapshot) async {
                      List<_PhotoWithDate> photosWithDate = [];
                      for (var doc in momentsSnapshot.docs) {
                        final data = doc.data();
                        final userId = data['userId'] as String;
                        final Timestamp? timestamp = data['createdAt'];
                        final DateTime sentDate = timestamp?.toDate() ?? DateTime.now();

                        // Lấy thông tin user (Avatar & Tên hiển thị) có bộ nhớ đệm
                        final String senderName;
                        final String senderAvatar;

                        final now = DateTime.now();
                        final cached = _userCache[userId];
                        if (cached != null && now.difference(cached.fetchedAt) < const Duration(minutes: 5)) {
                          senderName = cached.fullName;
                          senderAvatar = cached.avatarUrl;
                        } else {
                          final userDoc = await _firestore.collection('users').doc(userId).get();
                          final userData = userDoc.data() ?? {};
                          senderName = userData['fullName'] ?? 'Unknown User';
                          senderAvatar = userData['avatarUrl'] ?? '';
                          _userCache[userId] = _UserCacheEntry(
                            fullName: senderName,
                            avatarUrl: senderAvatar,
                            fetchedAt: now,
                          );
                        }

                        photosWithDate.add(_PhotoWithDate(
                          DummyPhoto(
                            id: doc.id,
                            imageUrl: data['imageUrl'] ?? '',
                            senderName: senderName,
                            senderAvatar: senderAvatar,
                            timeAgo: 'Recently',
                            caption: data['caption'],
                            reactionCount: data['reactionCount'] ?? 0,
                          ),
                          sentDate,
                        ));
                      }

                      chunkPhotos[i] = photosWithDate;

                      // Gộp tất cả các chunk và sắp xếp theo thời gian mới nhất
                      List<_PhotoWithDate> merged = [];
                      for (var list in chunkPhotos.values) {
                        merged.addAll(list);
                      }
                      merged.sort((a, b) => b.date.compareTo(a.date));

                      // Trả về tối đa 20 ảnh mới nhất trên feed
                      final result = merged.take(20).map((e) => e.photo).toList();

                      if (!controller.isClosed) {
                        controller.add(result);
                      }
                    }, onError: (err) {
                      if (!controller.isClosed) {
                        controller.addError(err);
                      }
                    });

                momentsSubs.add(sub);
              }
            }, onError: (err) {
              if (!controller.isClosed) {
                controller.addError(err);
              }
            });
      },
      onCancel: () {
        friendshipsSub?.cancel();
        for (var sub in momentsSubs) {
          sub.cancel();
        }
        momentsSubs.clear();
      },
    );

    return controller.stream;
  }


  /// Lấy danh sách ảnh cho Feed
  Future<List<DummyPhoto>> getFeedPhotos() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return [];

      // Lấy danh sách bạn bè (Status == Accepted)
      final friendships = await _firestore.collection('friendships')
          .where('status', isEqualTo: 'accepted')
          .where(Filter.or(
            Filter('requesterId', isEqualTo: currentUserId),
            Filter('receiverId', isEqualTo: currentUserId)
          ))
          .get();

      final friendIds = friendships.docs.map((doc) {
        final data = doc.data();
        return data['requesterId'] == currentUserId ? data['receiverId'] : data['requesterId'];
      }).toList();

      // Thêm chính mình vào feed
      friendIds.add(currentUserId);

      // Lấy ảnh từ Firestore
      final snapshot = await _firestore.collection('moments')
          .where('userId', whereIn: friendIds)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      List<DummyPhoto> photos = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        // Lấy info user gửi ảnh
        final userDoc = await _firestore.collection('users').doc(data['userId']).get();
        final userData = userDoc.data() ?? {};

        photos.add(DummyPhoto(
          id: doc.id,
          imageUrl: data['imageUrl'] ?? '',
          senderName: userData['fullName'] ?? 'Unknown User',
          senderAvatar: userData['avatarUrl'] ?? '',
          timeAgo: 'Recently', // Có thể dùng intl để format timestamp
          caption: data['caption'],
          reactionCount: data['reactionCount'] ?? 0,
        ));
      }
      return photos;
    } catch (e) {
      throw Exception('Failed to fetch feed photos: $e');
    }
  }

  /// Lấy danh sách ảnh lịch sử của người dùng
  Future<List<DummyHistoryPhoto>> getHistoryPhotos() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return [];

      final snapshot = await _firestore.collection('moments')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final Timestamp? timestamp = data['createdAt'];
        final DateTime sentDate = timestamp?.toDate() ?? DateTime.now();

        return DummyHistoryPhoto(
          id: doc.id,
          imageUrl: data['imageUrl'] ?? '',
          sentAt: '${sentDate.hour}:${sentDate.minute}',
          sentDate: sentDate,
          caption: data['caption'],
          recipientCount: 0, // Firestore không track cái này mặc định
          reactionCount: data['reactionCount'] ?? 0,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch history photos: $e');
    }
  }

  /// Upload photo to Firebase Storage and Save metadata to Firestore
  Future<DummyPhoto> uploadPhoto(Uint8List imageBytes, String? caption) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception('User not authenticated');

    final fileName = 'moments/$currentUserId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child(fileName);

    // Upload to Storage
    final uploadTask = await ref.putData(imageBytes, SettableMetadata(contentType: 'image/jpeg'));
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    // Save to Firestore
    final docRef = await _firestore.collection('moments').add({
      'userId': currentUserId,
      'imageUrl': downloadUrl,
      'caption': caption,
      'createdAt': FieldValue.serverTimestamp(),
      'reactionCount': 0,
    });

    // Lấy thông tin user hiện tại
    final userDoc = await _firestore.collection('users').doc(currentUserId).get();
    final userData = userDoc.data() ?? {};

    // Push notification task to /notifications_queue
    try {
      await _firestore.collection('notifications_queue').add({
        'senderId': currentUserId,
        'senderName': userData['fullName'] ?? 'A friend',
        'imageUrl': downloadUrl,
        'caption': caption,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      // Catch and log error to avoid failing the upload flow
      debugPrint('Failed to queue notification: $e');
    }

    // Gửi thông báo in-app cho tất cả bạn bè
    try {
      final friendships = await _firestore.collection('friendships')
          .where('status', isEqualTo: 'accepted')
          .where(Filter.or(
            Filter('requesterId', isEqualTo: currentUserId),
            Filter('receiverId', isEqualTo: currentUserId)
          ))
          .get();

      for (var doc in friendships.docs) {
        final data = doc.data();
        final friendId = data['requesterId'] == currentUserId ? data['receiverId'] : data['requesterId'];
        
        await _firestore.collection('notifications').add({
          'receiverId': friendId,
          'senderId': currentUserId,
          'senderName': userData['fullName'] ?? 'A friend',
          'senderAvatar': userData['avatarUrl'] ?? '',
          'type': 'moment_posted',
          'title': 'New Moment Posted',
          'body': '${userData['fullName'] ?? 'A friend'} posted a new photo.',
          'imageUrl': downloadUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
    } catch (e) {
      debugPrint('Failed to create in-app notifications: $e');
    }

    return DummyPhoto(
      id: docRef.id,
      imageUrl: downloadUrl,
      imageBytes: imageBytes,
      senderName: userData['fullName'] ?? 'You',
      senderAvatar: userData['avatarUrl'] ?? '',
      timeAgo: 'Just now',
      caption: caption,
      reactionCount: 0,
    );
  }

  /// Xoá ảnh
  Future<void> deletePhoto(String id) async {
    try {
      // 1. Lấy thông tin tài liệu từ Firestore để lấy imageUrl
      final doc = await _firestore.collection('moments').doc(id).get();
      
      if (doc.exists) {
        final data = doc.data();
        final imageUrl = data?['imageUrl'] as String?;
        
        // 2. Xóa file trong Firebase Storage
        if (imageUrl != null && imageUrl.isNotEmpty) {
          try {
            // Chỉ cố gắng xóa nếu URL chứa pattern của Firebase Storage
            // (Đề phòng trường hợp dummy data dùng URL bên ngoài như picsum.photos)
            if (imageUrl.contains('firebasestorage.googleapis.com')) {
              final ref = _storage.refFromURL(imageUrl);
              await ref.delete();
            }
          } catch (e) {
            // Không chặn tiến trình xóa Firestore nếu Storage gặp lỗi (ví dụ: file không tồn tại, network error)
            debugPrint('Firebase Storage delete error (ignored): $e');
          }
        }
      }
      
      // 3. Xóa document trong Firestore
      await _firestore.collection('moments').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete photo: $e');
    }
  }
}
