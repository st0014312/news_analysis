import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/services/api_service.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/utils/app_logger.dart';

part 'news_event.dart';
part 'news_state.dart';

/// BLoC for managing news
class NewsBloc extends Bloc<NewsEvent, NewsState> {
  /// API service
  final ApiService _apiService;

  /// Cache service
  final CacheService _cacheService;

  /// Constructor
  NewsBloc({
    required ApiService apiService,
    required CacheService cacheService,
  })  : _apiService = apiService,
        _cacheService = cacheService,
        super(const NewsInitial()) {
    on<NewsFeedRequested>(_onNewsFeedRequested);
    on<NewsDetailRequested>(_onNewsDetailRequested);
    on<NewsSearchRequested>(_onNewsSearchRequested);
    on<NewsFilterApplied>(_onNewsFilterApplied);
    on<NewsRefreshRequested>(_onNewsRefreshRequested);
  }

  /// Handle news feed request
  Future<void> _onNewsFeedRequested(
    NewsFeedRequested event,
    Emitter<NewsState> emit,
  ) async {
    try {
      emit(const NewsLoading());

      // Try to get from cache first
      final cachedNews = _cacheService.getNewsFeed();
      if (cachedNews != null && !event.forceRefresh) {
        emit(NewsFeedLoaded(news: cachedNews));

        // Refresh in background if needed
        if (event.refreshInBackground) {
          _refreshNewsFeed();
        }
        return;
      }

      // Fetch from API
      final response = await _apiService.get(
        '/news',
        queryParameters: {
          'page': event.page,
          'limit': event.limit,
          'sort': event.sort,
          'order': event.order,
        },
      );

      final news = List<Map<String, dynamic>>.from(response['items']);

      // Save to cache
      await _cacheService.saveNewsFeed(news);

      emit(NewsFeedLoaded(
        news: news,
        total: response['total'],
        page: response['page'],
        limit: response['limit'],
      ));
    } catch (e) {
      AppLogger.e('Error fetching news feed', error: e);

      // Try to get from cache as fallback
      final cachedNews = _cacheService.getNewsFeed();
      if (cachedNews != null) {
        emit(NewsFeedLoaded(
          news: cachedNews,
          isFromCache: true,
        ));
      } else {
        emit(NewsError(message: e.toString()));
      }
    }
  }

  /// Handle news detail request
  Future<void> _onNewsDetailRequested(
    NewsDetailRequested event,
    Emitter<NewsState> emit,
  ) async {
    try {
      emit(const NewsLoading());

      // Fetch from API
      final response = await _apiService.get('/news/${event.id}');

      emit(NewsDetailLoaded(news: response));
    } catch (e) {
      AppLogger.e('Error fetching news detail', error: e);
      emit(NewsError(message: e.toString()));
    }
  }

  /// Handle news search request
  Future<void> _onNewsSearchRequested(
    NewsSearchRequested event,
    Emitter<NewsState> emit,
  ) async {
    try {
      emit(const NewsLoading());

      // Fetch from API
      final response = await _apiService.get(
        '/news',
        queryParameters: {
          'query': event.query,
          'page': event.page,
          'limit': event.limit,
        },
      );

      final news = List<Map<String, dynamic>>.from(response['items']);

      emit(NewsSearchLoaded(
        news: news,
        query: event.query,
        total: response['total'],
        page: response['page'],
        limit: response['limit'],
      ));
    } catch (e) {
      AppLogger.e('Error searching news', error: e);
      emit(NewsError(message: e.toString()));
    }
  }

  /// Handle news filter applied
  Future<void> _onNewsFilterApplied(
    NewsFilterApplied event,
    Emitter<NewsState> emit,
  ) async {
    try {
      emit(const NewsLoading());

      // Fetch from API
      final response = await _apiService.get(
        '/news',
        queryParameters: {
          'page': 1,
          'limit': 20,
          'sentiment': event.sentiment,
          'entity': event.entity,
          'from_date': event.fromDate,
          'to_date': event.toDate,
          'sort': event.sort,
          'order': event.order,
        },
      );

      final news = List<Map<String, dynamic>>.from(response['items']);

      emit(NewsFeedLoaded(
        news: news,
        total: response['total'],
        page: response['page'],
        limit: response['limit'],
        filters: {
          'sentiment': event.sentiment,
          'entity': event.entity,
          'from_date': event.fromDate,
          'to_date': event.toDate,
          'sort': event.sort,
          'order': event.order,
        },
      ));
    } catch (e) {
      AppLogger.e('Error applying filters', error: e);
      emit(NewsError(message: e.toString()));
    }
  }

  /// Handle news refresh request
  Future<void> _onNewsRefreshRequested(
    NewsRefreshRequested event,
    Emitter<NewsState> emit,
  ) async {
    try {
      // Keep current state
      final currentState = state;

      // Fetch from API
      final response = await _apiService.get(
        '/news',
        queryParameters: {
          'page': 1,
          'limit': 20,
        },
      );

      final news = List<Map<String, dynamic>>.from(response['items']);

      // Save to cache
      await _cacheService.saveNewsFeed(news);

      // Emit new state if still in feed state
      if (currentState is NewsFeedLoaded) {
        emit(NewsFeedLoaded(
          news: news,
          total: response['total'],
          page: response['page'],
          limit: response['limit'],
        ));
      }
    } catch (e) {
      AppLogger.e('Error refreshing news', error: e);
      // Don't emit error, just log it
    }
  }

  /// Refresh news feed in background
  Future<void> _refreshNewsFeed() async {
    try {
      // Fetch from API
      final response = await _apiService.get(
        '/news',
        queryParameters: {
          'page': 1,
          'limit': 20,
        },
      );

      final news = List<Map<String, dynamic>>.from(response['items']);

      // Save to cache
      await _cacheService.saveNewsFeed(news);

      // Add refresh event
      add(const NewsRefreshRequested());
    } catch (e) {
      AppLogger.e('Error refreshing news in background', error: e);
    }
  }
}
