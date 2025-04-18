part of 'subscription_bloc.dart';

/// Base class for subscription events
abstract class SubscriptionEvent extends Equatable {
  /// Constructor
  const SubscriptionEvent();

  @override
  List<Object?> get props => [];
}

/// Event for requesting subscription plans
class SubscriptionPlansRequested extends SubscriptionEvent {
  /// Constructor
  const SubscriptionPlansRequested();
}

/// Event for requesting subscription purchase
class SubscriptionPurchaseRequested extends SubscriptionEvent {
  /// Plan ID
  final String planId;

  /// Payment method
  final String paymentMethod;

  /// Constructor
  const SubscriptionPurchaseRequested({
    required this.planId,
    required this.paymentMethod,
  });

  @override
  List<Object?> get props => [planId, paymentMethod];
}

/// Event for requesting subscription status
class SubscriptionStatusRequested extends SubscriptionEvent {
  /// Constructor
  const SubscriptionStatusRequested();
}

/// Event for requesting subscription cancellation
class SubscriptionCancelRequested extends SubscriptionEvent {
  /// Subscription ID
  final String subscriptionId;

  /// Constructor
  const SubscriptionCancelRequested({
    required this.subscriptionId,
  });

  @override
  List<Object?> get props => [subscriptionId];
}
