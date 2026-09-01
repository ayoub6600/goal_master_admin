/// What each plan means for THIS manager, right now.
///
/// The subscription screen used to offer «اشترك» on every card regardless of
/// what the manager already held. That is how the same plan was bought twice
/// inside one cycle — two rows, two 59 LYD debits four hours apart, and two of
/// three promotional months spent on a single billing period.
///
/// The decision is the server's. Nothing here classifies a plan by its name,
/// its price or its position in the list, and no figure on this screen is
/// worked out on the device: an upgrade's numbers arrive already calculated by
/// the same authority that will charge for it.
class SubscriptionLifecycle {
  const SubscriptionLifecycle({
    required this.isActive,
    required this.renewalDue,
    required this.renewalWindowDays,
    required this.plans,
  });

  /// Whether the manager holds entitlement at this moment.
  final bool isActive;

  /// Whether a same-plan renewal is legitimately due. Server-decided — the
  /// app never works out how close to expiry counts as "close".
  final bool renewalDue;

  final int renewalWindowDays;

  /// Keyed by plan id.
  final Map<int, PlanLifecycle> plans;

  PlanLifecycle? forPlan(int planId) => plans[planId];

  static SubscriptionLifecycle empty() => const SubscriptionLifecycle(
        isActive: false,
        renewalDue: true,
        renewalWindowDays: 0,
        plans: {},
      );

  factory SubscriptionLifecycle.fromJson(Map<String, dynamic> json) {
    final entries = ((json['plans'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => PlanLifecycle.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return SubscriptionLifecycle(
      isActive: json['is_active'] == true,
      renewalDue: json['renewal_due'] != false,
      renewalWindowDays: _int(json['renewal_window_days']),
      plans: {for (final e in entries) e.planId: e},
    );
  }
}

/// What the button on one plan card should do.
enum PlanAction {
  /// No entitlement: an ordinary purchase.
  subscribe,

  /// The plan the manager is on, mid-cycle. Not purchasable.
  current,

  /// The plan they are on, close enough to expiry that renewing is real.
  renew,

  /// Dearer plan in the same family: immediate and prorated.
  upgrade,

  /// Cheaper plan in the same family: takes effect next cycle.
  scheduleDowngrade,

  /// Flips marketplace access. Neither higher nor lower, so it waits for the
  /// next cycle and is never called an upgrade to the manager.
  scheduleSwitch;

  static PlanAction parse(String? raw) => switch (raw) {
        'current' => PlanAction.current,
        'renew' => PlanAction.renew,
        'upgrade' => PlanAction.upgrade,
        'schedule_downgrade' => PlanAction.scheduleDowngrade,
        'schedule_switch' => PlanAction.scheduleSwitch,
        _ => PlanAction.subscribe,
      };

  /// The words on the card.
  String get label => switch (this) {
        PlanAction.current => 'باقتك الحالية',
        PlanAction.renew => 'تجديد الاشتراك',
        PlanAction.upgrade => 'ترقية الآن',
        PlanAction.scheduleDowngrade => 'التغيير عند نهاية الدورة',
        PlanAction.scheduleSwitch => 'تغيير الباقة عند نهاية الدورة',
        PlanAction.subscribe => 'اشترك',
      };

  /// Whether tapping does anything. The plan they already hold does not.
  bool get isActionable => this != PlanAction.current;

  /// Whether confirming this takes money now.
  bool get chargesNow => this == PlanAction.renew ||
      this == PlanAction.upgrade ||
      this == PlanAction.subscribe;

  /// Whether this takes effect when the paid period runs out.
  bool get isScheduled =>
      this == PlanAction.scheduleDowngrade || this == PlanAction.scheduleSwitch;
}

class PlanLifecycle {
  const PlanLifecycle({
    required this.planId,
    required this.planName,
    required this.action,
    this.listPrice = 0,
    this.effectivePrice = 0,
    this.isCurrent = false,
    this.upgradePreview,
  });

  final int planId;
  final String planName;
  final PlanAction action;

  /// The plan's ordinary price and what this manager would actually pay —
  /// different while a promotion applies to them.
  final double listPrice;
  final double effectivePrice;

  bool get hasPromotionalPrice =>
      effectivePrice > 0 && effectivePrice < listPrice;

  final bool isCurrent;

  /// Present only for an upgrade. Every figure is the server's.
  final UpgradePreview? upgradePreview;

  factory PlanLifecycle.fromJson(Map<String, dynamic> json) {
    final preview = json['upgrade_preview'];

    return PlanLifecycle(
      planId: _int(json['plan_id']),
      planName: (json['plan_name'] ?? '').toString(),
      action: PlanAction.parse(json['action']?.toString()),
      listPrice: _double(json['list_price']),
      effectivePrice: _double(json['effective_price']),
      isCurrent: json['is_current'] == true,
      upgradePreview: preview is Map
          ? UpgradePreview.fromJson(Map<String, dynamic>.from(preview))
          : null,
    );
  }
}

/// The figures behind «ترقية الآن», calculated server-side.
///
/// Deliberately a dumb carrier: the app must not reproduce the remaining-time
/// arithmetic, because two implementations of one price is how a manager gets
/// shown one number and charged another.
class UpgradePreview {
  const UpgradePreview({
    required this.amountDue,
    required this.unusedCurrentValue,
    required this.targetPeriodValue,
    required this.currentPlanName,
    this.cycleEndsAt,
  });

  /// What is charged now.
  final double amountDue;

  /// What the rest of the current plan's period is worth — measured from what
  /// the manager actually pays for it, not the list price.
  final double unusedCurrentValue;

  /// What the new plan costs for that same remaining period.
  final double targetPeriodValue;

  final String currentPlanName;

  /// Unchanged by the upgrade: no new cycle begins.
  final DateTime? cycleEndsAt;

  factory UpgradePreview.fromJson(Map<String, dynamic> json) {
    return UpgradePreview(
      amountDue: _double(json['amount_due']),
      unusedCurrentValue: _double(json['unused_current_value']),
      targetPeriodValue: _double(json['target_period_value']),
      currentPlanName: (json['current_plan_name'] ?? '').toString(),
      cycleEndsAt: json['cycle_ends_at'] == null
          ? null
          : DateTime.tryParse(json['cycle_ends_at'].toString()),
    );
  }
}

int _int(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

double _double(dynamic v) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0;
}
