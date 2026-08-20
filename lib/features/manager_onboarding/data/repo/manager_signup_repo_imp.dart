import 'package:dartz/dartz.dart';
import 'package:goal_master_admin/core/databases/api/api_consumer.dart';
import 'package:goal_master_admin/core/databases/api/api_consumer_extension.dart';
import 'package:goal_master_admin/core/databases/api/end_points.dart';
import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:goal_master_admin/features/auth/data/model/login_model/user.dart';
import 'package:goal_master_admin/features/manager_onboarding/data/model/manager_signup_request_model.dart';
import 'package:goal_master_admin/features/manager_onboarding/data/model/subscription_plan_option.dart';
import 'package:goal_master_admin/features/manager_onboarding/data/repo/manager_signup_repo.dart';

class ManagerSignupRepoImp implements ManagerSignupRepo {
  final ApiConsumer consumer;

  ManagerSignupRepoImp(this.consumer);

  @override
  Future<Either<Failure, List<SubscriptionPlanOption>>> getPublicPlans() {
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
  Future<Either<Failure, UserData>> registerManager(
    ManagerSignupRequestModel request,
  ) {
    return consumer.handleRequestCustom(
      () => consumer.post(
        EndPoints.managerRegister,
        data: request.toJson(),
        isFormData: false,
      ),
      (response) async => UserData.fromJson(
        response['data'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}
