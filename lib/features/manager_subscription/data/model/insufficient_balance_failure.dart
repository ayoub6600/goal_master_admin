import 'package:goal_master_admin/core/errors/failure.dart';

class InsufficientBalanceFailure extends Failure {
  InsufficientBalanceFailure({
    required super.errMessage,
    required this.currentBalance,
    required this.requiredAmount,
  });

  final double currentBalance;
  final double requiredAmount;
}
