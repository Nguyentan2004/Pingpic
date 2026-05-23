import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/dummy_data.dart';
import '../../core/utils/time_formatter.dart';
import '../../core/services/in_app_notification_service.dart';
import '../models/comment_model.dart';

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


  /// Lấy Stream realtime của Feed ảnh (không giới hạn whereIn, có cache user)
  Stream<List<DummyPhoto>> getFeedPhotosStream() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    late StreamController<List<DummyPhoto>> controller;
    StreamSubscription? friendshipsSub;
    final Map<String, StreamSubscription> momentsSubs = {};
    final Map<String, List<_PhotoWithDate>> userPhotos = {};

    void emitMergedPhotos() {
      if (controller.isClosed) return;
      List<_PhotoWithDate> merged = [];
      for (var list in userPhotos.values) {
        merged.addAll(list);
      }
      merged.sort((a, b) => b.date.compareTo(a.date));
      final result = merged.take(20).map((e) => e.photo).toList();
      debugPrint('FEED_DEBUG: filtered count = ${result.length}');
      controller.add(result);
    }

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
              }).toSet();

              // Thêm chính mình vào feed
              friendIds.add(currentUserId);
              debugPrint('FEED_DEBUG: friendIds = $friendIds');

              // 2. Xác định xem ai đã bị xóa khỏi bạn bè
              final removedUids = momentsSubs.keys.where((uid) => !friendIds.contains(uid)).toList();
              for (final uid in removedUids) {
                momentsSubs[uid]?.cancel();
                momentsSubs.remove(uid);
                userPhotos.remove(uid);
              }

              // Nếu có bạn bè bị xóa, cập nhật lại feed ngay
              if (removedUids.isNotEmpty) {
                emitMergedPhotos();
              }

              // 3. Lắng nghe moments của từng user mới chưa có trong momentsSubs
              for (final uid in friendIds) {
                if (momentsSubs.containsKey(uid)) {
                  continue;
                }

                final sub = _firestore.collection('moments')
                    .where('userId', isEqualTo: uid)
                    .snapshots()
                    .listen((momentsSnapshot) async {
                      List<_PhotoWithDate> photosWithDate = [];
                      for (var doc in momentsSnapshot.docs) {
                        final data = doc.data();
                        final String mUserId = data['userId'] ?? '';
                        debugPrint('FEED_DEBUG: moment.userId = $mUserId, docId = ${doc.id}');
                        final Timestamp? timestamp = data['createdAt'];
                        final DateTime sentDate = timestamp?.toDate() ?? DateTime.now();

                        // Lấy thông tin user (Avatar & Tên hiển thị) có bộ nhớ đệm
                        final String senderName;
                        final String senderAvatar;

                        final now = DateTime.now();
                        final cached = _userCache[uid];
                        if (cached != null && now.difference(cached.fetchedAt) < const Duration(minutes: 5)) {
                          senderName = cached.fullName;
                          senderAvatar = cached.avatarUrl;
                        } else {
                          final userDoc = await _firestore.collection('users').doc(uid).get();
                          final userData = userDoc.data() ?? {};
                          senderName = userData['fullName'] ?? 'Unknown User';
                          senderAvatar = userData['avatarUrl'] ?? '';
                          _userCache[uid] = _UserCacheEntry(
                            fullName: senderName,
                            avatarUrl: senderAvatar,
                            fetchedAt: now,
                          );
                        }

                        photosWithDate.add(_PhotoWithDate(
                          DummyPhoto(
                            id: doc.id,
                            imageUrl: data['imageUrl'] ?? '',
                            userId: uid,
                            senderName: senderName,
                            senderAvatar: senderAvatar,
                            timeAgo: formatMomentTime(sentDate),
                            caption: data['caption'],
                            reactionCount: data['reactionCount'] ?? 0,
                            likes: List<String>.from(data['likes'] ?? []),
                            createdAt: sentDate,
                          ),
                          sentDate,
                        ));
                      }

                      userPhotos[uid] = photosWithDate;
                      emitMergedPhotos();
                    }, onError: (err) {
                      debugPrint('Error loading feed for user $uid: $err');
                    });

                momentsSubs[uid] = sub;
              }
            }, onError: (err) {
              if (!controller.isClosed) {
                controller.addError(err);
              }
            });
      },
      onCancel: () {
        friendshipsSub?.cancel();
        for (var sub in momentsSubs.values) {
          sub.cancel();
        }
        momentsSubs.clear();
        userPhotos.clear();
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
        return (data['requesterId'] == currentUserId ? data['receiverId'] : data['requesterId']) as String;
      }).toList();

      // Thêm chính mình vào feed
      friendIds.add(currentUserId);

      // Lấy ảnh từ Firestore cho từng user và gộp lại
      List<_PhotoWithDate> allPhotos = [];
      for (final uid in friendIds) {
        final snapshot = await _firestore.collection('moments')
            .where('userId', isEqualTo: uid)
            .get();

        final userDoc = await _firestore.collection('users').doc(uid).get();
        final userData = userDoc.data() ?? {};
        final senderName = userData['fullName'] ?? 'Unknown User';
        final senderAvatar = userData['avatarUrl'] ?? '';

        for (var doc in snapshot.docs) {
          final data = doc.data();
          final Timestamp? timestamp = data['createdAt'];
          final DateTime sentDate = timestamp?.toDate() ?? DateTime.now();

          allPhotos.add(_PhotoWithDate(
            DummyPhoto(
              id: doc.id,
              imageUrl: data['imageUrl'] ?? '',
              userId: uid,
              senderName: senderName,
              senderAvatar: senderAvatar,
              timeAgo: formatMomentTime(sentDate),
              caption: data['caption'],
              reactionCount: data['reactionCount'] ?? 0,
              likes: List<String>.from(data['likes'] ?? []),
              createdAt: sentDate,
            ),
            sentDate,
          ));
        }
      }

      allPhotos.sort((a, b) => b.date.compareTo(a.date));
      return allPhotos.take(20).map((e) => e.photo).toList();
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
          .get();

      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        final Timestamp? timestamp = data['createdAt'];
        final DateTime sentDate = timestamp?.toDate() ?? DateTime.now();

        return DummyHistoryPhoto(
          id: doc.id,
          imageUrl: data['imageUrl'] ?? '',
          sentAt: formatMomentTime(sentDate),
          sentDate: sentDate,
          caption: data['caption'],
          recipientCount: 0, // Firestore không track cái này mặc định
          reactionCount: data['reactionCount'] ?? 0,
        );
      }).toList();
      list.sort((a, b) => b.sentDate.compareTo(a.sentDate));
      return list;
    } catch (e) {
      throw Exception('Failed to fetch history photos: $e');
    }
  }

  /// Lấy Stream realtime danh sách ảnh lịch sử của người dùng
  Stream<List<DummyHistoryPhoto>> getHistoryPhotosStream(String userId) {
    return _firestore.collection('moments')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) {
            final data = doc.data();
            final Timestamp? timestamp = data['createdAt'];
            final DateTime sentDate = timestamp?.toDate() ?? DateTime.now();

            return DummyHistoryPhoto(
              id: doc.id,
              imageUrl: data['imageUrl'] ?? '',
              sentAt: formatMomentTime(sentDate),
              sentDate: sentDate,
              caption: data['caption'],
              recipientCount: 0,
              reactionCount: data['reactionCount'] ?? 0,
            );
          }).toList();
          list.sort((a, b) => b.sentDate.compareTo(a.sentDate));
          return list;
        });
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
      'likes': [],
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
        final notificationId = 'moment_${currentUserId}_${docRef.id}_$friendId';
        
        await _firestore.collection('notifications').doc(notificationId).set({
          'receiverId': friendId,
          'senderId': currentUserId,
          'senderName': userData['fullName'] ?? 'A friend',
          'senderAvatar': userData['avatarUrl'] ?? '',
          'type': 'moment_posted',
          'title': 'New Moment Posted',
          'body': '${userData['fullName'] ?? 'A friend'} posted a new photo.',
          'imageUrl': downloadUrl,
          'postId': docRef.id,
          'postOwnerId': currentUserId,
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
      userId: currentUserId,
      senderName: userData['fullName'] ?? 'You',
      senderAvatar: userData['avatarUrl'] ?? '',
      timeAgo: 'Just now',
      caption: caption,
      reactionCount: 0,
      likes: const [],
      createdAt: DateTime.now(),
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

  /// Toggle like/reaction on a moment
  Future<void> toggleLike(String momentId, bool currentlyLiked) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) throw Exception('User not authenticated');

      final docRef = _firestore.collection('moments').doc(momentId);

      // Fetch post owner and imageUrl for notification
      final momentDoc = await docRef.get();
      final momentData = momentDoc.data() ?? {};
      final postOwnerId = momentData['userId'] as String? ?? '';
      final postImageUrl = momentData['imageUrl'] as String? ?? '';

      if (currentlyLiked) {
        // If already liked, unlike it: remove uid from likes and decrement reactionCount
        await docRef.update({
          'likes': FieldValue.arrayRemove([currentUserId]),
          'reactionCount': FieldValue.increment(-1),
        });
        // Remove like notification
        if (postOwnerId.isNotEmpty) {
          await InAppNotificationService.sendLikeNotification(
            momentId: momentId,
            postOwnerId: postOwnerId,
            postImageUrl: postImageUrl,
            like: false,
          );
        }
      } else {
        // If not liked yet, like it: add uid to likes and increment reactionCount
        await docRef.update({
          'likes': FieldValue.arrayUnion([currentUserId]),
          'reactionCount': FieldValue.increment(1),
        });
        // Send like notification
        if (postOwnerId.isNotEmpty) {
          await InAppNotificationService.sendLikeNotification(
            momentId: momentId,
            postOwnerId: postOwnerId,
            postImageUrl: postImageUrl,
            like: true,
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
    }
  }

  /// Get real-time stream of comments for a moment, filtered for the current user
  Stream<List<CommentModel>> getCommentsStream(String momentId) {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('moments')
        .doc(momentId)
        .collection('comments')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => CommentModel.fromFirestore(doc))
              .toList();
          // Sort comments in-memory by createdAt ascending (for message thread layout)
          list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return list;
        });
  }

  /// Add a private comment on a moment
  Future<void> addComment(String momentId, String receiverId, String text) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) throw Exception('User not authenticated');

      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      final userData = userDoc.data() ?? {};

      // Fetch post owner + imageUrl for notification
      final momentDoc = await _firestore.collection('moments').doc(momentId).get();
      final momentData = momentDoc.data() ?? {};
      final postOwnerId = momentData['userId'] as String? ?? '';
      final postImageUrl = momentData['imageUrl'] as String? ?? '';

      // Write comment
      final commentRef = await _firestore
          .collection('moments')
          .doc(momentId)
          .collection('comments')
          .add({
        'senderId': currentUserId,
        'receiverId': receiverId,
        'participants': [currentUserId, receiverId],
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        'senderName': userData['fullName'] ?? 'Someone',
        'senderAvatar': userData['avatarUrl'] ?? '',
      });

      // Fire notification:
      // If the sender IS the post owner, they are replying to a commenter → send reply notif
      // Otherwise, the sender is commenting on someone else's post → send comment notif
      if (currentUserId == postOwnerId) {
        // Post owner replying to commenter (receiverId is the original commenter)
        await InAppNotificationService.sendReplyNotification(
          momentId: momentId,
          postOwnerId: postOwnerId,
          postImageUrl: postImageUrl,
          originalCommenterId: receiverId,
          replyCommentId: commentRef.id,
        );
      } else if (postOwnerId.isNotEmpty) {
        // Someone commenting on the post owner's moment
        await InAppNotificationService.sendCommentNotification(
          momentId: momentId,
          postOwnerId: postOwnerId,
          postImageUrl: postImageUrl,
          commentId: commentRef.id,
        );
      }
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

}
