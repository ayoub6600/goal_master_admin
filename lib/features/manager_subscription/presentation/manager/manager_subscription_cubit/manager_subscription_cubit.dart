import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:goal_master_admin/features/manager_onboarding/data/model/subscription_plan_option.dart';
import 'package:goal_master_admin/features/manager_subscription/data/model/insufficient_balance_failure.dart';
import 'package:goal_master_admin/features/manager_subscription/data/model/manager_subscription_response.dart';
import 'package:goal_master_admin/features/manager_subscription/data/model/subscription_lifecycle.dart';
import 'package:goal_master_admin/features/manager_subscription/data/repo/manager_subscription_repo.dart';

part 'manager_subscription_state.dart';

class ManagerSubscriptionCubit extends Cubit<ManagerSubscriptionState> {
  ManagerSubscriptionCubit(this._repo) : super(ManagerSubscriptionInitial());

  final ManagerSubscriptionRepo _repo;

  /// What each plan means for this manager, decided by the server.
  ///
  /// Held beside the plan list rather than merged into it: the plans are a
  /// shared read-only model the onboarding carousel also uses, and the
  /// lifecycle is meaningful only for a manager who already has an account.
  SubscriptionLifecycle _lifecycle = SubscriptionLifecycle.empty();

  SubscriptionLifecycle get lifecycle => _lifecycle;

  /// The action for one plan card. Falls back to a plain purchase when the
  /// server said nothing about it — never guessed from name or price.
  PlanAction actionFor(int planId) =>
      _lifecycle.forPlan(planId)?.action ?? PlanAction.subscribe;

  PlanLifecycle? lifecycleFor(int planId) => _lifecycle.forPlan(planId);

  /// Guards a financial tap against a second one while the first is in flight.
  /// The real protection is the server's idempotency; this only stops the app
  /// opening two sheets and sending two requests.
  bool _submitting = false;

  bool get isSubmitting => _submitting;

  Future<void> load() async {
    emit(ManagerSubscriptionLoading());

    final plansResult = await _repo.getPlans();
    final currentResult = await _repo.getCurrentSubscription();

    // Best effort: an older backend without this endpoint leaves every card
    // on its previous behaviour rather than blanking the screen.
    final lifecycleResult = await _repo.loadLifecycle();
    lifecycleResult.fold(
      (_) => _lifecycle = SubscriptionLifecycle.empty(),
      (value) => _lifecycle = value,
    );

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
    // A second tap while the first is still in flight would open a second
    // sheet and send a second request. The server refuses to charge twice
    // either way; this stops the app looking like it might.
    if (_submitting) return;
    _submitting = true;

    // Captured before the request: a downgrade or a plan switch is SUPPOSED to
    // leave the current plan alone, so only an immediate change is checked
    // against it afterwards.
    final wasImmediate = actionFor(subscriptionPlanId).chargesNow;

    final plans = _plansOf(state);
    final current = _currentOf(state);

    emit(ManagerSubscriptionChanging(current: current, plans: plans));

    final result = await _repo.changeSubscription(
      subscriptionPlanId: subscriptionPlanId,
      billingCycle: billingCycle,
    );

    _submitting = false;

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
      (updated) async {
        // A 200 is not a result.
        //
        // The server answers `already_processed` for a request whose business
        // event has been recorded before — which is right for a genuine retry
        // and was catastrophic here: an upgrade whose event had been reversed
        // came back looking successful while the plan never moved, and the app
        // said «تم تحديث اشتراكك بنجاح». So for a change that is supposed to
        // take effect NOW, the claim is checked against the server's own state
        // before anything is celebrated.
        await load();

        final confirmed = _lifecycle.forPlan(subscriptionPlanId);
        final tookEffect = confirmed?.isCurrent ?? false;

        if (kDebugMode) {
          debugPrint(
            'subscription change → target=$subscriptionPlanId '
            'wasImmediate=$wasImmediate '
            'currentAfterReload=${_currentOf(state)?.planId} '
            'confirmed=$tookEffect',
          );
        }

        if (wasImmediate && !tookEffect) {
          emit(ManagerSubscriptionFailure(
            'تعذر تأكيد ترقية الباقة. لم تتغير باقتك الحالية.',
            current: _currentOf(state),
            plans: _plansOf(state),
          ));
          return;
        }

        emit(ManagerSubscriptionChangeSuccess(
          current: _currentOf(state) ?? updated,
          plans: _plansOf(state),
        ));
      },
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

  /// Drop a change scheduled for the next cycle.
  ///
  /// Reloads from the server afterwards rather than patching fields locally:
  /// the subscription's state is the server's answer, not a guess assembled
  /// from what the request was trying to do.
  Future<void> cancelScheduledChange() async {
    if (_submitting) return;
    _submitting = true;

    final current = _currentOf(state);
    final plans = _plansOf(state);

    emit(ManagerSubscriptionChanging(current: current, plans: plans));

    final result = await _repo.cancelScheduledChange();

    _submitting = false;

    await result.fold(
      (failure) async => emit(ManagerSubscriptionFailure(
        failure.errMessage,
        current: current,
        plans: plans,
      )),
      (_) async => load(),
    );
  }
}
