import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../utils/app_logger.dart';
import 'cache_service.dart';

/// Service for handling authentication
class AuthService {
  /// Firebase Auth instance
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Cache service for storing tokens
  final CacheService _cacheService;

  /// Stream controller for auth state changes
  final StreamController<bool> _authStateController =
      StreamController<bool>.broadcast();

  /// Stream of auth state changes
  Stream<bool> get authStateChanges => _authStateController.stream;

  /// Current user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// User ID
  String? get userId => currentUser?.uid;

  /// Constructor
  AuthService({
    required CacheService cacheService,
  }) : _cacheService = cacheService {
    // Listen to Firebase auth state changes
    _firebaseAuth.authStateChanges().listen((User? user) {
      _authStateController.add(user != null);
    });
  }

  /// Register a new user
  Future<User?> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(displayName);

      // Save token
      final token = await userCredential.user?.getIdToken();
      if (token != null) {
        await _cacheService.saveToken(token);
      }

      return userCredential.user;
    } catch (e) {
      AppLogger.e('Registration error', error: e);
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save token
      final token = await userCredential.user?.getIdToken();
      if (token != null) {
        await _cacheService.saveToken(token);
      }

      return userCredential.user;
    } catch (e) {
      AppLogger.e('Sign in error', error: e);
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await _cacheService.clearToken();
    } catch (e) {
      AppLogger.e('Sign out error', error: e);
      rethrow;
    }
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    try {
      // First try to get token from Firebase
      final token = await currentUser?.getIdToken();
      if (token != null) {
        await _cacheService.saveToken(token);
        return token;
      }

      // If not available, try to get from cache
      return await _cacheService.getToken();
    } catch (e) {
      AppLogger.e('Get access token error', error: e);
      return null;
    }
  }

  /// Refresh token
  Future<bool> refreshToken() async {
    try {
      final token = await currentUser?.getIdToken(true);
      if (token != null) {
        await _cacheService.saveToken(token);
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.e('Refresh token error', error: e);
      return false;
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = currentUser;
      if (user != null) {
        return {
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'emailVerified': user.emailVerified,
        };
      }
      return null;
    } catch (e) {
      AppLogger.e('Get user profile error', error: e);
      return null;
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      await currentUser?.updateDisplayName(displayName);
      await currentUser?.updatePhotoURL(photoURL);
    } catch (e) {
      AppLogger.e('Update profile error', error: e);
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      AppLogger.e('Send password reset email error', error: e);
      rethrow;
    }
  }

  /// Verify password reset code
  Future<bool> verifyPasswordResetCode(String code) async {
    try {
      await _firebaseAuth.verifyPasswordResetCode(code);
      return true;
    } catch (e) {
      AppLogger.e('Verify password reset code error', error: e);
      return false;
    }
  }

  /// Confirm password reset
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    try {
      await _firebaseAuth.confirmPasswordReset(
        code: code,
        newPassword: newPassword,
      );
    } catch (e) {
      AppLogger.e('Confirm password reset error', error: e);
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    _authStateController.close();
  }
}
