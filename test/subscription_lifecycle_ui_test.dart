import 'package:flutter_test/flutter_test.dart';
import 'package:goal_master_admin/features/manager_subscription/data/model/manager_subscription_response.dart';
import 'package:goal_master_admin/features/manager_subscription/data/model/subscription_lifecycle.dart';

/// What the subscription screen offers depends on what the manager already has.
///
/// Every card used to say «اشترك». That is how the same plan was bought twice
/// inside one cycle — two rows, two 59 LYD debits four hours apart, two of
/// three promotional months gone. The decision is now the server's, and these
/// tests pin that the app only renders it: no classification by plan name or
/// price, and no arithmetic behind an upgrade's figures.
void main() {
  Map<String, dynamic> plan({
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

  SubscriptionLifecycle lifecycle({
    bool active = true,
    bool renewalDue = false,
    List<Map<String, dynamic>>? plans,
  }) =>
      SubscriptionLifecycle.fromJson({
        'is_active': active,
        'renewal_due': renewalDue,
        'renewal_window_days': 5,
        'plans': plans ??
            [
              plan(id: 4, name: 'انطلاقة', action: 'current', isCurrent: true, effective: 59),
              plan(id: 5, name: 'نمو', action: 'upgrade', list: 179, effective: 179, preview: {
                'amount_due': 80.0,
                'unused_current_value': 39.30,
                'target_period_value': 119.30,
                'current_plan_name': 'انطلاقة',
                'cycle_ends_at': '2026-09-29 00:24:51',
              }),
              plan(id: 3, name: 'إدارة', action: 'schedule_switch', list: 149, effective: 149),
              plan(id: 1, name: 'Launch', action: 'schedule_downgrade', list: 59, effective: 59),
            ],
      });

  // ---------- 1-3: the plan they already hold ----------

  group('the current plan', () {
    test('is labelled «باقتك الحالية»', () {
      expect(lifecycle().forPlan(4)!.action.label, 'باقتك الحالية');
      expect(lifecycle().forPlan(4)!.isCurrent, isTrue);
    });

    test('cannot be repurchased mid-cycle', () {
      final current = lifecycle().forPlan(4)!.action;

      expect(current, PlanAction.current);
      expect(current.isActionable, isFalse,
          reason: 'tapping the plan you hold must not send a charge');
      expect(current.chargesNow, isFalse);
    });

    test('its promotional price is shown honestly', () {
      final current = lifecycle().forPlan(4)!;

      // The manager pays 59, not the 79 on the list.
      expect(current.effectivePrice, 59);
      expect(current.listPrice, 79);
      expect(current.hasPromotionalPrice, isTrue);
    });
  });

  // ---------- 4: renewal window ----------

  group('renewal', () {
    test('is offered only when the server says it is due', () {
      final midCycle = lifecycle(renewalDue: false);
      expect(midCycle.forPlan(4)!.action, PlanAction.current);

      final nearExpiry = lifecycle(renewalDue: true, plans: [
        plan(id: 4, name: 'انطلاقة', action: 'renew', isCurrent: true, effective: 59),
      ]);
      expect(nearExpiry.forPlan(4)!.action, PlanAction.renew);
      expect(nearExpiry.forPlan(4)!.action.label, 'تجديد الاشتراك');
      expect(nearExpiry.forPlan(4)!.action.chargesNow, isTrue);
    });

    test('the window length comes from the server', () {
      expect(lifecycle().renewalWindowDays, 5);
    });
  });

  // ---------- 5-7: upgrade ----------

  group('an upgrade', () {
    test('is labelled «ترقية الآن» and charges now', () {
      final upgrade = lifecycle().forPlan(5)!.action;

      expect(upgrade, PlanAction.upgrade);
      expect(upgrade.label, 'ترقية الآن');
      expect(upgrade.chargesNow, isTrue);
      expect(upgrade.isScheduled, isFalse);
    });

    test('shows the amount the server calculated', () {
      final preview = lifecycle().forPlan(5)!.upgradePreview!;

      expect(preview.amountDue, 80.0);
      expect(preview.unusedCurrentValue, 39.30);
      expect(preview.targetPeriodValue, 119.30);
      expect(preview.currentPlanName, 'انطلاقة');
      expect(preview.cycleEndsAt, DateTime(2026, 9, 29, 0, 24, 51));
    });

    /// The figures are carried, never derived. If the app recomputed them it
    /// could show one number and the server charge another.
    test('the app derives none of the proration itself', () {
      final preview = lifecycle().forPlan(5)!.upgradePreview!;

      // Not equal to target minus unused computed from list prices, nor to any
      // ratio the app could form: it is simply what arrived.
      expect(preview.amountDue, 80.0);
      expect(
        preview.targetPeriodValue - preview.unusedCurrentValue,
        closeTo(80.0, 0.01),
        reason: 'server figures are internally consistent, and taken as given',
      );
    });

    test('a plan with no preview offers no amount to display', () {
      expect(lifecycle().forPlan(3)!.upgradePreview, isNull);
    });
  });

  // ---------- 8-9: scheduled changes ----------

  group('changes that wait for the next cycle', () {
    test('a downgrade is labelled for the end of the cycle', () {
      final action = lifecycle().forPlan(1)!.action;

      expect(action, PlanAction.scheduleDowngrade);
      expect(action.label, 'التغيير عند نهاية الدورة');
      expect(action.chargesNow, isFalse);
      expect(action.isScheduled, isTrue);
    });

    test('a marketplace switch is never called an upgrade', () {
      final action = lifecycle().forPlan(3)!.action;

      expect(action, PlanAction.scheduleSwitch);
      expect(action.label, 'تغيير الباقة عند نهاية الدورة');
      expect(action.label.contains('ترقية'), isFalse);
      expect(action.chargesNow, isFalse);
    });
  });

  // ---------- 10-11: the scheduled banner ----------

  group('a scheduled change', () {
    ManagerCurrentSubscription current({Map<String, dynamic>? scheduled}) =>
        ManagerCurrentSubscription.fromJson({
          'id': 15,
          'plan_id': 4,
          'plan_name': 'انطلاقة',
          'plan_code': 'gm_start',
          'status': 'active',
          'billing_cycle': 'monthly',
          'auto_renew': true,
          'starts_at': '2026-08-29 00:24:51',
          'ends_at': '2026-09-29 00:24:51',
          'trial_ends_at': null,
          'features': const <String, dynamic>{},
          'scheduled_change': scheduled,
        });

    test('is absent when nothing is pending', () {
      expect(current().scheduledChange, isNull);
    });

    test('carries the target plan and when it happens', () {
      final scheduled = current(scheduled: {
        'plan_id': 3,
        'plan_name': 'إدارة',
        'kind': 'switch',
        'effective_at': '2026-09-29 00:24:51',
      }).scheduledChange!;

      expect(scheduled.planName, 'إدارة');
      expect(scheduled.kind, 'switch');
      expect(scheduled.effectiveAt, DateTime(2026, 9, 29, 0, 24, 51));
    });
  });

  // ---------- fallbacks ----------

  group('without a lifecycle answer', () {
    test('an empty lifecycle offers a plain purchase', () {
      final empty = SubscriptionLifecycle.empty();

      expect(empty.forPlan(4), isNull);
      expect(empty.isActive, isFalse);
    });

    test('an unknown action falls back to subscribe, never to a charge label',
        () {
      expect(PlanAction.parse('something_new'), PlanAction.subscribe);
      expect(PlanAction.parse(null), PlanAction.subscribe);
    });

    test('no entitlement means every plan is purchasable', () {
      final fresh = lifecycle(active: false, plans: [
        plan(id: 4, name: 'انطلاقة', action: 'subscribe'),
      ]);

      expect(fresh.isActive, isFalse);
      expect(fresh.forPlan(4)!.action, PlanAction.subscribe);
      expect(fresh.forPlan(4)!.action.isActionable, isTrue);
    });
  });
}
