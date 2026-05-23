import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service responsible for writing in-app notification documents to Firestore.
///
/// Notification types:
///   like            → like_{senderId}_{momentId}
///   comment         → comment_{senderId}_{momentId}_{commentId}
///   reply           → reply_{senderId}_{momentId}_{commentId}
///   friend_request  → friend_request_{requesterId}_{receiverId}   (handled in FriendsRepository)
///   friend_accepted → friend_accepted_{accepterId}_{otherId}      (handled in FriendsRepository)
///   moment_posted   → moment_{senderId}_{momentId}_{friendId}     (handled in PhotoRepository)
class InAppNotificationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─────────────────────────────────────────
  // LIKE
  // ─────────────────────────────────────────

  /// Send a "like" notification to the post owner when someone likes their moment.
  /// Uses a deterministic doc ID so duplicate likes are upserted, not duplicated.
  /// If [like] is false, removes the notification (user unliked).
  static Future<void> sendLikeNotification({
    required String momentId,
    required String postOwnerId,
    required String postImageUrl,
    required bool like,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Don't notify yourself
      if (currentUser.uid == postOwnerId) return;

      final docId = 'like_${currentUser.uid}_$momentId';
      final ref = _db.collection('notifications').doc(docId);

      if (!like) {
        // User unliked — remove notification
        await ref.delete();
        return;
      }

      // Fetch sender info
      final userDoc = await _db.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data() ?? {};

      await ref.set({
        'receiverId': postOwnerId,
        'senderId': currentUser.uid,
        'senderName': userData['fullName'] ?? 'Someone',
        'senderAvatar': userData['avatarUrl'] ?? '',
        'type': 'like',
        'postId': momentId,
        'postOwnerId': postOwnerId,
        'imageUrl': postImageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      }, SetOptions(merge: false));
    } catch (e) {
      debugPrint('InAppNotificationService.sendLikeNotification error: $e');
    }
  }

  // ─────────────────────────────────────────
  // COMMENT
  // ─────────────────────────────────────────

  /// Send a "comment" notification to the post owner when someone comments.
  /// [commentId] is the Firestore doc ID of the new comment.
  static Future<void> sendCommentNotification({
    required String momentId,
    required String postOwnerId,
    required String postImageUrl,
    required String commentId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Don't notify yourself
      if (currentUser.uid == postOwnerId) return;

      final docId = 'comment_${currentUser.uid}_${momentId}_$commentId';
      final userDoc = await _db.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data() ?? {};

      await _db.collection('notifications').doc(docId).set({
        'receiverId': postOwnerId,
        'senderId': currentUser.uid,
        'senderName': userData['fullName'] ?? 'Someone',
        'senderAvatar': userData['avatarUrl'] ?? '',
        'type': 'comment',
        'postId': momentId,
        'postOwnerId': postOwnerId,
        'commentId': commentId,
        'imageUrl': postImageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      debugPrint('InAppNotificationService.sendCommentNotification error: $e');
    }
  }

  // ─────────────────────────────────────────
  // REPLY
  // ─────────────────────────────────────────

  /// Send a "reply" notification to the original commenter when the post owner replies.
  /// [originalCommenterId] is the person who wrote the original comment being replied to.
  static Future<void> sendReplyNotification({
    required String momentId,
    required String postOwnerId,
    required String postImageUrl,
    required String originalCommenterId,
    required String replyCommentId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Don't notify yourself
      if (currentUser.uid == originalCommenterId) return;

      final docId = 'reply_${currentUser.uid}_${momentId}_$replyCommentId';
      final userDoc = await _db.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data() ?? {};

      await _db.collection('notifications').doc(docId).set({
        'receiverId': originalCommenterId,
        'senderId': currentUser.uid,
        'senderName': userData['fullName'] ?? 'Someone',
        'senderAvatar': userData['avatarUrl'] ?? '',
        'type': 'reply',
        'postId': momentId,
        'postOwnerId': postOwnerId,
        'commentId': replyCommentId,
        'imageUrl': postImageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      debugPrint('InAppNotificationService.sendReplyNotification error: $e');
    }
  }
}
