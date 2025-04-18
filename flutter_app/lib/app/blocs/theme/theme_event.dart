part of 'theme_bloc.dart';

/// Base class for theme events
abstract class ThemeEvent extends Equatable {
  /// Constructor
  const ThemeEvent();

  @override
  List<Object> get props => [];
}

/// Event for initializing theme
class ThemeStarted extends ThemeEvent {
  /// Constructor
  const ThemeStarted();
}

/// Event for changing theme
class ThemeChanged extends ThemeEvent {
  /// New theme mode
  final ThemeMode themeMode;

  /// Constructor
  const ThemeChanged({required this.themeMode});

  @override
  List<Object> get props => [themeMode];
}
