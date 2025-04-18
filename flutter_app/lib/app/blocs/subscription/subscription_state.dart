part of 'subscription_bloc.dart';

/// Base class for subscription states
abstract class SubscriptionState extends Equatable {
  /// Constructor
  const SubscriptionState();

  @override
  List<Object?> get props => [];
}

/// Initial subscription state
class SubscriptionInitial extends SubscriptionState {
  /// Constructor
  const SubscriptionInitial();
}

/// Loading subscription state
class SubscriptionLoading extends SubscriptionState {
  /// Constructor
  const SubscriptionLoading();
}

/// Subscription plans loaded state
class SubscriptionPlansLoaded extends SubscriptionState {
  /// Subscription plans
  final List<Map<String, dynamic>> plans;

  /// Constructor
  const SubscriptionPlansLoaded({
    required this.plans,
  });

  @override
  List<Object?> get props => [plans];
}

/// Subscription purchased state
class SubscriptionPurchased extends SubscriptionState {
  /// Subscription ID
  final String subscriptionId;

  /// Subscription tier
  final String tier;

  /// Expiry date
  final String expiryDate;

  /// Constructor
  const SubscriptionPurchased({
    required this.subscriptionId,
    required this.tier,
    required this.expiryDate,
  });

  @override
  List<Object?> get props => [subscriptionId, tier, expiryDate];
}

/// Free subscription state
class SubscriptionFree extends SubscriptionState {
  /// Constructor
  const SubscriptionFree();
}

/// Active subscription state
class SubscriptionActive extends SubscriptionState {
  /// Subscription tier
  final String tier;

  /// Expiry date
  final String? expiryDate;

  /// Constructor
  const SubscriptionActive({
    required this.tier,
    this.expiryDate,
  });

  @override
  List<Object?> get props => [tier, expiryDate];
}

/// Subscription cancelled state
class SubscriptionCancelled extends SubscriptionState {
  /// Constructor
  const SubscriptionCancelled();
}

/// Error state
class SubscriptionError extends SubscriptionState {
  /// Error message
  final String message;

  /// Constructor
  const SubscriptionError({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}
