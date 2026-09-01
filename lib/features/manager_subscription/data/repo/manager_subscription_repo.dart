import 'package:dartz/dartz.dart';
import 'package:goal_master_admin/features/manager_subscription/data/model/subscription_lifecycle.dart';
import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:goal_master_admin/features/manager_onboarding/data/model/subscription_plan_option.dart';
import 'package:goal_master_admin/features/manager_subscription/data/model/manager_subscription_response.dart';

abstract class ManagerSubscriptionRepo {
  Future<Either<Failure, List<SubscriptionPlanOption>>> getPlans();

  Future<Either<Failure, ManagerCurrentSubscription?>> getCurrentSubscription();

  Future<Either<Failure, ManagerCurrentSubscription>> changeSubscription({
    required int subscriptionPlanId,
    required String billingCycle,
  });

  Future<Either<Failure, ManagerCurrentSubscription>> updateAutoRenew({
    required bool enabled,
  });

  /// What each plan would mean for this manager now. Read-only: previewing a
  /// price never spends a promotional cycle.
  Future<Either<Failure, SubscriptionLifecycle>> loadLifecycle();

  /// Drop a scheduled change before it takes effect.
  Future<Either<Failure, ManagerCurrentSubscription?>> cancelScheduledChange();
}
