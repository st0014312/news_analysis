import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../utils/app_logger.dart';
import 'auth_service.dart';

/// Service for handling API requests
class ApiService {
  /// Dio HTTP client
  late final Dio _dio;

  /// Authentication service
  final AuthService _authService;

  /// Base URL for API requests
  final String baseUrl;

  /// Constructor
  ApiService({
    required this.baseUrl,
    required AuthService authService,
  }) : _authService = authService {
    _initDio();
  }

  /// Initialize Dio with interceptors and options
  void _initDio() {
    final options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    _dio = Dio(options);

    // Add logging interceptor
    if (!AppConfig.isProduction) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) => AppLogger.d('DIO: $object'),
      ));
    }

    // Add auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _authService.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token expired, try to refresh
          final refreshed = await _authService.refreshToken();
          if (refreshed) {
            // Retry the request with new token
            final token = await _authService.getAccessToken();
            error.requestOptions.headers['Authorization'] = 'Bearer $token';

            // Create new request with the updated token
            final response = await _dio.fetch(error.requestOptions);
            return handler.resolve(response);
          }
        }
        return handler.next(error);
      },
    ));
  }

  /// Make a GET request
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      return response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Make a POST request
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Make a PUT request
  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Make a DELETE request
  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Handle API errors
  void _handleError(dynamic error) {
    if (error is DioException) {
      AppLogger.e(
        'API Error: ${error.type} - ${error.message}',
        error: error,
        stackTrace: error.stackTrace,
      );

      // Log response data if available
      if (error.response != null) {
        AppLogger.e(
          'Response: ${error.response?.statusCode} - ${error.response?.data}',
        );
      }
    } else {
      AppLogger.e('Unexpected API error', error: error);
    }
  }
}
