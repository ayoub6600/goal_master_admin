import 'package:dartz/dartz.dart';
import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:goal_master_admin/features/manager_onboarding/data/model/subscription_plan_option.dart';
import 'package:goal_master_admin/features/manager_subscription/data/model/insufficient_balance_failure.dart';
import 'package:goal_master_admin/features/manager_subscription/data/model/manager_subscription_response.dart';
import 'package:goal_master_admin/features/manager_subscription/data/model/subscription_lifecycle.dart';
import 'package:goal_master_admin/features/manager_subscription/data/repo/manager_subscription_repo.dart';

/// A stand-in for the subscription server, recording what the screen asked for.
///
/// The point of these tests is that the app renders the server's decision
/// rather than making one, so the fake hands back deliberately odd figures and
/// the tests assert those exact figures reach the screen.
class FakeSubscriptionRepo implements ManagerSubscriptionRepo {
  FakeSubscriptionRepo({
    required this.plans,
    required this.current,
    required this.lifecycle,
  });

  List<SubscriptionPlanOption> plans;
  ManagerCurrentSubscription? current;
  SubscriptionLifecycle lifecycle;

  /// What `changeSubscription` should do next.
  Either<Failure, ManagerCurrentSubscription>? changeResult;

  /// Swapped in after a successful change, so a reload returns the new state.
  ManagerCurrentSubscription? currentAfterChange;
  SubscriptionLifecycle? lifecycleAfterChange;

  int changeCalls = 0;
  int cancelCalls = 0;
  int lifecycleCalls = 0;
  Map<String, dynamic>? lastChangeArgs;

  bool _changed = false;

  @override
  Future<Either<Failure, List<SubscriptionPlanOption>>> getPlans() async =>
      Right(plans);

  @override
  Future<Either<Failure, ManagerCurrentSubscription?>>
      getCurrentSubscription() async =>
          Right(_changed ? (currentAfterChange ?? current) : current);

  @override
  Future<Either<Failure, SubscriptionLifecycle>> loadLifecycle() async {
    lifecycleCalls++;
    return Right(_changed ? (lifecycleAfterChange ?? lifecycle) : lifecycle);
  }

  @override
  Future<Either<Failure, ManagerCurrentSubscription>> changeSubscription({
    required int subscriptionPlanId,
    required String billingCycle,
  }) async {
    changeCalls++;
    lastChangeArgs = {
      'subscription_plan_id': subscriptionPlanId,
      'billing_cycle': billingCycle,
    };

    final result = changeResult ??
        Right<Failure, ManagerCurrentSubscription>(
          currentAfterChange ?? current!,
        );

    if (result.isRight()) _changed = true;

    return result;
  }

  @override
  Future<Either<Failure, ManagerCurrentSubscription?>>
      cancelScheduledChange() async {
    cancelCalls++;
    _changed = true;
    return Right(currentAfterChange ?? current);
  }

  @override
  Future<Either<Failure, ManagerCurrentSubscription>> updateAutoRenew({
    required bool enabled,
  }) async =>
      Right(current!);

  // ---------------- fixtures ----------------

  static SubscriptionPlanOption planOption({
    required int id,
    required String name,
    required String code,
    double monthly = 79,
    bool marketplace = true,
    double prepaidCommission = 10,
    double poaCommission = 5,
  }) {
    return SubscriptionPlanOption.fromJson({
      'id': id,
      'name': name,
      'code': code,
      'short_description': '',
      'description': '',
      'badge_label': '',
      'currency_code': 'LYD',
      'monthly_price': monthly,
      'yearly_price': monthly * 10,
      'trial_days': 0,
      'is_featured': false,
      'features': {
        'max_branches': 2,
        'max_fields': 6,
        'max_staff': 8,
        'allow_reports': 1,
        'allow_wallet': marketplace ? 1 : 0,
        'allow_local_payment': marketplace ? 1 : 0,
        'allow_customer_marketplace': marketplace ? 1 : 0,
        'goal_master_prepaid_commission_percent': prepaidCommission,
        'goal_master_poa_commission_percent': poaCommission,
      },
    });
  }

  static ManagerCurrentSubscription currentSubscription({
    int planId = 4,
    String planName = 'انطلاقة',
    String endsAt = '2026-09-29 00:24:51',
    Map<String, dynamic>? scheduledChange,
  }) {
    return ManagerCurrentSubscription.fromJson({
      'id': 15,
      'plan_id': planId,
      'plan_name': planName,
      'plan_code': 'gm_start',
      'status': 'active',
      'billing_cycle': 'monthly',
      'auto_renew': true,
      'starts_at': '2026-08-29 00:24:51',
      'ends_at': endsAt,
      'trial_ends_at': null,
      'features': const <String, dynamic>{},
      'scheduled_change': scheduledChange,
    });
  }

  static SubscriptionLifecycle lifecycleWith(
    List<Map<String, dynamic>> plans, {
    bool active = true,
    bool renewalDue = false,
  }) {
    return SubscriptionLifecycle.fromJson({
      'is_active': active,
      'renewal_due': renewalDue,
      'renewal_window_days': 5,
      'plans': plans,
    });
  }

  static Map<String, dynamic> planState({
    required int id,
    required String name,
    required String action,
    double list = 79,
    double effective = 79,
    bool isCurrent = false,
    Map<String, dynamic>? preview,
  }) =>
      {
        'plan_id': id,
        'plan_name': name,
        'action': action,
        'list_price': list,
        'effective_price': effective,
        'is_current': isCurrent,
        'upgrade_preview': preview,
      };

  static Failure insufficientBalance() => InsufficientBalanceFailure(
        errMessage: 'رصيد المحفظة غير كافٍ لإتمام العملية.',
        currentBalance: 10,
        requiredAmount: 66.48,
      );
}
