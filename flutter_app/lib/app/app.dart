import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import '../core/config/app_config.dart';
import '../core/services/service_locator.dart';
import '../core/services/analytics_service.dart';
import '../core/utils/app_logger.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/news/news_bloc.dart';
import 'blocs/subscription/subscription_bloc.dart';
import 'blocs/theme/theme_bloc.dart';

/// Main application widget
class FinancialNewsApp extends StatelessWidget {
  /// Constructor
  const FinancialNewsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => serviceLocator<AuthBloc>(),
        ),
        BlocProvider<NewsBloc>(
          create: (context) => serviceLocator<NewsBloc>(),
        ),
        BlocProvider<SubscriptionBloc>(
          create: (context) => serviceLocator<SubscriptionBloc>(),
        ),
        BlocProvider<ThemeBloc>(
          create: (context) => serviceLocator<ThemeBloc>(),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp.router(
            title: 'Financial News Analyzer',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeState.themeMode,
            routerConfig: AppRouter.router,
            debugShowCheckedModeBanner: !AppConfig.isProduction,
            // Observer is set in the router configuration
            builder: (context, child) {
              // Add global error handling, loading indicators, etc.
              return _ErrorHandler(child: child);
            },
          );
        },
      ),
    );
  }
}

/// Widget for handling global errors
class _ErrorHandler extends StatelessWidget {
  /// Child widget
  final Widget? child;

  /// Constructor
  const _ErrorHandler({Key? key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // You can add error boundary logic here
    // For example, catching Flutter errors and showing a friendly UI

    // For now, just return the child
    if (child == null) {
      return const Center(
        child: Text('An error occurred'),
      );
    }

    return child!;
  }
}
