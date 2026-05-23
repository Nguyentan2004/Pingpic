import 'package:cloud_firestore/cloud_firestore.dart';

/// Supported notification types:
/// - 'like'            : Someone liked your moment
/// - 'comment'         : Someone commented on your moment
/// - 'reply'           : Someone replied to your comment
/// - 'friend_request'  : Someone sent you a friend request
/// - 'friend_accepted' : Someone accepted your friend request
/// - 'moment_posted'   : A friend posted a new moment
class NotificationModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String receiverId;
  final String type;
  final String? postId;       // momentId for like/comment/reply/moment_posted
  final String? postOwnerId;  // UID of post owner (for navigation)
  final String? commentId;    // for reply notifications
  final String? imageUrl;     // post thumbnail
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.receiverId,
    required this.type,
    this.postId,
    this.postOwnerId,
    this.commentId,
    this.imageUrl,
    required this.createdAt,
    required this.isRead,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    DateTime created = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      created = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      created = DateTime.tryParse(data['createdAt']) ?? DateTime.now();
    }
    return NotificationModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderAvatar: data['senderAvatar'] ?? '',
      receiverId: data['receiverId'] ?? '',
      type: data['type'] ?? '',
      postId: data['postId'],
      postOwnerId: data['postOwnerId'],
      commentId: data['commentId'],
      imageUrl: data['imageUrl'],
      createdAt: created,
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'receiverId': receiverId,
      'type': type,
      if (postId != null) 'postId': postId,
      if (postOwnerId != null) 'postOwnerId': postOwnerId,
      if (commentId != null) 'commentId': commentId,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'createdAt': createdAt,
      'isRead': isRead,
    };
  }
}
