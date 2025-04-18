part of 'news_bloc.dart';

/// Base class for news states
abstract class NewsState extends Equatable {
  /// Constructor
  const NewsState();

  @override
  List<Object?> get props => [];
}

/// Initial news state
class NewsInitial extends NewsState {
  /// Constructor
  const NewsInitial();
}

/// Loading news state
class NewsLoading extends NewsState {
  /// Constructor
  const NewsLoading();
}

/// News feed loaded state
class NewsFeedLoaded extends NewsState {
  /// News items
  final List<Map<String, dynamic>> news;

  /// Total items
  final int total;

  /// Current page
  final int page;

  /// Items per page
  final int limit;

  /// Applied filters
  final Map<String, dynamic>? filters;

  /// Whether the data is from cache
  final bool isFromCache;

  /// Constructor
  const NewsFeedLoaded({
    required this.news,
    this.total = 0,
    this.page = 1,
    this.limit = 20,
    this.filters,
    this.isFromCache = false,
  });

  @override
  List<Object?> get props => [news, total, page, limit, filters, isFromCache];
}

/// News detail loaded state
class NewsDetailLoaded extends NewsState {
  /// News item
  final Map<String, dynamic> news;

  /// Constructor
  const NewsDetailLoaded({
    required this.news,
  });

  @override
  List<Object?> get props => [news];
}

/// News search loaded state
class NewsSearchLoaded extends NewsState {
  /// News items
  final List<Map<String, dynamic>> news;

  /// Search query
  final String query;

  /// Total items
  final int total;

  /// Current page
  final int page;

  /// Items per page
  final int limit;

  /// Constructor
  const NewsSearchLoaded({
    required this.news,
    required this.query,
    this.total = 0,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [news, query, total, page, limit];
}

/// Error state
class NewsError extends NewsState {
  /// Error message
  final String message;

  /// Constructor
  const NewsError({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}
