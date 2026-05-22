import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background message handler
  debugPrint("Background message received: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Android Channel for foreground notifications
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.', // description
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    if (kIsWeb) {
      _initialized = true;
      return;
    }

    try {
      // Set background messaging handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Create Android Notification Channel for local notifications (foreground)
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      // Initialize local notifications setting
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _localNotifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle notification click when app is in foreground
          debugPrint("Notification clicked: ${response.payload}");
        },
      );

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint("Foreground message received: ${message.messageId}");
        
        final RemoteNotification? notification = message.notification;
        final AndroidNotification? android = message.notification?.android;

        // If Android notification exists and app is in foreground, trigger local notification banner
        if (notification != null && android != null) {
          _localNotifications.show(
            id: notification.hashCode,
            title: notification.title,
            body: notification.body,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                _channel.id,
                _channel.name,
                channelDescription: _channel.description,
                icon: android.smallIcon ?? '@mipmap/ic_launcher',
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
              ),
            ),
            payload: message.data.toString(),
          );
        }
      });

      // Handle when user clicks notification and app is opened from background state
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint("Notification opened app: ${message.messageId}");
      });

      _initialized = true;
    } catch (e) {
      debugPrint("Failed to initialize NotificationService: $e");
    }
  }

  /// Request permissions for iOS and Android 13+
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    try {
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('User granted permission: ${settings.authorizationStatus}');
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      debugPrint("Error requesting notification permissions: $e");
      return false;
    }
  }

  /// Get FCM token
  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      debugPrint("Error getting FCM token: $e");
      return null;
    }
  }

  /// Update token in Firestore users collection
  Future<void> updateTokenInFirestore(String userId) async {
    if (kIsWeb) return; // Skip for Web unless web push is configured

    try {
      final token = await getToken();
      if (token == null) return;

      debugPrint("FCM Token for user $userId: $token");

      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      
      // Add token to a list of tokens so the user can have multiple devices logged in
      await userRef.update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      }).catchError((error) async {
        // If document exists but fcmTokens field is missing, or update fails due to document not containing it
        await userRef.set({
          'fcmTokens': [token],
        }, SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint("Error updating FCM token in Firestore: $e");
    }
  }

  /// Remove token from Firestore users collection (on logout)
  Future<void> removeTokenFromFirestore(String userId) async {
    if (kIsWeb) return;

    try {
      final token = await getToken();
      if (token == null) return;

      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      await userRef.update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
    } catch (e) {
      debugPrint("Error removing FCM token from Firestore: $e");
    }
  }
}
