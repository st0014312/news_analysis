part of 'auth_bloc.dart';

/// Base class for authentication events
abstract class AuthEvent extends Equatable {
  /// Constructor
  const AuthEvent();

  @override
  List<Object> get props => [];
}

/// Event for initializing authentication
class AuthStarted extends AuthEvent {
  /// Constructor
  const AuthStarted();
}

/// Event for when user is logged in
class AuthLoggedIn extends AuthEvent {
  /// Constructor
  const AuthLoggedIn();
}

/// Event for when user is logged out
class AuthLoggedOut extends AuthEvent {
  /// Constructor
  const AuthLoggedOut();
}

/// Event for login request
class AuthLoginRequested extends AuthEvent {
  /// Email
  final String email;

  /// Password
  final String password;

  /// Constructor
  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

/// Event for registration request
class AuthRegisterRequested extends AuthEvent {
  /// Email
  final String email;

  /// Password
  final String password;

  /// Display name
  final String displayName;

  /// Constructor
  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.displayName,
  });

  @override
  List<Object> get props => [email, password, displayName];
}

/// Event for logout request
class AuthLogoutRequested extends AuthEvent {
  /// Constructor
  const AuthLogoutRequested();
}
