import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goal_master_admin/features/manager_cancellation_policy/data/repo/manager_cancellation_policy_repo_imp.dart';
import 'package:goal_master_admin/features/manager_cancellation_policy/presentation/manager/manager_cancellation_policy_cubit/manager_cancellation_policy_state.dart';

class ManagerCancellationPolicyCubit
    extends Cubit<ManagerCancellationPolicyState> {
  final ManagerCancellationPolicyRepoImp repo;

  ManagerCancellationPolicyCubit(this.repo)
      : super(const ManagerCancellationPolicyInitial());

  Future<void> load() async {
    emit(const ManagerCancellationPolicyLoading());

    final result = await repo.getPolicy();

    result.fold(
      (failure) => emit(ManagerCancellationPolicyFailure(failure.errMessage)),
      (data) => emit(ManagerCancellationPolicyLoaded(data)),
    );
  }
}
