import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goal_master_admin/features/manager_wallet/data/repo/manager_wallet_repo_imp.dart';
import 'package:goal_master_admin/features/manager_wallet/presentation/manager/manager_wallet_cubit/manager_wallet_state.dart';

class ManagerWalletCubit extends Cubit<ManagerWalletState> {
  final ManagerWalletRepoImp repo;

  ManagerWalletCubit(this.repo) : super(const ManagerWalletInitial());

  Future<void> load() async {
    emit(const ManagerWalletLoading());

    final summaryResult = await repo.getWalletSummary();
    final transactionsResult = await repo.getWalletTransactions();

    summaryResult.fold(
      (failure) => emit(ManagerWalletFailure(failure.errMessage)),
      (summary) {
        transactionsResult.fold(
          (failure) => emit(ManagerWalletFailure(failure.errMessage)),
          (transactions) {
            emit(
              ManagerWalletLoaded(
                summary.data.copyWith(
                  transactions: transactions.data.transactions,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
