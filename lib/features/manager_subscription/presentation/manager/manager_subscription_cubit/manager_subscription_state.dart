part of 'manager_subscription_cubit.dart';


sealed class ManagerSubscriptionState {}

final class ManagerSubscriptionInitial extends ManagerSubscriptionState {}

final class ManagerSubscriptionLoading extends ManagerSubscriptionState {}

final class ManagerSubscriptionLoaded extends ManagerSubscriptionState {
  ManagerSubscriptionLoaded({
    required this.current,
    required this.plans,
  });

  final ManagerCurrentSubscription? current;
  final List<SubscriptionPlanOption> plans;
}

final class ManagerSubscriptionFailure extends ManagerSubscriptionState {
  ManagerSubscriptionFailure(
    this.message, {
    this.current,
    this.plans = const [],
  });

  final String message;
  final ManagerCurrentSubscription? current;
  final List<SubscriptionPlanOption> plans;
}

final class ManagerSubscriptionInsufficientBalance
    extends ManagerSubscriptionState {
  ManagerSubscriptionInsufficientBalance({
    required this.message,
    required this.currentBalance,
    required this.requiredAmount,
    this.current,
    this.plans = const [],
  });

  final String message;
  final double currentBalance;
  final double requiredAmount;
  final ManagerCurrentSubscription? current;
  final List<SubscriptionPlanOption> plans;
}

final class ManagerSubscriptionChanging extends ManagerSubscriptionState {
  ManagerSubscriptionChanging({
    required this.current,
    required this.plans,
  });

  final ManagerCurrentSubscription? current;
  final List<SubscriptionPlanOption> plans;
}

final class ManagerSubscriptionChangeSuccess extends ManagerSubscriptionState {
  ManagerSubscriptionChangeSuccess({
    required this.current,
    required this.plans,
  });

  final ManagerCurrentSubscription current;
  final List<SubscriptionPlanOption> plans;
}
