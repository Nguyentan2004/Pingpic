import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String username;
  final String fullName;
  final String? avatarUrl;
  final bool isFriend;
  final bool isRequested;
  final bool isOnline;
  final DateTime? lastActive;

  UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    this.avatarUrl,
    this.isFriend = false,
    this.isRequested = false,
    this.isOnline = false,
    this.lastActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedLastActive;
    final lastActiveVal = json['lastActive'];
    if (lastActiveVal != null) {
      if (lastActiveVal is Timestamp) {
        parsedLastActive = lastActiveVal.toDate();
      } else if (lastActiveVal is String) {
        parsedLastActive = DateTime.tryParse(lastActiveVal);
      }
    }

    return UserModel(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? '',
      avatarUrl: json['avatarUrl'],
      isFriend: json['isFriend'] ?? false,
      isRequested: json['isRequested'] ?? false,
      isOnline: json['isOnline'] ?? false,
      lastActive: parsedLastActive,
    );
  }
}

class FriendRequestModel {
  final String id;
  final String requesterName;
  final String requesterAvatar;

  FriendRequestModel({
    required this.id,
    required this.requesterName,
    required this.requesterAvatar,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    return FriendRequestModel(
      id: json['id']?.toString() ?? '',
      requesterName: json['requesterName'] ?? '',
      requesterAvatar: json['requesterAvatar'] ?? '',
    );
  }
}
