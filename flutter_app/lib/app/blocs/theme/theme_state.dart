part of 'theme_bloc.dart';

/// State for theme bloc
class ThemeState extends Equatable {
  /// Current theme mode
  final ThemeMode themeMode;

  /// Constructor
  const ThemeState({
    required this.themeMode,
  });

  /// Create a copy with updated values
  ThemeState copyWith({
    ThemeMode? themeMode,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  List<Object> get props => [themeMode];
}
