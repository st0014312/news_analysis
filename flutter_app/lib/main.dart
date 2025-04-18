import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/services/service_locator.dart';
import 'core/utils/app_logger.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logger
  AppLogger.init();
  AppLogger.log.i('Starting Financial News Analyzer app');

  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    AppLogger.log.i('Firebase initialized');

    // Initialize Hive for local storage
    await Hive.initFlutter();
    AppLogger.log.i('Hive initialized');

    // Register Hive adapters
    // registerAdapters();

    // Initialize SharedPreferences
    final sharedPreferences = await SharedPreferences.getInstance();
    AppLogger.log.i('SharedPreferences initialized');

    // Initialize secure storage
    const secureStorage = FlutterSecureStorage();
    AppLogger.log.i('Secure storage initialized');

    // Initialize service locator
    await setupServiceLocator(
      sharedPreferences: sharedPreferences,
      secureStorage: secureStorage,
    );
    AppLogger.log.i('Service locator initialized');

    // Set up app configuration
    await AppConfig.initialize(flavor: 'development');
    AppLogger.log.i('App configuration initialized');

    // Run the app
    runApp(const FinancialNewsApp());
  } catch (e, stackTrace) {
    AppLogger.log
        .e('Error during app initialization', error: e, stackTrace: stackTrace);
    // Show error screen or handle gracefully
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Error initializing app: $e'),
          ),
        ),
      ),
    );
  }
}
