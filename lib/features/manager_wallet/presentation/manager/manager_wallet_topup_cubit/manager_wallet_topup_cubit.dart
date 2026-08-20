import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goal_master_admin/features/manager_wallet/data/repo/manager_wallet_repo_imp.dart';
import 'package:goal_master_admin/features/manager_wallet/presentation/manager/manager_wallet_topup_cubit/manager_wallet_topup_state.dart';

class ManagerWalletTopUpCubit extends Cubit<ManagerWalletTopUpState> {
  final ManagerWalletRepoImp repo;

  ManagerWalletTopUpCubit(this.repo) : super(const ManagerWalletTopUpInitial());

  Future<void> confirmTopUp(
    String amount, {
    required String status,
    String? reference,
  }) async {
    emit(const ManagerWalletTopUpLoading());
    final result = await repo.confirmTopUp(
      amount,
      status,
      reference: reference,
    );
    result.fold(
      (failure) => emit(ManagerWalletTopUpFailure(failure.errMessage)),
      (message) => emit(ManagerWalletTopUpSuccess(message)),
    );
  }
}
