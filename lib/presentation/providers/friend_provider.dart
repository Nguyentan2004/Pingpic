import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/friends_repository.dart';

class FriendProvider extends ChangeNotifier {
  final FriendsRepository _repository = FriendsRepository();
  final List<StreamSubscription> _friendsStatusSubscriptions = [];
  StreamSubscription? _friendshipsSubscription;
  StreamSubscription? _pendingRequestsSubscription;

  List<UserModel> _friends = [];
  List<FriendRequestModel> _pendingRequests = [];
  List<UserModel> _searchResults = [];
  
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isDisposed = false;

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
      // Bắt đầu lắng nghe danh sách bạn bè realtime
      startListeningToFriendships();
      // Bắt đầu lắng nghe danh sách lời mời kết bạn realtime
      startListeningToPendingRequests();
    } catch (e) {
      debugPrint('Error fetching friends data: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Lắng nghe danh sách lời mời kết bạn realtime
  void startListeningToPendingRequests() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    _pendingRequestsSubscription?.cancel();
    _pendingRequestsSubscription = FirebaseFirestore.instance
        .collection('friendships')
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) async {
      final List<FriendRequestModel> requests = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final requesterId = data['requesterId'] as String;

        try {
          final requesterDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(requesterId)
              .get();
          final requesterData = requesterDoc.data() ?? {};

          requests.add(FriendRequestModel(
            id: doc.id,
            requesterName: requesterData['fullName'] ?? 'Unknown',
            requesterAvatar: requesterData['avatarUrl'] ?? '',
          ));
        } catch (e) {
          debugPrint('Error fetching requester profile: $e');
        }
      }

      if (!_isDisposed) {
        _pendingRequests = requests;
        _isLoading = false;
        notifyListeners();
      }
    }, onError: (e) {
      debugPrint('Error listening to pending requests: $e');
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  void _clearFriendsStatusSubscriptions() {
    for (var sub in _friendsStatusSubscriptions) {
      sub.cancel();
    }
    _friendsStatusSubscriptions.clear();
  }

  void _clearSubscriptions() {
    _friendshipsSubscription?.cancel();
    _friendshipsSubscription = null;
    _pendingRequestsSubscription?.cancel();
    _pendingRequestsSubscription = null;
    _clearFriendsStatusSubscriptions();
  }

  /// Lắng nghe danh sách bạn bè realtime
  void startListeningToFriendships() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    _friendshipsSubscription?.cancel();
    _friendshipsSubscription = FirebaseFirestore.instance
        .collection('friendships')
        .where('status', isEqualTo: 'accepted')
        .where(Filter.or(
          Filter('requesterId', isEqualTo: currentUserId),
          Filter('receiverId', isEqualTo: currentUserId),
        ))
        .snapshots()
        .listen((snapshot) {
      final friendIds = snapshot.docs.map((doc) {
        final data = doc.data();
        return data['requesterId'] == currentUserId
            ? data['receiverId'] as String
            : data['requesterId'] as String;
      }).toList();

      if (friendIds.isEmpty) {
        _friends = [];
        _clearFriendsStatusSubscriptions();
        _isLoading = false;
        notifyListeners();
        return;
      }

      _listenToFriendsProfilesAndStatus(friendIds);
    }, onError: (e) {
      debugPrint('Error listening to friendships: $e');
      _isLoading = false;
      notifyListeners();
    });
  }

  /// Lắng nghe thông tin profile và trạng thái online của bạn bè realtime
  void _listenToFriendsProfilesAndStatus(List<String> friendIds) {
    _clearFriendsStatusSubscriptions();
    if (friendIds.isEmpty) {
      _friends = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    final List<List<String>> chunks = [];
    for (var i = 0; i < friendIds.length; i += 30) {
      final end = (i + 30 < friendIds.length) ? i + 30 : friendIds.length;
      chunks.add(friendIds.sublist(i, end));
    }

    final Map<String, UserModel> friendsMap = {};

    for (final chunk in chunks) {
      final sub = FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .snapshots()
          .listen((snapshot) {
        for (var doc in snapshot.docs) {
          final data = doc.data();
          friendsMap[doc.id] = UserModel(
            id: doc.id,
            username: data['username'] ?? '',
            fullName: data['fullName'] ?? '',
            avatarUrl: data['avatarUrl'] ?? '',
            isFriend: true,
            isRequested: false,
            isOnline: data['isOnline'] ?? false,
            lastActive: data['lastActive'] is Timestamp
                ? (data['lastActive'] as Timestamp).toDate()
                : null,
          );
        }

        // Cập nhật danh sách bạn bè theo thứ tự IDs ban đầu
        _friends = friendIds
            .map((id) => friendsMap[id])
            .whereType<UserModel>()
            .toList();

        _isLoading = false;
        notifyListeners();
      }, onError: (e) {
        debugPrint('Error listening to friends profiles/status: $e');
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
    _isDisposed = true;
    _clearSubscriptions();
    super.dispose();
  }
}
