import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../blocs/news/news_bloc.dart';
import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';
import '../../../core/utils/app_logger.dart';

/// News detail screen
class NewsDetailScreen extends StatefulWidget {
  /// News ID
  final String id;

  /// Constructor
  const NewsDetailScreen({
    Key? key,
    required this.id,
  }) : super(key: key);

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showAppBarTitle = false;

  @override
  void initState() {
    super.initState();

    // Load news detail
    context.read<NewsBloc>().add(NewsDetailRequested(id: widget.id));

    // Listen to scroll events
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Handle scroll events
  void _onScroll() {
    final showTitle = _scrollController.offset > 150;
    if (showTitle != _showAppBarTitle) {
      setState(() {
        _showAppBarTitle = showTitle;
      });
    }
  }

  /// Share news
  void _shareNews(Map<String, dynamic> news) {
    final title = news['title'] ?? 'Financial News';
    final url = news['url'] ?? '';
    final summary = news['summary'] ?? '';

    final shareText = '$title\n\n$summary\n\nRead more: $url';

    Share.share(shareText, subject: title);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<NewsBloc, NewsState>(
        builder: (context, state) {
          if (state is NewsLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is NewsDetailLoaded) {
            final news = state.news;
            return _buildDetailView(news);
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
                          .add(NewsDetailRequested(id: widget.id));
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
    );
  }

  /// Build detail view
  Widget _buildDetailView(Map<String, dynamic> news) {
    final sentiment =
        news['sentiment'] ?? {'category': 'neutral', 'score': 0.0};
    final sentimentCategory = sentiment['category'] ?? 'neutral';
    final entities = List<Map<String, dynamic>>.from(news['entities'] ?? []);
    final relatedArticles =
        List<Map<String, dynamic>>.from(news['related_articles'] ?? []);

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // App bar
        SliverAppBar(
          expandedHeight: 200,
          floating: false,
          pinned: true,
          title: _showAppBarTitle ? Text(news['title'] ?? 'News Detail') : null,
          flexibleSpace: FlexibleSpaceBar(
            background: news['metadata']?['image_url'] != null
                ? Image.network(
                    news['metadata']['image_url'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppTheme.primaryColor,
                        child: const Center(
                          child: Icon(
                            Icons.bar_chart,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    color: AppTheme.primaryColor,
                    child: const Center(
                      child: Icon(
                        Icons.bar_chart,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                  ),
          ),
          actions: [
            // Share button
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareNews(news),
            ),
            // Bookmark button
            IconButton(
              icon: const Icon(Icons.bookmark_border),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Article bookmarked'),
                  ),
                );
              },
            ),
          ],
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  news['title'] ?? 'No Title',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Source and date
                Row(
                  children: [
                    Text(
                      news['source'] ?? 'Unknown Source',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('•'),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(news['published_at']),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Sentiment badge
                _buildSentimentBadge(sentimentCategory, sentiment['score']),
                const SizedBox(height: 16),

                // Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Summary',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(news['summary'] ?? 'No summary available'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Content
                const Text(
                  'Full Article',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(news['content'] ?? 'No content available'),
                const SizedBox(height: 24),

                // Entities
                if (entities.isNotEmpty) ...[
                  const Text(
                    'Mentioned Entities',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildEntitiesList(entities),
                  const SizedBox(height: 24),
                ],

                // Related articles
                if (relatedArticles.isNotEmpty) ...[
                  const Text(
                    'Related Articles',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildRelatedArticles(relatedArticles),
                  const SizedBox(height: 24),
                ],

                // Source link
                if (news['url'] != null) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      // Open URL
                    },
                    icon: const Icon(Icons.link),
                    label: const Text('View Original Article'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build sentiment badge
  Widget _buildSentimentBadge(String sentiment, double? score) {
    Color color;
    IconData icon;
    String scoreText =
        score != null ? '${(score * 100).toStringAsFixed(0)}%' : '';

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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            sentiment,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (scoreText.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              scoreText,
              style: TextStyle(
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build entities list
  Widget _buildEntitiesList(List<Map<String, dynamic>> entities) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: entities.map((entity) {
        final name = entity['name'] ?? '';
        final type = entity['type'] ?? '';
        final relevance = entity['relevance'] ?? 0.0;

        return ActionChip(
          label: Text(name),
          avatar: _getEntityIcon(type),
          onPressed: () {
            // Filter news by entity
            context.pushNamed(
              AppRouter.home,
              extra: {'filter_entity': name},
            );
          },
          backgroundColor: _getEntityColor(type).withOpacity(0.1),
        );
      }).toList(),
    );
  }

  /// Get entity icon
  Widget? _getEntityIcon(String type) {
    IconData iconData;

    switch (type.toLowerCase()) {
      case 'company':
        iconData = Icons.business;
        break;
      case 'ticker':
        iconData = Icons.show_chart;
        break;
      case 'person':
        iconData = Icons.person;
        break;
      case 'sector':
        iconData = Icons.category;
        break;
      default:
        iconData = Icons.label;
        break;
    }

    return Icon(
      iconData,
      size: 16,
    );
  }

  /// Get entity color
  Color _getEntityColor(String type) {
    switch (type.toLowerCase()) {
      case 'company':
        return Colors.blue;
      case 'ticker':
        return Colors.green;
      case 'person':
        return Colors.purple;
      case 'sector':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Build related articles
  Widget _buildRelatedArticles(List<Map<String, dynamic>> articles) {
    return Column(
      children: articles.map((article) {
        return ListTile(
          title: Text(
            article['title'] ?? 'No Title',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            context.pushNamed(
              AppRouter.newsDetail,
              pathParameters: {'id': article['id']},
            );
          },
        );
      }).toList(),
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
