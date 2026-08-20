import 'package:dartz/dartz.dart';
import 'package:goal_master_admin/core/databases/api/api_consumer.dart';
import 'package:goal_master_admin/core/databases/api/api_consumer_extension.dart';
import 'package:goal_master_admin/core/databases/api/end_points.dart';
import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:goal_master_admin/features/manager_wallet/data/model/manager_wallet_response.dart';
import 'package:goal_master_admin/features/manager_wallet/data/repo/manager_wallet_repo.dart';

class ManagerWalletRepoImp extends ManagerWalletRepo {
  final ApiConsumer consumer;

  ManagerWalletRepoImp(this.consumer);

  @override
  Future<Either<Failure, ManagerWalletResponse>> getWalletSummary() {
    return consumer.handleRequest(
      () => consumer.get(EndPoints.managerWalletSummary),
      (res) => ManagerWalletResponse.fromJson(res),
    );
  }

  @override
  Future<Either<Failure, ManagerWalletResponse>> getWalletTransactions({
    int page = 1,
  }) {
    return consumer.handleRequest(
      () => consumer.get(
        EndPoints.managerWalletTransactions,
        queryParameters: {'page': page},
      ),
      (res) => ManagerWalletResponse.fromJson(res),
    );
  }

  @override
  Future<Either<Failure, String>> chargeCard(String code) {
    return consumer.handleRequest(
      () => consumer.post(
        EndPoints.charge,
        data: {'code': code},
      ),
      (res) => res['message']?.toString() ?? 'تم شحن المحفظة بنجاح',
    );
  }

  @override
  Future<Either<Failure, String>> confirmTopUp(
    String amount,
    String status, {
    String? reference,
  }) {
    return consumer.handleRequest(
      () => consumer.post(
        EndPoints.managerWalletConfirmTopUp,
        data: {
          'amount': amount,
          'status': status,
          if (reference != null && reference.isNotEmpty) 'reference': reference,
        },
      ),
      (res) => res['message']?.toString() ?? 'تمت العملية بنجاح',
    );
  }

  @override
  Future<Either<Failure, String>> updateLocalPaymentSetting(bool enabled) {
    return consumer.handleRequest(
      () => consumer.post(
        EndPoints.managerWalletLocalPaymentSetting,
        data: {'enabled': enabled},
      ),
      (res) => res['message']?.toString() ?? 'تم تحديث الإعداد بنجاح',
    );
  }
}
