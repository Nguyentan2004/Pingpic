import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/presence_service.dart';
import '../../core/services/notification_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  String? _username;
  String? _fullName;
  String? _avatarUrl;
  String? _bio;
  String? _userId;
  PresenceService? _presenceService;

  AuthStatus get status => _status;
  String? get username => _username;
  String? get fullName => _fullName;
  String? get avatarUrl => _avatarUrl;
  String? get bio => _bio;
  String? get userId => _userId;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        _userId = user.uid;
        // Lấy thông tin bổ sung từ Firestore
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          _username = data['username'];
          _fullName = data['fullName'];
          _avatarUrl = data['avatarUrl'];
          _bio = data['bio'];
        }
        _status = AuthStatus.authenticated;

        // Initialize presence tracking for the logged-in user
        if (_presenceService == null || _presenceService!.userId != user.uid) {
          _presenceService?.dispose();
          _presenceService = PresenceService(user.uid);
          _presenceService!.initialize();
        }

        // Request notifications permission and update FCM token in Firestore
        await NotificationService().requestPermissions();
        await NotificationService().updateTokenInFirestore(user.uid);
      } else {
        // Clear presence tracking when user logs out
        _presenceService?.dispose();
        _presenceService = null;

        _userId = null;
        _username = null;
        _fullName = null;
        _avatarUrl = null;
        _bio = null;
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    });
  }

  Future<bool> login(String username, String password) async {
    try {
      // Vì Firebase dùng Email, ta giả định email là username@pingpic.com
      final email = username.contains('@') ? username : '$username@pingpic.com';
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      debugPrint('Login Error: $e');
      return false;
    }
  }

  Future<bool> register(String username, String fullName, String password) async {
    try {
      final email = '$username@pingpic.com';
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        // Lưu thông tin profile vào Firestore
        const avatarUrl = ""; // Không dùng pravatar.cc để tránh lỗi CORS
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'username': username,
          'fullName': fullName,
          'avatarUrl': avatarUrl,
          'bio': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        _username = username;
        _fullName = fullName;
        _avatarUrl = avatarUrl;
        _bio = '';
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Register Error: $e');
    }
    return false;
  }

  Future<void> logout() async {
    if (_userId != null) {
      await NotificationService().removeTokenFromFirestore(_userId!);
    }
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  Future<bool> updateProfile({required String fullName, required String bio, String? avatarUrl}) async {
    try {
      if (_userId == null) return false;
      final updateData = {
        'fullName': fullName,
        'bio': bio,
      };
      if (avatarUrl != null) {
        updateData['avatarUrl'] = avatarUrl;
      }
      await FirebaseFirestore.instance.collection('users').doc(_userId!).update(updateData);
      _fullName = fullName;
      _bio = bio;
      if (avatarUrl != null) {
        _avatarUrl = avatarUrl;
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }

  Future<String?> uploadAvatar(Uint8List imageBytes) async {
    try {
      if (_userId == null) return null;
      final ref = FirebaseStorage.instance.ref().child('avatars/$_userId.jpg');
      final uploadTask = await ref.putData(imageBytes, SettableMetadata(contentType: 'image/jpeg'));
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _presenceService?.dispose();
    super.dispose();
  }
}
