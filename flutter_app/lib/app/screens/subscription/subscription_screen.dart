import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/subscription/subscription_bloc.dart';
import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';
import '../../../core/utils/app_logger.dart';

/// Subscription screen
class SubscriptionScreen extends StatefulWidget {
  /// Constructor
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String? _selectedPlanId;

  @override
  void initState() {
    super.initState();

    // Load subscription plans
    context.read<SubscriptionBloc>().add(const SubscriptionPlansRequested());

    // Check current subscription status
    context.read<SubscriptionBloc>().add(const SubscriptionStatusRequested());
  }

  /// Subscribe to plan
  void _subscribeToPlan() {
    if (_selectedPlanId != null) {
      context.read<SubscriptionBloc>().add(
            SubscriptionPurchaseRequested(
              planId: _selectedPlanId!,
              paymentMethod: 'credit_card', // Default payment method
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Subscription'),
      ),
      body: BlocConsumer<SubscriptionBloc, SubscriptionState>(
        listener: (context, state) {
          if (state is SubscriptionPurchased) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Successfully subscribed to ${state.tier} plan!'),
                backgroundColor: AppTheme.positiveColor,
              ),
            );

            // Navigate back to home
            context.goNamed(AppRouter.home);
          } else if (state is SubscriptionError) {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is SubscriptionLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is SubscriptionPlansLoaded) {
            return _buildPlansView(state.plans);
          } else if (state is SubscriptionActive) {
            return _buildActiveSubscriptionView(state);
          } else if (state is SubscriptionFree) {
            // If we have plans loaded in the state, show them
            if (state is SubscriptionPlansLoaded) {
              return _buildPlansView((state as SubscriptionPlansLoaded).plans);
            }

            // Otherwise, show a loading indicator
            return const Center(
              child: CircularProgressIndicator(),
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

  /// Build plans view
  Widget _buildPlansView(List<Map<String, dynamic>> plans) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          const Text(
            'Upgrade to Premium',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Get access to premium features and enhance your financial news experience',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Premium features
          _buildFeaturesList(),
          const SizedBox(height: 32),

          // Plans
          ...plans.map((plan) => _buildPlanCard(plan)),
          const SizedBox(height: 24),

          // Subscribe button
          BlocBuilder<SubscriptionBloc, SubscriptionState>(
            builder: (context, state) {
              return ElevatedButton(
                onPressed:
                    state is SubscriptionLoading || _selectedPlanId == null
                        ? null
                        : _subscribeToPlan,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: state is SubscriptionLoading
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Subscribe Now',
                        style: TextStyle(fontSize: 16),
                      ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Terms and conditions
          const Text(
            'By subscribing, you agree to our Terms of Service and Privacy Policy. '
            'Subscriptions will automatically renew unless canceled at least 24 hours before the end of the current period.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build plan card
  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final planId = plan['id'] ?? '';
    final name = plan['name'] ?? '';
    final price = plan['price'] ?? 0.0;
    final interval = plan['interval'] ?? 'month';
    final features = List<String>.from(plan['features'] ?? []);
    final isSelected = planId == _selectedPlanId;

    // Skip free plan
    if (planId == 'free') {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPlanId = planId;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plan name and selection indicator
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Radio<String>(
                    value: planId,
                    groupValue: _selectedPlanId,
                    onChanged: (value) {
                      setState(() {
                        _selectedPlanId = value;
                      });
                    },
                    activeColor: AppTheme.primaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Price
              RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(
                      text: '\$${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    TextSpan(
                      text: '/$interval',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Features
              ...features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppTheme.positiveColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(feature),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  /// Build features list
  Widget _buildFeaturesList() {
    final features = [
      {
        'icon': Icons.notifications_active,
        'title': 'Real-time Alerts',
        'description': 'Get instant notifications for market-moving news',
      },
      {
        'icon': Icons.analytics,
        'title': 'Advanced Analytics',
        'description': 'Detailed sentiment analysis and entity extraction',
      },
      {
        'icon': Icons.dashboard_customize,
        'title': 'Custom Watchlists',
        'description': 'Create and monitor multiple stock watchlists',
      },
      {
        'icon': Icons.history,
        'title': 'Historical Data',
        'description': 'Access to historical news and sentiment data',
      },
    ];

    return Column(
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  feature['icon'] as IconData,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature['title'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature['description'] as String,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Build active subscription view
  Widget _buildActiveSubscriptionView(SubscriptionActive state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.positiveColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppTheme.positiveColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'You\'re a Premium Subscriber!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Subscription details
            Text(
              'You are currently on the ${state.tier} plan',
              style: const TextStyle(
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Expiry date
            if (state.expiryDate != null) ...[
              Text(
                'Your subscription will renew on ${_formatDate(state.expiryDate!)}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],

            // Manage subscription button
            OutlinedButton(
              onPressed: () {
                // Show subscription management options
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Manage Subscription'),
                    content: const Text(
                      'Do you want to cancel your subscription? You will still have access until the end of your current billing period.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Keep Subscription'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Cancel subscription
                          context.read<SubscriptionBloc>().add(
                                SubscriptionCancelRequested(
                                  subscriptionId:
                                      'subscription_id', // This would come from the state
                                ),
                              );
                        },
                        child: const Text('Cancel Subscription'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Manage Subscription'),
            ),
            const SizedBox(height: 16),

            // Back to home button
            TextButton(
              onPressed: () {
                context.goNamed(AppRouter.home);
              },
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }

  /// Format date
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
