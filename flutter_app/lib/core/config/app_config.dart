import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/app_logger.dart';

/// Environment types for the application
enum Environment {
  development,
  staging,
  production,
}

/// Configuration class for the application
class AppConfig {
  /// Private constructor to prevent direct instantiation
  AppConfig._();

  /// Current environment
  static late Environment _environment;

  /// API base URL
  static late String _apiBaseUrl;

  /// WebSocket URL
  static late String _webSocketUrl;

  /// API key (if needed)
  static String? _apiKey;

  /// Initialize the app configuration based on the flavor
  static void initialize({required String flavor}) {
    switch (flavor) {
      case 'development':
        _environment = Environment.development;
        _apiBaseUrl = 'http://localhost:8000/api';
        _webSocketUrl = 'ws://localhost:8000/ws';
        break;
      case 'staging':
        _environment = Environment.staging;
        _apiBaseUrl = 'https://staging-api.financialnews.com/api';
        _webSocketUrl = 'wss://staging-api.financialnews.com/ws';
        break;
      case 'production':
        _environment = Environment.production;
        _apiBaseUrl = 'https://api.financialnews.com/api';
        _webSocketUrl = 'wss://api.financialnews.com/ws';
        break;
      default:
        _environment = Environment.development;
        _apiBaseUrl = 'http://localhost:8000/api';
        _webSocketUrl = 'ws://localhost:8000/ws';
        AppLogger.w('Unknown flavor: $flavor, defaulting to development');
    }

    AppLogger.i('App configured for ${_environment.name} environment');
    AppLogger.d('API Base URL: $_apiBaseUrl');
    AppLogger.d('WebSocket URL: $_webSocketUrl');
  }

  /// Get the current environment
  static Environment get environment => _environment;

  /// Check if the app is running in development mode
  static bool get isDevelopment => _environment == Environment.development;

  /// Check if the app is running in staging mode
  static bool get isStaging => _environment == Environment.staging;

  /// Check if the app is running in production mode
  static bool get isProduction => _environment == Environment.production;

  /// Get the API base URL
  static String get apiBaseUrl => _apiBaseUrl;

  /// Get the WebSocket URL
  static String get webSocketUrl => _webSocketUrl;

  /// Get the API key
  static String? get apiKey => _apiKey;

  /// Set the API key
  static void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  /// Get the theme mode based on the environment
  static ThemeMode getThemeMode() {
    if (kDebugMode && isDevelopment) {
      return ThemeMode.light; // Use light mode for development
    }
    return ThemeMode.system; // Use system theme for production
  }
}
