import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class FriendsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Tìm kiếm người dùng qua username hoặc fullName
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      final trimmedQuery = query.trim();
      if (trimmedQuery.isEmpty) return [];

      QuerySnapshot<Map<String, dynamic>> snapshot;
      final isCode = RegExp(r'^[a-zA-Z0-9]{6}$').hasMatch(trimmedQuery);

      if (isCode) {
        snapshot = await _firestore.collection('users')
            .where('shareCode', isEqualTo: trimmedQuery.toUpperCase())
            .limit(20)
            .get();

        if (snapshot.docs.isEmpty) {
          snapshot = await _firestore.collection('users')
              .where('username', isGreaterThanOrEqualTo: trimmedQuery)
              .where('username', isLessThanOrEqualTo: '$trimmedQuery\uf8ff')
              .limit(20)
              .get();
        }
      } else {
        snapshot = await _firestore.collection('users')
            .where('username', isGreaterThanOrEqualTo: trimmedQuery)
            .where('username', isLessThanOrEqualTo: '$trimmedQuery\uf8ff')
            .limit(20)
            .get();
      }

      List<UserModel> users = [];
      for (var doc in snapshot.docs) {
        if (doc.id == currentUserId) continue;
        final data = doc.data();
        
        // Kiểm tra trạng thái quan hệ
        final rel = await _firestore.collection('friendships')
            .where(Filter.or(
              Filter.and(Filter('requesterId', isEqualTo: currentUserId), Filter('receiverId', isEqualTo: doc.id)),
              Filter.and(Filter('requesterId', isEqualTo: doc.id), Filter('receiverId', isEqualTo: currentUserId))
            ))
            .get();

        bool isFriend = false;
        bool isRequested = false;

        if (rel.docs.isNotEmpty) {
          final relData = rel.docs.first.data();
          if (relData['status'] == 'accepted') {
            isFriend = true;
          } else if (relData['requesterId'] == currentUserId) {
            isRequested = true;
          }
        }

        users.add(UserModel(
          id: doc.id,
          username: data['username'] ?? '',
          fullName: data['fullName'] ?? '',
          avatarUrl: data['avatarUrl'] ?? '',
          isFriend: isFriend,
          isRequested: isRequested,
          isOnline: data['isOnline'] ?? false,
          lastActive: data['lastActive'] is Timestamp
              ? (data['lastActive'] as Timestamp).toDate()
              : null,
        ));
      }
      return users;
    } catch (e) {
      rethrow;
    }
  }

  /// Gửi lời mời kết bạn
  Future<void> sendFriendRequest(String receiverId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) throw Exception('User not authenticated');

      // 1. Kiểm tra xem đối phương đã gửi yêu cầu kết bạn cho mình chưa (reverse request)
      final reverseId = '${receiverId}_$currentUserId';
      final reverseDoc = await _firestore.collection('friendships').doc(reverseId).get();

      if (reverseDoc.exists) {
         final data = reverseDoc.data();
         if (data != null && data['status'] == 'pending') {
           // Nếu có yêu cầu ngược lại đang chờ, chấp nhận nó luôn để thành bạn bè
           await acceptFriendRequest(reverseId);
           return;
         }
      }

      // 2. Nếu chưa có yêu cầu ngược lại, tạo yêu cầu mới với ID có cấu trúc: requesterId_receiverId
      final friendshipId = '${currentUserId}_$receiverId';
      await _firestore.collection('friendships').doc(friendshipId).set({
        'requesterId': currentUserId,
        'receiverId': receiverId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Tạo thông báo gửi yêu cầu kết bạn
      try {
        final requesterDoc = await _firestore.collection('users').doc(currentUserId).get();
        final requesterData = requesterDoc.data() ?? {};
        final notificationId = 'friend_request_${currentUserId}_$receiverId';
        await _firestore.collection('notifications').doc(notificationId).set({
          'receiverId': receiverId,
          'senderId': currentUserId,
          'senderName': requesterData['fullName'] ?? 'Someone',
          'senderAvatar': requesterData['avatarUrl'] ?? '',
          'type': 'friend_request',
          'title': 'New Friend Request',
          'body': '${requesterData['fullName'] ?? 'Someone'} sent you a friend request.',
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      } catch (e) {
        debugPrint('Error creating notification for friend request: $e');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Lấy danh sách lời mời đang chờ
  Future<List<FriendRequestModel>> getFriendRequests() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      final snapshot = await _firestore.collection('friendships')
          .where('receiverId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      List<FriendRequestModel> requests = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final requesterDoc = await _firestore.collection('users').doc(data['requesterId']).get();
        final requesterData = requesterDoc.data() ?? {};

        requests.add(FriendRequestModel(
          id: doc.id, // ID của bản ghi friendship
          requesterId: data['requesterId'] ?? '',
          requesterName: requesterData['fullName'] ?? 'Unknown',
          requesterAvatar: requesterData['avatarUrl'] ?? '',
        ));
      }
      return requests;
    } catch (e) {
      rethrow;
    }
  }

  /// Chấp nhận kết bạn
  Future<void> acceptFriendRequest(String requestId) async {
    try {
      await _firestore.collection('friendships').doc(requestId).update({
        'status': 'accepted',
      });

      // Gửi thông báo cho người gửi yêu cầu ban đầu
      final currentUserId = _auth.currentUser?.uid;
      final doc = await _firestore.collection('friendships').doc(requestId).get();
      if (doc.exists && currentUserId != null) {
        final data = doc.data();
        if (data != null) {
          final requesterId = data['requesterId'];
          final receiverId = data['receiverId'];
          final otherId = currentUserId == receiverId ? requesterId : receiverId;

          final accepterDoc = await _firestore.collection('users').doc(currentUserId).get();
          final accepterData = accepterDoc.data() ?? {};
          final notificationId = 'friend_accepted_${currentUserId}_$otherId';

          await _firestore.collection('notifications').doc(notificationId).set({
            'receiverId': otherId,
            'senderId': currentUserId,
            'senderName': accepterData['fullName'] ?? 'Someone',
            'senderAvatar': accepterData['avatarUrl'] ?? '',
            'type': 'friend_accepted',
            'title': 'Friend Request Accepted',
            'body': '${accepterData['fullName'] ?? 'Someone'} accepted your friend request.',
            'createdAt': FieldValue.serverTimestamp(),
            'isRead': false,
          });
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Từ chối kết bạn
  Future<void> rejectFriendRequest(String requestId) async {
    try {
      await _firestore.collection('friendships').doc(requestId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Xóa bạn bè (Hủy kết bạn)
  Future<void> removeFriend(String friendId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) throw Exception('User not authenticated');

      final docId1 = '${currentUserId}_$friendId';
      final docId2 = '${friendId}_$currentUserId';

      final doc1 = await _firestore.collection('friendships').doc(docId1).get();
      if (doc1.exists) {
        await _firestore.collection('friendships').doc(docId1).delete();
      } else {
        final doc2 = await _firestore.collection('friendships').doc(docId2).get();
        if (doc2.exists) {
          await _firestore.collection('friendships').doc(docId2).delete();
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Lấy danh sách bạn bè
  Future<List<UserModel>> getFriendsList() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      final snapshot = await _firestore.collection('friendships')
          .where('status', isEqualTo: 'accepted')
          .where(Filter.or(
            Filter('requesterId', isEqualTo: currentUserId),
            Filter('receiverId', isEqualTo: currentUserId)
          ))
          .get();

      List<UserModel> friends = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final friendId = data['requesterId'] == currentUserId ? data['receiverId'] : data['requesterId'];
        
        final friendDoc = await _firestore.collection('users').doc(friendId).get();
        final friendData = friendDoc.data() ?? {};

        friends.add(UserModel(
          id: friendId,
          username: friendData['username'] ?? '',
          fullName: friendData['fullName'] ?? '',
          avatarUrl: friendData['avatarUrl'] ?? '',
          isFriend: true,
          isOnline: friendData['isOnline'] ?? false,
          lastActive: friendData['lastActive'] is Timestamp
              ? (friendData['lastActive'] as Timestamp).toDate()
              : null,
        ));
      }
      return friends;
    } catch (e) {
      rethrow;
    }
  }
}
