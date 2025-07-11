import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import '../models/user.dart' as app_user;

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _firebaseUser;
  app_user.User? _currentUser;
  bool _isLoading = false;

  User? get firebaseUser => _firebaseUser;
  app_user.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  AuthService() {
    print('🔐 [AUTH_SERVICE] AuthService initialized');
    developer.log('🔐 AuthService initialized', name: 'AuthService');
    // No longer relying on auth state changes
  }

  // Handle authentication manually instead of using the auth state listener
  Future<void> _handleAuthentication(String uid) async {
    print('👤 [AUTH_SERVICE] Authentication successful for UID: $uid');
    developer.log('👤 Authentication successful for UID: $uid',
        name: 'AuthService');

    // Set the current Firebase user ID
    _firebaseUser = _auth.currentUser;

    print('📥 [AUTH_SERVICE] Loading user data for: $uid');
    developer.log('📥 Loading user data for: $uid', name: 'AuthService');

    // Load user data using the provided UID
    await _loadUserData(uid);

    print('🔄 [AUTH_SERVICE] Notifying listeners');
    notifyListeners();
  }

  Future<void> _loadUserData(String uid) async {
    try {
      developer.log('📊 Loading user data from Firestore for uid: $uid',
          name: 'AuthService');
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        developer.log('✅ User data found in Firestore', name: 'AuthService');
        _currentUser = app_user.User.fromJson({
          'id': doc.id,
          ...doc.data()!,
        });
      } else {
        developer.log('⚠️ User document not found in Firestore',
            name: 'AuthService');
      }
    } catch (e) {
      developer.log('❌ Error loading user data: $e',
          name: 'AuthService', error: e);
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    print('🔑 [AUTH_SERVICE] Attempting sign in with email: $email');
    developer.log('🔑 Attempting sign in with email: $email',
        name: 'AuthService');
    _isLoading = true;
    notifyListeners();

    try {
      print('📡 [AUTH_SERVICE] Making Firebase auth request');
      developer.log('📡 Making Firebase auth request', name: 'AuthService');
      final userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      print('✅ [AUTH_SERVICE] Firebase sign in successful');
      developer.log('✅ Firebase sign in successful', name: 'AuthService');

      // Use the _handleAuthentication method with the user's UID
      await _handleAuthentication(userCredential.user!.uid);
    } catch (e) {
      print('❌ [AUTH_SERVICE] Firebase sign in failed: $e');
      developer.log('❌ Firebase sign in failed: $e',
          name: 'AuthService', error: e);
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String userType,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final userData = app_user.User(
          id: credential.user!.uid,
          firstName: firstName,
          lastName: lastName,
          email: email,
          userType: userType,
          location: 'Recife, Brazil',
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(userData.toJson());

        _currentUser = userData;

        // Use the _handleAuthentication method with the user's UID
        await _handleAuthentication(credential.user!.uid);
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
