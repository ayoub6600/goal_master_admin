import 'package:dartz/dartz.dart';
import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:goal_master_admin/features/auth/data/model/login_model/user.dart';
import 'package:goal_master_admin/features/manager_onboarding/data/model/manager_signup_request_model.dart';
import 'package:goal_master_admin/features/manager_onboarding/data/model/subscription_plan_option.dart';

abstract class ManagerSignupRepo {
  Future<Either<Failure, List<SubscriptionPlanOption>>> getPublicPlans();

  Future<Either<Failure, UserData>> registerManager(
    ManagerSignupRequestModel request,
  );
}
