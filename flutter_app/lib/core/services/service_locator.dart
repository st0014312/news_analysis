import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../utils/app_logger.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'cache_service.dart';
import 'notification_service.dart';
import 'analytics_service.dart';

/// Global service locator instance
final GetIt serviceLocator = GetIt.instance;

/// Setup the service locator with all required services
Future<void> setupServiceLocator({
  required SharedPreferences sharedPreferences,
  required FlutterSecureStorage secureStorage,
}) async {
  AppLogger.i('Setting up service locator');

  // Register services
  _registerCoreServices(sharedPreferences, secureStorage);
  _registerApiServices();
  _registerRepositories();
  _registerBlocs();

  AppLogger.i('Service locator setup complete');
}

/// Register core services
void _registerCoreServices(
  SharedPreferences sharedPreferences,
  FlutterSecureStorage secureStorage,
) {
  // Register SharedPreferences
  serviceLocator.registerSingleton<SharedPreferences>(sharedPreferences);

  // Register SecureStorage
  serviceLocator.registerSingleton<FlutterSecureStorage>(secureStorage);

  // Register CacheService
  serviceLocator.registerSingleton<CacheService>(
    CacheService(
      sharedPreferences: sharedPreferences,
      secureStorage: secureStorage,
    ),
  );

  // Register AuthService
  serviceLocator.registerSingleton<AuthService>(
    AuthService(
      cacheService: serviceLocator<CacheService>(),
    ),
  );

  // Register NotificationService
  serviceLocator.registerSingleton<NotificationService>(
    NotificationService(),
  );

  // Register AnalyticsService
  serviceLocator.registerSingleton<AnalyticsService>(
    AnalyticsService(),
  );
}

/// Register API services
void _registerApiServices() {
  // Register ApiService
  serviceLocator.registerSingleton<ApiService>(
    ApiService(
      baseUrl: AppConfig.apiBaseUrl,
      authService: serviceLocator<AuthService>(),
    ),
  );

  // Register other API services as needed
}

/// Register repositories
void _registerRepositories() {
  // Register repositories here
  // Example:
  // serviceLocator.registerSingleton<NewsRepository>(
  //   NewsRepository(
  //     apiService: serviceLocator<ApiService>(),
  //     cacheService: serviceLocator<CacheService>(),
  //   ),
  // );
}

/// Register BLoCs
void _registerBlocs() {
  // Register BLoCs here
  // Note: BLoCs are typically registered as factories, not singletons
  // Example:
  // serviceLocator.registerFactory<NewsBloc>(
  //   () => NewsBloc(
  //     newsRepository: serviceLocator<NewsRepository>(),
  //   ),
  // );
}
