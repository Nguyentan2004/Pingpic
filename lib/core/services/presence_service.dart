import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'presence_helper.dart';

class PresenceService with WidgetsBindingObserver {
  final String userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isInitialized = false;

  PresenceService(this.userId);

  /// Initializes presence tracking and sets user to online.
  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;

    // Observe Flutter app lifecycle (Mobile/Desktop focus changes)
    WidgetsBinding.instance.addObserver(this);

    // Set status online on startup
    setOnline();

    // Set up Web visibility and unload hooks
    PresenceHelper.setupHooks(userId, (isVisible) {
      if (isVisible) {
        setOnline();
      } else {
        setOffline();
      }
    });
  }

  /// Sets the user's status to online in Firestore
  Future<void> setOnline() async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isOnline': true,
        'lastActive': FieldValue.serverTimestamp(),
      });
      debugPrint('PresenceService: Set user $userId ONLINE');
    } catch (e) {
      debugPrint('PresenceService Error (setOnline): $e');
    }
  }

  /// Sets the user's status to offline in Firestore
  Future<void> setOffline() async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isOnline': false,
        'lastActive': FieldValue.serverTimestamp(),
      });
      debugPrint('PresenceService: Set user $userId OFFLINE');
    } catch (e) {
      debugPrint('PresenceService Error (setOffline): $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setOnline();
    } else if (state == AppLifecycleState.paused || 
               state == AppLifecycleState.inactive || 
               state == AppLifecycleState.detached) {
      setOffline();
    }
  }

  /// Cleans up the observer and marks the user offline.
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    setOffline();
  }
}
