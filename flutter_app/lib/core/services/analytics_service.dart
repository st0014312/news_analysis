import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import '../utils/app_logger.dart';

/// Event names for analytics
class AnalyticsEvents {
  // Authentication events
  static const String login = 'login';
  static const String signup = 'sign_up';
  static const String logout = 'logout';

  // Screen view events
  static const String screenView = 'screen_view';

  // News events
  static const String viewArticle = 'view_article';
  static const String shareArticle = 'share_article';
  static const String searchNews = 'search_news';
  static const String filterNews = 'filter_news';
  static const String bookmarkArticle = 'bookmark_article';

  // Subscription events
  static const String viewSubscription = 'view_subscription';
  static const String startSubscription = 'start_subscription';
  static const String completeSubscription = 'complete_subscription';
  static const String cancelSubscription = 'cancel_subscription';

  // Watchlist events
  static const String addToWatchlist = 'add_to_watchlist';
  static const String removeFromWatchlist = 'remove_from_watchlist';

  // Notification events
  static const String enableNotifications = 'enable_notifications';
  static const String disableNotifications = 'disable_notifications';
  static const String receiveNotification = 'receive_notification';
  static const String openNotification = 'open_notification';

  // Error events
  static const String error = 'error';

  // Private constructor to prevent instantiation
  AnalyticsEvents._();
}

/// Service for tracking analytics events
class AnalyticsService {
  /// Firebase Analytics instance
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Firebase Analytics Observer for navigation
  late final FirebaseAnalyticsObserver _observer;

  /// Get the analytics observer for navigation
  FirebaseAnalyticsObserver get observer => _observer;

  /// Constructor
  AnalyticsService() {
    _observer = FirebaseAnalyticsObserver(analytics: _analytics);
    _init();
  }

  /// Initialize analytics
  void _init() {
    // Enable analytics collection based on environment
    _analytics.setAnalyticsCollectionEnabled(!kDebugMode);

    AppLogger.i('Analytics service initialized');
  }

  /// Log a custom event
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );

      AppLogger.d('Analytics event logged: $name');
    } catch (e) {
      AppLogger.e('Error logging analytics event', error: e);
    }
  }

  /// Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );

      AppLogger.d('Screen view logged: $screenName');
    } catch (e) {
      AppLogger.e('Error logging screen view', error: e);
    }
  }

  /// Log user login
  Future<void> logLogin({
    required String method,
  }) async {
    try {
      await _analytics.logLogin(
        loginMethod: method,
      );

      AppLogger.d('Login logged: $method');
    } catch (e) {
      AppLogger.e('Error logging login', error: e);
    }
  }

  /// Log user signup
  Future<void> logSignUp({
    required String method,
  }) async {
    try {
      await _analytics.logSignUp(
        signUpMethod: method,
      );

      AppLogger.d('Sign up logged: $method');
    } catch (e) {
      AppLogger.e('Error logging sign up', error: e);
    }
  }

  /// Log article view
  Future<void> logArticleView({
    required String articleId,
    required String title,
    required String source,
    String? category,
  }) async {
    try {
      await logEvent(
        name: AnalyticsEvents.viewArticle,
        parameters: {
          'article_id': articleId,
          'title': title,
          'source': source,
          'category': category,
        },
      );
    } catch (e) {
      AppLogger.e('Error logging article view', error: e);
    }
  }

  /// Log article share
  Future<void> logArticleShare({
    required String articleId,
    required String title,
    required String method,
  }) async {
    try {
      await _analytics.logShare(
        contentType: 'article',
        itemId: articleId,
        method: method,
      );

      AppLogger.d('Article share logged: $articleId');
    } catch (e) {
      AppLogger.e('Error logging article share', error: e);
    }
  }

  /// Log search
  Future<void> logSearch({
    required String searchTerm,
  }) async {
    try {
      await _analytics.logSearch(
        searchTerm: searchTerm,
      );

      AppLogger.d('Search logged: $searchTerm');
    } catch (e) {
      AppLogger.e('Error logging search', error: e);
    }
  }

  /// Log filter application
  Future<void> logFilter({
    required Map<String, dynamic> filters,
  }) async {
    try {
      await logEvent(
        name: AnalyticsEvents.filterNews,
        parameters: filters,
      );
    } catch (e) {
      AppLogger.e('Error logging filter', error: e);
    }
  }

  /// Log subscription view
  Future<void> logSubscriptionView({
    required String planId,
  }) async {
    try {
      await logEvent(
        name: AnalyticsEvents.viewSubscription,
        parameters: {
          'plan_id': planId,
        },
      );
    } catch (e) {
      AppLogger.e('Error logging subscription view', error: e);
    }
  }

  /// Log subscription start
  Future<void> logSubscriptionStart({
    required String planId,
    required double price,
    required String currency,
  }) async {
    try {
      await logEvent(
        name: AnalyticsEvents.startSubscription,
        parameters: {
          'plan_id': planId,
          'price': price,
          'currency': currency,
        },
      );
    } catch (e) {
      AppLogger.e('Error logging subscription start', error: e);
    }
  }

  /// Log subscription complete
  Future<void> logSubscriptionComplete({
    required String planId,
    required double price,
    required String currency,
    required String paymentMethod,
  }) async {
    try {
      await logEvent(
        name: AnalyticsEvents.completeSubscription,
        parameters: {
          'plan_id': planId,
          'price': price,
          'currency': currency,
          'payment_method': paymentMethod,
        },
      );
    } catch (e) {
      AppLogger.e('Error logging subscription complete', error: e);
    }
  }

  /// Log error
  Future<void> logError({
    required String errorCode,
    required String message,
    StackTrace? stackTrace,
  }) async {
    try {
      await logEvent(
        name: AnalyticsEvents.error,
        parameters: {
          'error_code': errorCode,
          'message': message,
          'stack_trace': stackTrace?.toString(),
        },
      );
    } catch (e) {
      AppLogger.e('Error logging error event', error: e);
    }
  }

  /// Set user ID
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);

      AppLogger.d('User ID set: $userId');
    } catch (e) {
      AppLogger.e('Error setting user ID', error: e);
    }
  }

  /// Set user property
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    try {
      await _analytics.setUserProperty(
        name: name,
        value: value,
      );

      AppLogger.d('User property set: $name = $value');
    } catch (e) {
      AppLogger.e('Error setting user property', error: e);
    }
  }

  /// Reset analytics data
  Future<void> resetAnalyticsData() async {
    try {
      await _analytics.resetAnalyticsData();

      AppLogger.i('Analytics data reset');
    } catch (e) {
      AppLogger.e('Error resetting analytics data', error: e);
    }
  }
}
