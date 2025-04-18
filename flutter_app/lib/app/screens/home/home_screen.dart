import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/news/news_bloc.dart';
import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';
import '../../../core/utils/app_logger.dart';

/// Home screen with news feed
class HomeScreen extends StatefulWidget {
  /// Constructor
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  // Filter values
  String? _selectedSentiment;
  String? _selectedEntity;
  String _sortBy = 'date';
  String _sortOrder = 'desc';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load news feed
    context.read<NewsBloc>().add(const NewsFeedRequested());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  /// Handle refresh
  void _onRefresh() {
    context.read<NewsBloc>().add(const NewsFeedRequested(forceRefresh: true));
    _refreshController.refreshCompleted();
  }

  /// Handle loading more
  void _onLoading() {
    final state = context.read<NewsBloc>().state;
    if (state is NewsFeedLoaded) {
      context.read<NewsBloc>().add(NewsFeedRequested(
            page: state.page + 1,
            forceRefresh: true,
          ));
    }
    _refreshController.loadComplete();
  }

  /// Apply filters
  void _applyFilters() {
    context.read<NewsBloc>().add(NewsFilterApplied(
          sentiment: _selectedSentiment,
          entity: _selectedEntity,
          sort: _sortBy,
          order: _sortOrder,
        ));

    Navigator.pop(context); // Close filter dialog
  }

  /// Reset filters
  void _resetFilters() {
    setState(() {
      _selectedSentiment = null;
      _selectedEntity = null;
      _sortBy = 'date';
      _sortOrder = 'desc';
    });

    context.read<NewsBloc>().add(const NewsFeedRequested(forceRefresh: true));
    Navigator.pop(context); // Close filter dialog
  }

  /// Show filter dialog
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filter News'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sentiment filter
                const Text('Sentiment',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Positive'),
                      selected: _selectedSentiment == 'positive',
                      onSelected: (selected) {
                        setState(() {
                          _selectedSentiment = selected ? 'positive' : null;
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: AppTheme.positiveColor.withOpacity(0.2),
                      checkmarkColor: AppTheme.positiveColor,
                    ),
                    FilterChip(
                      label: const Text('Negative'),
                      selected: _selectedSentiment == 'negative',
                      onSelected: (selected) {
                        setState(() {
                          _selectedSentiment = selected ? 'negative' : null;
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: AppTheme.negativeColor.withOpacity(0.2),
                      checkmarkColor: AppTheme.negativeColor,
                    ),
                    FilterChip(
                      label: const Text('Neutral'),
                      selected: _selectedSentiment == 'neutral',
                      onSelected: (selected) {
                        setState(() {
                          _selectedSentiment = selected ? 'neutral' : null;
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: AppTheme.neutralColor.withOpacity(0.2),
                      checkmarkColor: AppTheme.neutralColor,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Sort options
                const Text('Sort By',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'date', child: Text('Date')),
                    DropdownMenuItem(
                        value: 'relevance', child: Text('Relevance')),
                    DropdownMenuItem(
                        value: 'sentiment', child: Text('Sentiment')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _sortBy = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Sort order
                const Text('Sort Order',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'desc', label: Text('Descending')),
                    ButtonSegment(value: 'asc', label: Text('Ascending')),
                  ],
                  selected: {_sortOrder},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _sortOrder = selection.first;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _resetFilters,
              child: const Text('Reset'),
            ),
            ElevatedButton(
              onPressed: _applyFilters,
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial News'),
        actions: [
          // Search button
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              context.pushNamed(AppRouter.newsSearch);
            },
          ),
          // Filter button
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          // Profile button
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              context.pushNamed(AppRouter.profile);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Stocks'),
            Tab(text: 'Markets'),
          ],
        ),
      ),
      body: BlocBuilder<NewsBloc, NewsState>(
        builder: (context, state) {
          if (state is NewsInitial ||
              state is NewsLoading && state is! NewsFeedLoaded) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is NewsFeedLoaded) {
            return SmartRefresher(
              controller: _refreshController,
              onRefresh: _onRefresh,
              onLoading: _onLoading,
              enablePullUp: true,
              child: state.news.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: state.news.length,
                      itemBuilder: (context, index) {
                        final news = state.news[index];
                        return _buildNewsCard(news);
                      },
                    ),
            );
          } else if (state is NewsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppTheme.errorColor,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<NewsBloc>()
                          .add(const NewsFeedRequested(forceRefresh: true));
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          } else {
            return const Center(
              child: Text('Unknown state'),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show subscription options
          context.pushNamed(AppRouter.subscription);
        },
        child: const Icon(Icons.star),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.article_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No news found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try changing your filters or check back later',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context
                  .read<NewsBloc>()
                  .add(const NewsFeedRequested(forceRefresh: true));
            },
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  /// Build news card
  Widget _buildNewsCard(Map<String, dynamic> news) {
    final sentiment =
        news['sentiment'] ?? {'category': 'neutral', 'score': 0.0};
    final sentimentCategory = sentiment['category'] ?? 'neutral';
    final entities = List<Map<String, dynamic>>.from(news['entities'] ?? []);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          context.pushNamed(
            AppRouter.newsDetail,
            pathParameters: {'id': news['id']},
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and sentiment badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      news['title'] ?? 'No Title',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildSentimentBadge(sentimentCategory),
                ],
              ),
              const SizedBox(height: 8),

              // Summary
              Text(
                news['summary'] ?? 'No summary available',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Entities
              if (entities.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: entities
                      .take(3)
                      .map((entity) => Chip(
                            label: Text(
                              entity['name'] ?? '',
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Colors.grey.shade200,
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ))
                      .toList(),
                ),
                const SizedBox(height: 8),
              ],

              // Source and date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    news['source'] ?? 'Unknown Source',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _formatDate(news['published_at']),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build sentiment badge
  Widget _buildSentimentBadge(String sentiment) {
    Color color;
    IconData icon;

    switch (sentiment.toLowerCase()) {
      case 'positive':
        color = AppTheme.positiveColor;
        icon = Icons.thumb_up;
        break;
      case 'negative':
        color = AppTheme.negativeColor;
        icon = Icons.thumb_down;
        break;
      case 'neutral':
      default:
        color = AppTheme.neutralColor;
        icon = Icons.thumbs_up_down;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            sentiment,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Format date
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Unknown date';
    }

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Invalid date';
    }
  }
}
