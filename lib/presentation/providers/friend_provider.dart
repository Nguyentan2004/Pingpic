import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/friends_repository.dart';

class FriendProvider extends ChangeNotifier {
  final FriendsRepository _repository = FriendsRepository();
  final List<StreamSubscription> _friendsStatusSubscriptions = [];

  List<UserModel> _friends = [];
  List<FriendRequestModel> _pendingRequests = [];
  List<UserModel> _searchResults = [];
  
  bool _isLoading = false;
  bool _isSearching = false;

  List<UserModel> get friends => _friends;
  List<FriendRequestModel> get pendingRequests => _pendingRequests;
  List<UserModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;

  /// Tải dữ liệu ban đầu (Bạn bè + Lời mời)
  Future<void> fetchFriendsData() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      _clearSubscriptions();
      _friends = [];
      _pendingRequests = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getFriendsList(),
        _repository.getFriendRequests(),
      ]);
      _friends = results[0] as List<UserModel>;
      _pendingRequests = results[1] as List<FriendRequestModel>;

      // Bắt đầu lắng nghe trạng thái online của bạn bè
      final friendIds = _friends.map((f) => f.id).toList();
      _listenToFriendsStatus(friendIds);
    } catch (e) {
      debugPrint('Error fetching friends data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _clearSubscriptions() {
    for (var sub in _friendsStatusSubscriptions) {
      sub.cancel();
    }
    _friendsStatusSubscriptions.clear();
  }

  void _listenToFriendsStatus(List<String> friendIds) {
    _clearSubscriptions();
    if (friendIds.isEmpty) return;

    // Chia nhóm IDs theo 30 để tránh Firestore whereIn limitation
    final List<List<String>> chunks = [];
    for (var i = 0; i < friendIds.length; i += 30) {
      final end = (i + 30 < friendIds.length) ? i + 30 : friendIds.length;
      chunks.add(friendIds.sublist(i, end));
    }

    for (final chunk in chunks) {
      final sub = FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .snapshots()
          .listen((snapshot) {
        bool changed = false;
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final index = _friends.indexWhere((f) => f.id == doc.id);
          if (index != -1) {
            final updatedFriend = UserModel(
              id: _friends[index].id,
              username: _friends[index].username,
              fullName: _friends[index].fullName,
              avatarUrl: _friends[index].avatarUrl,
              isFriend: _friends[index].isFriend,
              isRequested: _friends[index].isRequested,
              isOnline: data['isOnline'] ?? false,
              lastActive: data['lastActive'] is Timestamp
                  ? (data['lastActive'] as Timestamp).toDate()
                  : null,
            );

            if (_friends[index].isOnline != updatedFriend.isOnline ||
                _friends[index].lastActive != updatedFriend.lastActive) {
              _friends[index] = updatedFriend;
              changed = true;
            }
          }
        }
        if (changed) {
          notifyListeners();
        }
      }, onError: (e) {
        debugPrint('Error listening to friends status: $e');
      });
      _friendsStatusSubscriptions.add(sub);
    }
  }

  /// Tìm kiếm người dùng
  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      _searchResults = await _repository.searchUsers(query);
    } catch (e) {
      debugPrint('Error searching users: $e');
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Gửi lời mời kết bạn
  Future<bool> sendRequest(String userId) async {
    try {
      await _repository.sendFriendRequest(userId);
      // Cập nhật trạng thái trong searchResults để hiện "Requested"
      final index = _searchResults.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _searchResults[index] = UserModel(
          id: _searchResults[index].id,
          username: _searchResults[index].username,
          fullName: _searchResults[index].fullName,
          avatarUrl: _searchResults[index].avatarUrl,
          isFriend: false,
          isRequested: true,
          isOnline: _searchResults[index].isOnline,
          lastActive: _searchResults[index].lastActive,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error sending request: $e');
      return false;
    }
  }

  /// Chấp nhận lời mời
  Future<bool> acceptRequest(String requestId) async {
    try {
      await _repository.acceptFriendRequest(requestId);
      // Sau khi chấp nhận, tải lại danh sách
      await fetchFriendsData();
      return true;
    } catch (e) {
      debugPrint('Error accepting request: $e');
      return false;
    }
  }

  /// Từ chối lời mời
  Future<bool> rejectRequest(String requestId) async {
    try {
      await _repository.rejectFriendRequest(requestId);
      // Tải lại danh sách sau khi từ chối
      await fetchFriendsData();
      return true;
    } catch (e) {
      debugPrint('Error rejecting request: $e');
      return false;
    }
  }

  /// Hủy kết bạn
  Future<bool> removeFriend(String friendId) async {
    try {
      await _repository.removeFriend(friendId);
      // Tải lại danh sách sau khi hủy kết bạn
      await fetchFriendsData();
      return true;
    } catch (e) {
      debugPrint('Error removing friend: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _clearSubscriptions();
    super.dispose();
  }
}
