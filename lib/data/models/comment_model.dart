import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime createdAt;
  final String senderName;
  final String senderAvatar;

  CommentModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
    required this.senderName,
    required this.senderAvatar,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    DateTime created = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      created = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      created = DateTime.tryParse(data['createdAt']) ?? DateTime.now();
    }

    return CommentModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      text: data['text'] ?? '',
      createdAt: created,
      senderName: data['senderName'] ?? '',
      senderAvatar: data['senderAvatar'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'createdAt': createdAt,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
    };
  }
}
