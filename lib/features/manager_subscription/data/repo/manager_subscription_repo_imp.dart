import 'package:dartz/dartz.dart';
import 'package:goal_master_admin/features/manager_subscription/data/model/subscription_lifecycle.dart';
import 'package:dio/dio.dart';
import 'package:goal_master_admin/core/databases/api/api_consumer.dart';
import 'package:goal_master_admin/core/databases/api/api_consumer_extension.dart';
import 'package:goal_master_admin/core/databases/api/end_points.dart';
import 'package:goal_master_admin/core/errors/exceptions.dart';
import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:goal_master_admin/features/manager_onboarding/data/model/subscription_plan_option.dart';
import 'package:goal_master_admin/features/manager_subscription/data/model/insufficient_balance_failure.dart';
import 'package:goal_master_admin/features/manager_subscription/data/model/manager_subscription_response.dart';
import 'package:goal_master_admin/features/manager_subscription/data/repo/manager_subscription_repo.dart';

class ManagerSubscriptionRepoImp implements ManagerSubscriptionRepo {
  final ApiConsumer consumer;

  ManagerSubscriptionRepoImp(this.consumer);

  @override
  Future<Either<Failure, List<SubscriptionPlanOption>>> getPlans() {
    return consumer.handleRequestCustom(
      () => consumer.get(EndPoints.managerPublicPlans),
      (response) async {
        final plans = (response['data'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((item) => SubscriptionPlanOption.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList();
        return plans;
      },
    );
  }

  @override
  Future<Either<Failure, ManagerCurrentSubscription?>> getCurrentSubscription() {
    return consumer.handleRequestCustom(
      () => consumer.get(EndPoints.managerSubscriptionCurrent),
      (response) async {
        final data = response['data'];
        if (data == null) return null;
        return ManagerCurrentSubscription.fromJson(
          Map<String, dynamic>.from(data as Map),
        );
      },
    );
  }

  @override
  Future<Either<Failure, ManagerCurrentSubscription>> changeSubscription({
    required int subscriptionPlanId,
    required String billingCycle,
  }) async {
    try {
      final response = await consumer.post(
        EndPoints.managerSubscriptionChange,
        data: {
          'subscription_plan_id': subscriptionPlanId,
          'billing_cycle': billingCycle,
        },
        isFormData: false,
      );
      return right(
        ManagerCurrentSubscription.fromJson(
          Map<String, dynamic>.from(response['data'] as Map),
        ),
      );
    } catch (e) {
      if (e is DioException &&
          e.response?.statusCode == 422 &&
          e.response?.data is Map &&
          (e.response!.data as Map).containsKey('required_amount')) {
        final data = e.response!.data as Map;
        return left(
          InsufficientBalanceFailure(
            errMessage: data['data']?.toString() ?? 'الرصيد في المحفظة غير كافٍ',
            currentBalance: _toDouble(data['current_balance']),
            requiredAmount: _toDouble(data['required_amount']),
          ),
        );
      }
      if (e is DioException) {
        return left(ServerFailure.fromDioException(e));
      }
      return left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ManagerCurrentSubscription>> updateAutoRenew({
    required bool enabled,
  }) {
    return consumer.handleRequestCustom(
      () => consumer.post(
        EndPoints.managerSubscriptionAutoRenew,
        data: {'enabled': enabled},
        isFormData: false,
      ),
      (response) async => ManagerCurrentSubscription.fromJson(
        Map<String, dynamic>.from(response['data'] as Map),
      ),
    );
  }

  @override
  Future<Either<Failure, SubscriptionLifecycle>> loadLifecycle() {
    return consumer.handleRequest(
      () => consumer.get(EndPoints.managerSubscriptionOptions),
      (data) => SubscriptionLifecycle.fromJson(
        Map<String, dynamic>.from(data['data'] as Map),
      ),
    );
  }

  @override
  Future<Either<Failure, ManagerCurrentSubscription?>> cancelScheduledChange() {
    return consumer.handleRequest(
      () => consumer.post(EndPoints.managerSubscriptionCancelScheduled),
      (data) {
        final payload = data['data'];
        return payload is Map
            ? ManagerCurrentSubscription.fromJson(
                Map<String, dynamic>.from(payload))
            : null;
      },
    );
  }
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
