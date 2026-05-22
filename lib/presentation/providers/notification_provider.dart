import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription? _notificationsSubscription;
  
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider() {
    _initListener();
  }

  void _initListener() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _subscribeToNotifications(user.uid);
      } else {
        _unsubscribe();
      }
    });
  }

  void _subscribeToNotifications(String userId) {
    _unsubscribe();
    _isLoading = true;
    notifyListeners();

    _notificationsSubscription = _firestore
        .collection('notifications')
        .where('receiverId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        _notifications = snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList();
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error listening to notifications: $error');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void _unsubscribe() {
    _notificationsSubscription?.cancel();
    _notificationsSubscription = null;
    _notifications = [];
    notifyListeners();
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final unreadNotifications = _notifications.where((n) => !n.isRead).toList();
      if (unreadNotifications.isEmpty) return;

      final batch = _firestore.batch();
      for (var n in unreadNotifications) {
        final ref = _firestore.collection('notifications').doc(n.id);
        batch.update(ref, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }
}
