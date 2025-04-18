import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/services/cache_service.dart';

/// Splash screen
class SplashScreen extends StatefulWidget {
  /// Constructor
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    // Start animation
    _animationController.forward();

    // Initialize app
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Initialize app
  Future<void> _initializeApp() async {
    try {
      // Simulate initialization delay
      await Future.delayed(const Duration(seconds: 2));

      // Check authentication state
      if (mounted) {
        context.read<AuthBloc>().add(const AuthStarted());
      }

      // Navigate based on onboarding status
      if (mounted) {
        final cacheService = context.read<CacheService>();
        final isOnboardingCompleted = cacheService.isOnboardingCompleted();

        if (!isOnboardingCompleted) {
          context.goNamed(AppRouter.onboarding);
        } else {
          // Auth state will handle navigation
        }
      }
    } catch (e) {
      AppLogger.e('Error initializing app', error: e);

      // Navigate to error screen
      if (mounted) {
        context.goNamed(
          AppRouter.error,
          extra: {'error': 'Failed to initialize app: ${e.toString()}'},
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.goNamed(AppRouter.home);
        } else if (state is AuthUnauthenticated) {
          context.goNamed(AppRouter.login);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Authentication error: ${state.message}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
          context.goNamed(AppRouter.login);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.primaryColor,
        body: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.bar_chart,
                    size: 80,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),

                // App name
                const Text(
                  'Financial News Analyzer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Loading indicator
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
