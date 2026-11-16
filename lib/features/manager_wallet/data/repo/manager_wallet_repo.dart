import 'package:dartz/dartz.dart';
import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:goal_master_admin/features/manager_wallet/data/model/manager_wallet_response.dart';
import 'package:goal_master_admin/features/manager_wallet/data/model/topup_checkout.dart';

abstract class ManagerWalletRepo {
  Future<Either<Failure, ManagerWalletResponse>> getWalletSummary();

  Future<Either<Failure, ManagerWalletResponse>> getWalletTransactions({
    int page = 1,
  });

  Future<Either<Failure, String>> chargeCard(String code);

  Future<Either<Failure, TopUpCheckout>> startTopUp(String amount);

  Future<Either<Failure, TopUpConfirmation>> confirmTopUp(String reference);

  Future<Either<Failure, String>> updateLocalPaymentSetting(bool enabled);
}
