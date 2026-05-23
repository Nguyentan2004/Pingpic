import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import '../../core/services/presence_service.dart';
import '../../core/services/notification_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  String? _username;
  String? _email;
  String? _fullName;
  String? _avatarUrl;
  String? _bio;
  String? _shareCode;
  String? _userId;
  PresenceService? _presenceService;

  AuthStatus get status => _status;
  String? get username => _username;
  String? get email => _email;
  String? get fullName => _fullName;
  String? get avatarUrl => _avatarUrl;
  String? get bio => _bio;
  String? get shareCode => _shareCode;
  String? get userId => _userId;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  String _generateShareCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = math.Random();
    return List.generate(6, (index) => chars[rand.nextInt(chars.length)]).join();
  }

  AuthProvider() {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    if (kIsWeb) {
      try {
        await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      } catch (e) {
        debugPrint('Error setting FirebaseAuth persistence on web: $e');
      }
    }

    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        final rememberMe = prefs.getBool('remember_me') ?? true;

        if (!rememberMe) {
          _presenceService?.dispose();
          _presenceService = null;
          _userId = null;
          _username = null;
          _email = null;
          _fullName = null;
          _avatarUrl = null;
          _bio = null;
          _shareCode = null;
          _status = AuthStatus.unauthenticated;
          notifyListeners();
          
          await FirebaseAuth.instance.signOut();
          return;
        }

        _userId = user.uid;
        // Lấy thông tin bổ sung từ Firestore
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          _username = data['username'];
          _fullName = data['fullName'];
          _avatarUrl = data['avatarUrl'];
          _bio = data['bio'];
          
          _email = data['email'] ?? user.email;
          // Tự động backfill email nếu Firestore document chưa có trường email
          if (!data.containsKey('email') || data['email'] == null) {
            FirebaseFirestore.instance.collection('users').doc(user.uid).update({
              'email': _email,
            }).catchError((e) => debugPrint('Error backfilling email: $e'));
          }
          
          if (data.containsKey('shareCode') && data['shareCode'] != null && data['shareCode'].toString().isNotEmpty) {
            _shareCode = data['shareCode'];
          } else {
            final generatedCode = _generateShareCode();
            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
              'shareCode': generatedCode,
            });
            _shareCode = generatedCode;
          }
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
        _email = null;
        _fullName = null;
        _avatarUrl = null;
        _bio = null;
        _shareCode = null;
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    });
  }

  Future<String?> login(String usernameOrEmail, String password, {bool rememberMe = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', rememberMe);

      String resolvedEmail = usernameOrEmail.trim();
      if (!resolvedEmail.contains('@')) {
        // Query Firestore to find the user with this username
        final query = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: resolvedEmail)
            .limit(1)
            .get();
            
        if (query.docs.isEmpty) {
          return 'auth/username-not-found';
        } else {
          final data = query.docs.first.data();
          final emailVal = data['email'];
          if (emailVal == null || emailVal.toString().trim().isEmpty) {
            return 'auth/email-not-linked';
          }
          resolvedEmail = emailVal.toString().trim();
        }
      }
      
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: resolvedEmail,
        password: password,
      );
      return null; // Success
    } on FirebaseAuthException catch (e) {
      debugPrint('Login Error: ${e.code} - ${e.message}');
      return e.code;
    } catch (e) {
      debugPrint('Login Error: $e');
      return 'auth/network-error';
    }
  }

  Future<String?> register({
    required String username,
    required String email,
    required String fullName,
    required String password,
  }) async {
    try {
      // 1. Kiểm tra duplicate username trên Firestore
      final usernameQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
          
      if (usernameQuery.docs.isNotEmpty) {
        return 'auth/username-already-in-use';
      }

      // 2. Tạo account trên Firebase Auth
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        final generatedCode = _generateShareCode();
        // Lưu thông tin profile vào Firestore bao gồm cả email
        const avatarUrl = "";
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'userId': user.uid,
          'username': username,
          'email': email,
          'fullName': fullName,
          'avatarUrl': avatarUrl,
          'bio': '',
          'shareCode': generatedCode,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        _username = username;
        _email = email;
        _fullName = fullName;
        _avatarUrl = avatarUrl;
        _bio = '';
        _shareCode = generatedCode;
        notifyListeners();
        return null; // Success
      }
      return 'auth/unknown-error';
    } on FirebaseAuthException catch (e) {
      debugPrint('Register Error: ${e.code} - ${e.message}');
      return e.code;
    } catch (e) {
      debugPrint('Register Error: $e');
      return 'auth/network-error';
    }
  }

  Future<String?> sendPasswordReset(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      return null; // Success
    } on FirebaseAuthException catch (e) {
      debugPrint('Reset Password Error: ${e.code} - ${e.message}');
      return e.code;
    } catch (e) {
      debugPrint('Reset Password Error: $e');
      return 'auth/network-error';
    }
  }

  Future<void> logout() async {
    if (_userId != null) {
      await NotificationService().removeTokenFromFirestore(_userId!).catchError((e) => debugPrint('Error removing FCM token: $e'));
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', false);
    await FirebaseAuth.instance.signOut();
    
    _presenceService?.dispose();
    _presenceService = null;
    _userId = null;
    _username = null;
    _email = null;
    _fullName = null;
    _avatarUrl = null;
    _bio = null;
    _shareCode = null;
    _status = AuthStatus.unauthenticated;
    
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
