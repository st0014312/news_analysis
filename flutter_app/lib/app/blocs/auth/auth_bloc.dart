import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/utils/app_logger.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// BLoC for managing authentication
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  /// Authentication service
  final AuthService _authService;

  /// Cache service
  final CacheService _cacheService;

  /// Stream subscription for auth state changes
  StreamSubscription<bool>? _authSubscription;

  /// Constructor
  AuthBloc({
    required AuthService authService,
    required CacheService cacheService,
  })  : _authService = authService,
        _cacheService = cacheService,
        super(const AuthInitial()) {
    on<AuthStarted>(_onAuthStarted);
    on<AuthLoggedIn>(_onAuthLoggedIn);
    on<AuthLoggedOut>(_onAuthLoggedOut);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);

    // Listen to auth state changes
    _authSubscription = _authService.authStateChanges.listen((isAuthenticated) {
      if (isAuthenticated) {
        add(const AuthLoggedIn());
      } else {
        add(const AuthLoggedOut());
      }
    });
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  /// Initialize authentication state
  Future<void> _onAuthStarted(
    AuthStarted event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());

      final isAuthenticated = _authService.isAuthenticated;

      if (isAuthenticated) {
        final user = await _authService.getUserProfile();
        emit(AuthAuthenticated(user: user ?? {}));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      AppLogger.e('Error starting auth', error: e);
      emit(AuthError(message: e.toString()));
    }
  }

  /// Handle logged in event
  Future<void> _onAuthLoggedIn(
    AuthLoggedIn event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());

      final user = await _authService.getUserProfile();
      emit(AuthAuthenticated(user: user ?? {}));
    } catch (e) {
      AppLogger.e('Error handling logged in', error: e);
      emit(AuthError(message: e.toString()));
    }
  }

  /// Handle logged out event
  Future<void> _onAuthLoggedOut(
    AuthLoggedOut event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthUnauthenticated());
  }

  /// Handle login request
  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());

      await _authService.signIn(
        email: event.email,
        password: event.password,
      );

      // Auth state change will trigger AuthLoggedIn event
    } catch (e) {
      AppLogger.e('Error logging in', error: e);
      emit(AuthError(message: e.toString()));
    }
  }

  /// Handle register request
  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());

      await _authService.register(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      );

      // Auth state change will trigger AuthLoggedIn event
    } catch (e) {
      AppLogger.e('Error registering', error: e);
      emit(AuthError(message: e.toString()));
    }
  }

  /// Handle logout request
  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());

      await _authService.signOut();

      // Auth state change will trigger AuthLoggedOut event
    } catch (e) {
      AppLogger.e('Error logging out', error: e);
      emit(AuthError(message: e.toString()));
    }
  }
}
