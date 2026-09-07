import 'package:dartz/dartz.dart';
import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:goal_master_admin/features/manager_cancellation_policy/data/model/manager_cancellation_policy_response.dart';

abstract class ManagerCancellationPolicyRepo {
  Future<Either<Failure, ManagerCancellationPolicyData>> getPolicy();

  Future<Either<Failure, String>> updatePolicy({
    required double freeHours,
    required double partial75Hours,
    required double partial50Hours,
  });
}
