import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/services/cache_service.dart';
import '../../../core/utils/app_logger.dart';

part 'theme_event.dart';
part 'theme_state.dart';

/// BLoC for managing app theme
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  /// Cache service for storing theme preference
  final CacheService _cacheService;

  /// Constructor
  ThemeBloc({
    required CacheService cacheService,
  })  : _cacheService = cacheService,
        super(const ThemeState(themeMode: ThemeMode.system)) {
    on<ThemeStarted>(_onThemeStarted);
    on<ThemeChanged>(_onThemeChanged);
  }

  /// Initialize theme from cache
  Future<void> _onThemeStarted(
    ThemeStarted event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      final themeString = _cacheService.getTheme();
      if (themeString != null) {
        final themeMode = _getThemeModeFromString(themeString);
        emit(state.copyWith(themeMode: themeMode));
      }
    } catch (e) {
      AppLogger.e('Error loading theme', error: e);
    }
  }

  /// Handle theme change
  Future<void> _onThemeChanged(
    ThemeChanged event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      final themeMode = event.themeMode;
      await _cacheService.saveTheme(_getStringFromThemeMode(themeMode));
      emit(state.copyWith(themeMode: themeMode));
    } catch (e) {
      AppLogger.e('Error changing theme', error: e);
    }
  }

  /// Convert theme mode to string
  String _getStringFromThemeMode(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }

  /// Convert string to theme mode
  ThemeMode _getThemeModeFromString(String themeString) {
    switch (themeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}
