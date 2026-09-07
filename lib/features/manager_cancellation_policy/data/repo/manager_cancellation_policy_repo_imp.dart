import 'package:dartz/dartz.dart';
import 'package:goal_master_admin/core/databases/api/api_consumer.dart';
import 'package:goal_master_admin/core/databases/api/api_consumer_extension.dart';
import 'package:goal_master_admin/core/databases/api/end_points.dart';
import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:goal_master_admin/features/manager_cancellation_policy/data/model/manager_cancellation_policy_response.dart';
import 'package:goal_master_admin/features/manager_cancellation_policy/data/repo/manager_cancellation_policy_repo.dart';

class ManagerCancellationPolicyRepoImp extends ManagerCancellationPolicyRepo {
  final ApiConsumer consumer;

  ManagerCancellationPolicyRepoImp(this.consumer);

  @override
  Future<Either<Failure, ManagerCancellationPolicyData>> getPolicy() {
    return consumer.handleRequest(
      () => consumer.get(EndPoints.managerCancellationPolicy),
      (res) => ManagerCancellationPolicyResponse.fromJson(res).data!,
    );
  }

  @override
  Future<Either<Failure, String>> updatePolicy({
    required double freeHours,
    required double partial75Hours,
    required double partial50Hours,
  }) {
    return consumer.handleRequest(
      () => consumer.post(
        EndPoints.managerCancellationPolicy,
        data: {
          'free_hours': freeHours,
          'partial_75_hours': partial75Hours,
          'partial_50_hours': partial50Hours,
        },
      ),
      (res) => res['message']?.toString() ?? 'تم حفظ سياسة الإلغاء بنجاح',
    );
  }
}
