import 'package:logger/logger.dart';

/// A utility class for logging throughout the application.
class AppLogger {
  static late Logger _logger;

  /// Initialize the logger with custom configuration
  static void init() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
      level: Level.verbose,
    );
  }

  /// Get the logger instance
  static Logger get log => _logger;

  /// Log a verbose message
  static void v(String message, {dynamic error, StackTrace? stackTrace}) {
    _logger.v(message, error: error, stackTrace: stackTrace);
  }

  /// Log a debug message
  static void d(String message, {dynamic error, StackTrace? stackTrace}) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log an info message
  static void i(String message, {dynamic error, StackTrace? stackTrace}) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log a warning message
  static void w(String message, {dynamic error, StackTrace? stackTrace}) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log an error message
  static void e(String message, {dynamic error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log a wtf message (What a Terrible Failure)
  static void wtf(String message, {dynamic error, StackTrace? stackTrace}) {
    _logger.wtf(message, error: error, stackTrace: stackTrace);
  }
}
