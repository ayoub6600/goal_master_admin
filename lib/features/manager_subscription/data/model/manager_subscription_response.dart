import 'package:goal_master_admin/features/manager_onboarding/data/model/subscription_plan_option.dart';

class ManagerCurrentSubscription {
  final int id;
  final int planId;
  final String planName;
  final String planCode;
  final String status;
  final String billingCycle;
  final bool autoRenew;
  final String? startsAt;
  final String? endsAt;
  final String? trialEndsAt;
  final SubscriptionPlanFeatures features;

  const ManagerCurrentSubscription({
    required this.id,
    required this.planId,
    required this.planName,
    required this.planCode,
    required this.status,
    required this.billingCycle,
    required this.autoRenew,
    required this.startsAt,
    required this.endsAt,
    required this.trialEndsAt,
    required this.features,
  });

  int? get daysRemaining {
    if (endsAt == null || endsAt!.isEmpty) return null;
    final end = DateTime.tryParse(endsAt!);
    if (end == null) return null;
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    return end.difference(startOfToday).inDays;
  }

  bool get isExpiringSoon {
    final remaining = daysRemaining;
    return remaining != null && remaining <= 7;
  }

  bool get isExpired {
    final remaining = daysRemaining;
    return remaining != null && remaining < 0;
  }

  bool get isTrial => status.toLowerCase().trim() == 'trialing';

  factory ManagerCurrentSubscription.fromJson(Map<String, dynamic> json) {
    return ManagerCurrentSubscription(
      id: _toInt(json['id']),
      planId: _toInt(json['plan_id']),
      planName: json['plan_name']?.toString() ?? '',
      planCode: json['plan_code']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      billingCycle: json['billing_cycle']?.toString() ?? 'monthly',
      autoRenew: json['auto_renew'] == null
          ? true
          : (json['auto_renew'] == true || json['auto_renew'].toString() == '1'),
      startsAt: json['starts_at']?.toString(),
      endsAt: json['ends_at']?.toString(),
      trialEndsAt: json['trial_ends_at']?.toString(),
      features: SubscriptionPlanFeatures.fromJson(
        json['features'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
