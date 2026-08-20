part of 'subscription_plans_cubit.dart';

sealed class SubscriptionPlansState {}

final class SubscriptionPlansInitial extends SubscriptionPlansState {}

final class SubscriptionPlansLoading extends SubscriptionPlansState {}

final class SubscriptionPlansLoaded extends SubscriptionPlansState {
  final List<SubscriptionPlanOption> plans;

  SubscriptionPlansLoaded(this.plans);
}

final class SubscriptionPlansError extends SubscriptionPlansState {
  final String message;

  SubscriptionPlansError(this.message);
}
