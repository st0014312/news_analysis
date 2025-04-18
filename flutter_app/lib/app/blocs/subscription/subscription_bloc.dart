import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/services/api_service.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/utils/app_logger.dart';

part 'subscription_event.dart';
part 'subscription_state.dart';

/// BLoC for managing subscriptions
class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  /// API service
  final ApiService _apiService;

  /// Cache service
  final CacheService _cacheService;

  /// Constructor
  SubscriptionBloc({
    required ApiService apiService,
    required CacheService cacheService,
  })  : _apiService = apiService,
        _cacheService = cacheService,
        super(const SubscriptionInitial()) {
    on<SubscriptionPlansRequested>(_onSubscriptionPlansRequested);
    on<SubscriptionPurchaseRequested>(_onSubscriptionPurchaseRequested);
    on<SubscriptionStatusRequested>(_onSubscriptionStatusRequested);
    on<SubscriptionCancelRequested>(_onSubscriptionCancelRequested);
  }

  /// Handle subscription plans request
  Future<void> _onSubscriptionPlansRequested(
    SubscriptionPlansRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(const SubscriptionLoading());

      // Fetch from API
      final response = await _apiService.get('/subscriptions');

      final plans = List<Map<String, dynamic>>.from(response['plans']);

      emit(SubscriptionPlansLoaded(plans: plans));
    } catch (e) {
      AppLogger.e('Error fetching subscription plans', error: e);
      emit(SubscriptionError(message: e.toString()));
    }
  }

  /// Handle subscription purchase request
  Future<void> _onSubscriptionPurchaseRequested(
    SubscriptionPurchaseRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(const SubscriptionLoading());

      // Send purchase request to API
      final response = await _apiService.post(
        '/subscriptions',
        data: {
          'plan_id': event.planId,
          'payment_method': event.paymentMethod,
        },
      );

      emit(SubscriptionPurchased(
        subscriptionId: response['subscription_id'],
        tier: response['tier'],
        expiryDate: response['end_date'],
      ));
    } catch (e) {
      AppLogger.e('Error purchasing subscription', error: e);
      emit(SubscriptionError(message: e.toString()));
    }
  }

  /// Handle subscription status request
  Future<void> _onSubscriptionStatusRequested(
    SubscriptionStatusRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(const SubscriptionLoading());

      // Fetch user profile from cache
      final user = await _cacheService.getUser();

      if (user != null) {
        final tier = user['subscription_tier'] ?? 'free';
        final expiryDate = user['subscription_expiry'];

        if (tier == 'free') {
          emit(const SubscriptionFree());
        } else {
          emit(SubscriptionActive(
            tier: tier,
            expiryDate: expiryDate,
          ));
        }
      } else {
        emit(const SubscriptionFree());
      }
    } catch (e) {
      AppLogger.e('Error fetching subscription status', error: e);
      emit(SubscriptionError(message: e.toString()));
    }
  }

  /// Handle subscription cancel request
  Future<void> _onSubscriptionCancelRequested(
    SubscriptionCancelRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(const SubscriptionLoading());

      // Send cancel request to API
      await _apiService.delete(
        '/subscriptions/${event.subscriptionId}',
      );

      emit(const SubscriptionCancelled());

      // Refresh status
      add(const SubscriptionStatusRequested());
    } catch (e) {
      AppLogger.e('Error cancelling subscription', error: e);
      emit(SubscriptionError(message: e.toString()));
    }
  }
}
