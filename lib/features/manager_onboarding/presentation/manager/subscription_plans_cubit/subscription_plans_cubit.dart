import 'package:bloc/bloc.dart';
import 'package:goal_master_admin/features/manager_onboarding/data/model/subscription_plan_option.dart';
import 'package:goal_master_admin/features/manager_onboarding/data/repo/manager_signup_repo.dart';

part 'subscription_plans_state.dart';

class SubscriptionPlansCubit extends Cubit<SubscriptionPlansState> {
  SubscriptionPlansCubit(this._repo) : super(SubscriptionPlansInitial());

  final ManagerSignupRepo _repo;

  Future<void> loadPlans() async {
    emit(SubscriptionPlansLoading());
    final result = await _repo.getPublicPlans();
    result.fold(
      (failure) => emit(SubscriptionPlansError(failure.errMessage)),
      (plans) => emit(SubscriptionPlansLoaded(plans)),
    );
  }
}
