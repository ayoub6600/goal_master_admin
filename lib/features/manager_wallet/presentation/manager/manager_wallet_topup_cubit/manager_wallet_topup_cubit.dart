import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goal_master_admin/features/manager_wallet/data/repo/manager_wallet_repo_imp.dart';
import 'package:goal_master_admin/features/manager_wallet/presentation/manager/manager_wallet_topup_cubit/manager_wallet_topup_state.dart';

class ManagerWalletTopUpCubit extends Cubit<ManagerWalletTopUpState> {
  final ManagerWalletRepoImp repo;

  ManagerWalletTopUpCubit(this.repo) : super(const ManagerWalletTopUpInitial());

  /// Asks the server to open a top-up for [amount].
  Future<void> start(String amount) async {
    emit(const ManagerWalletTopUpLoading());
    final result = await repo.startTopUp(amount);
    result.fold(
      (failure) => emit(ManagerWalletTopUpFailure(failure.errMessage)),
      (checkout) => emit(ManagerWalletTopUpReady(checkout)),
    );
  }

  /// The Lightbox reported success: the server checks with the bank.
  Future<void> confirm(String reference) async {
    emit(const ManagerWalletTopUpLoading());
    final result = await repo.confirmTopUp(reference);
    result.fold(
      (failure) => emit(ManagerWalletTopUpFailure(failure.errMessage)),
      (confirmation) => emit(confirmation.credited
          ? ManagerWalletTopUpSuccess(confirmation.message)
          : ManagerWalletTopUpPending(confirmation.message)),
    );
  }
}
