import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_logger.dart';

/// Keys for cache storage
class CacheKeys {
  static const String token = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String user = 'user_data';
  static const String theme = 'app_theme';
  static const String onboarding = 'onboarding_completed';
  static const String lastSync = 'last_sync_timestamp';
  static const String newsCache = 'news_cache';
  static const String newsFeed = 'news_feed';
  static const String watchlist = 'watchlist';
  static const String notifications = 'notifications';

  // Private constructor to prevent instantiation
  CacheKeys._();
}

/// Service for handling local caching
class CacheService {
  /// SharedPreferences instance for non-sensitive data
  final SharedPreferences _sharedPreferences;

  /// Secure storage for sensitive data
  final FlutterSecureStorage _secureStorage;

  /// Constructor
  CacheService({
    required SharedPreferences sharedPreferences,
    required FlutterSecureStorage secureStorage,
  })  : _sharedPreferences = sharedPreferences,
        _secureStorage = secureStorage;

  /// Save authentication token
  Future<void> saveToken(String token) async {
    try {
      await _secureStorage.write(key: CacheKeys.token, value: token);
    } catch (e) {
      AppLogger.e('Error saving token', error: e);
      // Fallback to shared preferences if secure storage fails
      await _sharedPreferences.setString(CacheKeys.token, token);
    }
  }

  /// Get authentication token
  Future<String?> getToken() async {
    try {
      return await _secureStorage.read(key: CacheKeys.token);
    } catch (e) {
      AppLogger.e('Error getting token from secure storage', error: e);
      // Fallback to shared preferences
      return _sharedPreferences.getString(CacheKeys.token);
    }
  }

  /// Clear authentication token
  Future<void> clearToken() async {
    try {
      await _secureStorage.delete(key: CacheKeys.token);
    } catch (e) {
      AppLogger.e('Error clearing token from secure storage', error: e);
    }

    // Also clear from shared preferences (fallback)
    await _sharedPreferences.remove(CacheKeys.token);
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String refreshToken) async {
    try {
      await _secureStorage.write(
          key: CacheKeys.refreshToken, value: refreshToken);
    } catch (e) {
      AppLogger.e('Error saving refresh token', error: e);
    }
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: CacheKeys.refreshToken);
    } catch (e) {
      AppLogger.e('Error getting refresh token', error: e);
      return null;
    }
  }

  /// Save user data
  Future<void> saveUser(Map<String, dynamic> userData) async {
    try {
      final userJson = jsonEncode(userData);
      await _sharedPreferences.setString(CacheKeys.user, userJson);
    } catch (e) {
      AppLogger.e('Error saving user data', error: e);
    }
  }

  /// Get user data
  Future<Map<String, dynamic>?> getUser() async {
    try {
      final userJson = _sharedPreferences.getString(CacheKeys.user);
      if (userJson != null) {
        return jsonDecode(userJson) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      AppLogger.e('Error getting user data', error: e);
      return null;
    }
  }

  /// Clear user data
  Future<void> clearUser() async {
    try {
      await _sharedPreferences.remove(CacheKeys.user);
    } catch (e) {
      AppLogger.e('Error clearing user data', error: e);
    }
  }

  /// Save app theme
  Future<void> saveTheme(String theme) async {
    try {
      await _sharedPreferences.setString(CacheKeys.theme, theme);
    } catch (e) {
      AppLogger.e('Error saving theme', error: e);
    }
  }

  /// Get app theme
  String? getTheme() {
    try {
      return _sharedPreferences.getString(CacheKeys.theme);
    } catch (e) {
      AppLogger.e('Error getting theme', error: e);
      return null;
    }
  }

  /// Save onboarding status
  Future<void> saveOnboardingCompleted(bool completed) async {
    try {
      await _sharedPreferences.setBool(CacheKeys.onboarding, completed);
    } catch (e) {
      AppLogger.e('Error saving onboarding status', error: e);
    }
  }

  /// Get onboarding status
  bool isOnboardingCompleted() {
    try {
      return _sharedPreferences.getBool(CacheKeys.onboarding) ?? false;
    } catch (e) {
      AppLogger.e('Error getting onboarding status', error: e);
      return false;
    }
  }

  /// Save last sync timestamp
  Future<void> saveLastSyncTimestamp(DateTime timestamp) async {
    try {
      await _sharedPreferences.setString(
          CacheKeys.lastSync, timestamp.toIso8601String());
    } catch (e) {
      AppLogger.e('Error saving last sync timestamp', error: e);
    }
  }

  /// Get last sync timestamp
  DateTime? getLastSyncTimestamp() {
    try {
      final timestamp = _sharedPreferences.getString(CacheKeys.lastSync);
      if (timestamp != null) {
        return DateTime.parse(timestamp);
      }
      return null;
    } catch (e) {
      AppLogger.e('Error getting last sync timestamp', error: e);
      return null;
    }
  }

  /// Save news cache
  Future<void> saveNewsCache(List<Map<String, dynamic>> news) async {
    try {
      final newsJson = jsonEncode(news);
      await _sharedPreferences.setString(CacheKeys.newsCache, newsJson);
    } catch (e) {
      AppLogger.e('Error saving news cache', error: e);
    }
  }

  /// Get news cache
  List<Map<String, dynamic>>? getNewsCache() {
    try {
      final newsJson = _sharedPreferences.getString(CacheKeys.newsCache);
      if (newsJson != null) {
        final List<dynamic> decoded = jsonDecode(newsJson);
        return decoded.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      AppLogger.e('Error getting news cache', error: e);
      return null;
    }
  }

  /// Save news feed
  Future<void> saveNewsFeed(List<Map<String, dynamic>> feed) async {
    try {
      final feedJson = jsonEncode(feed);
      await _sharedPreferences.setString(CacheKeys.newsFeed, feedJson);
    } catch (e) {
      AppLogger.e('Error saving news feed', error: e);
    }
  }

  /// Get news feed
  List<Map<String, dynamic>>? getNewsFeed() {
    try {
      final feedJson = _sharedPreferences.getString(CacheKeys.newsFeed);
      if (feedJson != null) {
        final List<dynamic> decoded = jsonDecode(feedJson);
        return decoded.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      AppLogger.e('Error getting news feed', error: e);
      return null;
    }
  }

  /// Save watchlist
  Future<void> saveWatchlist(List<String> watchlist) async {
    try {
      await _sharedPreferences.setStringList(CacheKeys.watchlist, watchlist);
    } catch (e) {
      AppLogger.e('Error saving watchlist', error: e);
    }
  }

  /// Get watchlist
  List<String> getWatchlist() {
    try {
      return _sharedPreferences.getStringList(CacheKeys.watchlist) ?? [];
    } catch (e) {
      AppLogger.e('Error getting watchlist', error: e);
      return [];
    }
  }

  /// Clear all cache
  Future<void> clearAll() async {
    try {
      await _sharedPreferences.clear();
      await _secureStorage.deleteAll();
    } catch (e) {
      AppLogger.e('Error clearing all cache', error: e);
    }
  }
}
