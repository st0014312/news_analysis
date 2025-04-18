part of 'auth_bloc.dart';

/// Base class for authentication states
abstract class AuthState extends Equatable {
  /// Constructor
  const AuthState();

  @override
  List<Object> get props => [];
}

/// Initial authentication state
class AuthInitial extends AuthState {
  /// Constructor
  const AuthInitial();
}

/// Loading authentication state
class AuthLoading extends AuthState {
  /// Constructor
  const AuthLoading();
}

/// Authenticated state
class AuthAuthenticated extends AuthState {
  /// User data
  final Map<String, dynamic> user;

  /// Constructor
  const AuthAuthenticated({
    required this.user,
  });

  @override
  List<Object> get props => [user];
}

/// Unauthenticated state
class AuthUnauthenticated extends AuthState {
  /// Constructor
  const AuthUnauthenticated();
}

/// Error state
class AuthError extends AuthState {
  /// Error message
  final String message;

  /// Constructor
  const AuthError({
    required this.message,
  });

  @override
  List<Object> get props => [message];
}
