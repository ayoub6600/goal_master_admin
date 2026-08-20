import 'package:bloc/bloc.dart';
import 'package:goal_master_admin/features/manager_onboarding/data/model/subscription_plan_option.dart';
import 'package:goal_master_admin/features/manager_subscription/data/model/insufficient_balance_failure.dart';
import 'package:goal_master_admin/features/manager_subscription/data/model/manager_subscription_response.dart';
import 'package:goal_master_admin/features/manager_subscription/data/repo/manager_subscription_repo.dart';

part 'manager_subscription_state.dart';

class ManagerSubscriptionCubit extends Cubit<ManagerSubscriptionState> {
  ManagerSubscriptionCubit(this._repo) : super(ManagerSubscriptionInitial());

  final ManagerSubscriptionRepo _repo;

  Future<void> load() async {
    emit(ManagerSubscriptionLoading());

    final plansResult = await _repo.getPlans();
    final currentResult = await _repo.getCurrentSubscription();

    plansResult.fold(
      (failure) => emit(ManagerSubscriptionFailure(failure.errMessage)),
      (plans) {
        currentResult.fold(
          (failure) => emit(
            ManagerSubscriptionFailure(failure.errMessage, plans: plans),
          ),
          (current) => emit(
            ManagerSubscriptionLoaded(current: current, plans: plans),
          ),
        );
      },
    );
  }

  List<SubscriptionPlanOption> _plansOf(ManagerSubscriptionState state) {
    return switch (state) {
      final ManagerSubscriptionLoaded s => s.plans,
      final ManagerSubscriptionChanging s => s.plans,
      final ManagerSubscriptionChangeSuccess s => s.plans,
      final ManagerSubscriptionFailure s => s.plans,
      final ManagerSubscriptionInsufficientBalance s => s.plans,
      _ => const <SubscriptionPlanOption>[],
    };
  }

  ManagerCurrentSubscription? _currentOf(ManagerSubscriptionState state) {
    return switch (state) {
      final ManagerSubscriptionLoaded s => s.current,
      final ManagerSubscriptionChanging s => s.current,
      final ManagerSubscriptionChangeSuccess s => s.current,
      final ManagerSubscriptionFailure s => s.current,
      final ManagerSubscriptionInsufficientBalance s => s.current,
      _ => null,
    };
  }

  Future<void> changePlan({
    required int subscriptionPlanId,
    required String billingCycle,
  }) async {
    final plans = _plansOf(state);
    final current = _currentOf(state);

    emit(ManagerSubscriptionChanging(current: current, plans: plans));

    final result = await _repo.changeSubscription(
      subscriptionPlanId: subscriptionPlanId,
      billingCycle: billingCycle,
    );

    result.fold(
      (failure) {
        if (failure is InsufficientBalanceFailure) {
          emit(
            ManagerSubscriptionInsufficientBalance(
              message: failure.errMessage,
              currentBalance: failure.currentBalance,
              requiredAmount: failure.requiredAmount,
              current: current,
              plans: plans,
            ),
          );
          return;
        }
        emit(
          ManagerSubscriptionFailure(
            failure.errMessage,
            current: current,
            plans: plans,
          ),
        );
      },
      (updated) => emit(
        ManagerSubscriptionChangeSuccess(current: updated, plans: plans),
      ),
    );
  }

  Future<void> toggleAutoRenew(bool enabled) async {
    final plans = _plansOf(state);
    final current = _currentOf(state);

    final result = await _repo.updateAutoRenew(enabled: enabled);

    result.fold(
      (failure) => emit(
        ManagerSubscriptionFailure(
          failure.errMessage,
          current: current,
          plans: plans,
        ),
      ),
      (updated) => emit(
        ManagerSubscriptionLoaded(current: updated, plans: plans),
      ),
    );
  }
}
