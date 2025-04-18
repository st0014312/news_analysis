part of 'news_bloc.dart';

/// Base class for news events
abstract class NewsEvent extends Equatable {
  /// Constructor
  const NewsEvent();

  @override
  List<Object?> get props => [];
}

/// Event for requesting news feed
class NewsFeedRequested extends NewsEvent {
  /// Page number
  final int page;

  /// Items per page
  final int limit;

  /// Sort field
  final String sort;

  /// Sort order
  final String order;

  /// Whether to force refresh
  final bool forceRefresh;

  /// Whether to refresh in background
  final bool refreshInBackground;

  /// Constructor
  const NewsFeedRequested({
    this.page = 1,
    this.limit = 20,
    this.sort = 'date',
    this.order = 'desc',
    this.forceRefresh = false,
    this.refreshInBackground = true,
  });

  @override
  List<Object?> get props =>
      [page, limit, sort, order, forceRefresh, refreshInBackground];
}

/// Event for requesting news detail
class NewsDetailRequested extends NewsEvent {
  /// News ID
  final String id;

  /// Constructor
  const NewsDetailRequested({
    required this.id,
  });

  @override
  List<Object?> get props => [id];
}

/// Event for requesting news search
class NewsSearchRequested extends NewsEvent {
  /// Search query
  final String query;

  /// Page number
  final int page;

  /// Items per page
  final int limit;

  /// Constructor
  const NewsSearchRequested({
    required this.query,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [query, page, limit];
}

/// Event for applying news filters
class NewsFilterApplied extends NewsEvent {
  /// Sentiment filter
  final String? sentiment;

  /// Entity filter
  final String? entity;

  /// From date filter
  final String? fromDate;

  /// To date filter
  final String? toDate;

  /// Sort field
  final String sort;

  /// Sort order
  final String order;

  /// Constructor
  const NewsFilterApplied({
    this.sentiment,
    this.entity,
    this.fromDate,
    this.toDate,
    this.sort = 'date',
    this.order = 'desc',
  });

  @override
  List<Object?> get props => [sentiment, entity, fromDate, toDate, sort, order];
}

/// Event for requesting news refresh
class NewsRefreshRequested extends NewsEvent {
  /// Constructor
  const NewsRefreshRequested();
}
