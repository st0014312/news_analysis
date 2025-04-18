import 'package:financial_news_analyzer/core/services/cache_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/service_locator.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/app_logger.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
// import '../screens/auth/register_screen.dart';
// import '../screens/auth/forgot_password_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/news/news_detail_screen.dart';
// import '../screens/news/news_search_screen.dart';
// import '../screens/profile/profile_screen.dart';
// import '../screens/profile/settings_screen.dart';
import '../screens/subscription/subscription_screen.dart';
import '../screens/error_screen.dart';

/// App router configuration
class AppRouter {
  // Private constructor to prevent instantiation
  AppRouter._();

  /// Route names
  static const String splash = 'splash';
  static const String onboarding = 'onboarding';
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgot-password';
  static const String home = 'home';
  static const String newsDetail = 'news-detail';
  static const String newsSearch = 'news-search';
  static const String profile = 'profile';
  static const String settings = 'settings';
  static const String subscription = 'subscription';
  static const String error = 'error';

  /// Route paths
  static const String splashPath = '/';
  static const String onboardingPath = '/onboarding';
  static const String loginPath = '/login';
  static const String registerPath = '/register';
  static const String forgotPasswordPath = '/forgot-password';
  static const String homePath = '/home';
  static const String newsDetailPath = '/news/:id';
  static const String newsSearchPath = '/news/search';
  static const String profilePath = '/profile';
  static const String settingsPath = '/settings';
  static const String subscriptionPath = '/subscription';
  static const String errorPath = '/error';

  /// GoRouter instance
  static final GoRouter router = GoRouter(
    initialLocation: splashPath,
    debugLogDiagnostics: true,
    redirect: _handleRedirect,
    routes: [
      GoRoute(
        name: splash,
        path: splashPath,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        name: onboarding,
        path: onboardingPath,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        name: login,
        path: loginPath,
        builder: (context, state) => const LoginScreen(),
      ),
      // GoRoute(
      //   name: register,
      //   path: registerPath,
      //   builder: (context, state) => const RegisterScreen(),
      // ),
      // GoRoute(
      //   name: forgotPassword,
      //   path: forgotPasswordPath,
      //   builder: (context, state) => const ForgotPasswordScreen(),
      // ),
      GoRoute(
        name: home,
        path: homePath,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        name: newsDetail,
        path: newsDetailPath,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return NewsDetailScreen(id: id);
        },
      ),
      // GoRoute(
      //   name: newsSearch,
      //   path: newsSearchPath,
      //   builder: (context, state) => const NewsSearchScreen(),
      // ),
      // GoRoute(
      //   name: profile,
      //   path: profilePath,
      //   builder: (context, state) => const ProfileScreen(),
      // ),
      // GoRoute(
      //   name: settings,
      //   path: settingsPath,
      //   builder: (context, state) => const SettingsScreen(),
      // ),
      GoRoute(
        name: subscription,
        path: subscriptionPath,
        builder: (context, state) => const SubscriptionScreen(),
      ),
    ],
    errorBuilder: (context, state) => ErrorScreen(
      errorMessage: state.error?.toString() ?? 'Unknown error',
    ),
  );

  /// Handle redirects based on authentication state
  static String? _handleRedirect(BuildContext context, GoRouterState state) {
    try {
      final authService = serviceLocator<AuthService>();
      final isAuthenticated = authService.isAuthenticated;

      // Get the current path
      final currentPath = state.matchedLocation;

      // Check if the path is in the auth group
      final isAuthRoute = currentPath == loginPath ||
          currentPath == registerPath ||
          currentPath == forgotPasswordPath;

      // Check if the path is in the onboarding group
      final isOnboardingRoute = currentPath == onboardingPath;

      // Check if the path is the splash screen
      final isSplashRoute = currentPath == splashPath;

      // Get onboarding status
      final cacheService =
          serviceLocator.get(instanceName: 'cacheService') as CacheService;
      final isOnboardingCompleted = cacheService.isOnboardingCompleted();

      // If the user is on the splash screen, let them proceed
      if (isSplashRoute) {
        return null;
      }

      // If onboarding is not completed and the user is not on the onboarding screen,
      // redirect to onboarding
      if (!isOnboardingCompleted && !isOnboardingRoute && !isSplashRoute) {
        return onboardingPath;
      }

      // If the user is authenticated and trying to access an auth route,
      // redirect to home
      if (isAuthenticated && isAuthRoute) {
        return homePath;
      }

      // If the user is not authenticated and trying to access a protected route,
      // redirect to login
      if (!isAuthenticated &&
          !isAuthRoute &&
          !isOnboardingRoute &&
          !isSplashRoute) {
        return loginPath;
      }

      // Allow the user to proceed
      return null;
    } catch (e) {
      AppLogger.e('Error in router redirect', error: e);
      return null;
    }
  }
}
