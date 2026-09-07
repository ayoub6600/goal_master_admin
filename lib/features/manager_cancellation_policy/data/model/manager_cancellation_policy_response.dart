class ManagerCancellationPolicyResponse {
  final bool success;
  final ManagerCancellationPolicyData? data;
  final String? message;

  const ManagerCancellationPolicyResponse({
    required this.success,
    this.data,
    this.message,
  });

  factory ManagerCancellationPolicyResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return ManagerCancellationPolicyResponse(
      success: _toBool(json['status']),
      data: json['data'] == null
          ? null
          : ManagerCancellationPolicyData.fromJson(
              json['data'] as Map<String, dynamic>,
            ),
      message: json['message']?.toString(),
    );
  }
}

class ManagerCancellationPolicyData {
  final bool isCustom;

  /// The hour cutoff for each fixed refund bracket, keyed by percent
  /// (100, 75, 50, 0) — the same four brackets the platform default uses.
  final Map<int, double> tierHours;
  final CancellationPolicyBounds bounds;

  const ManagerCancellationPolicyData({
    required this.isCustom,
    required this.tierHours,
    required this.bounds,
  });

  double hoursFor(int percent) => tierHours[percent] ?? 0;

  factory ManagerCancellationPolicyData.fromJson(Map<String, dynamic> json) {
    final tiers = (json['tiers'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();

    return ManagerCancellationPolicyData(
      isCustom: _toBool(json['is_custom']),
      tierHours: {
        for (final tier in tiers)
          (tier['refund_percent'] as num).toInt(): _toDouble(tier['from_hours']),
      },
      bounds: CancellationPolicyBounds.fromJson(
        json['bounds'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class CancellationPolicyBounds {
  final bool policyEnabled;
  final bool allowOverride;
  final double minFreeCancellationHours;
  final double maxFreeCancellationHours;

  const CancellationPolicyBounds({
    required this.policyEnabled,
    required this.allowOverride,
    required this.minFreeCancellationHours,
    required this.maxFreeCancellationHours,
  });

  factory CancellationPolicyBounds.fromJson(Map<String, dynamic> json) {
    return CancellationPolicyBounds(
      policyEnabled: _toBool(json['policy_enabled']),
      allowOverride: _toBool(json['allow_override']),
      minFreeCancellationHours: _toDouble(json['min_free_cancellation_hours']),
      maxFreeCancellationHours: _toDouble(json['max_free_cancellation_hours']),
    );
  }
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value == 1;
  final normalized = value?.toString().toLowerCase() ?? '';
  return normalized == 'true' || normalized == '1';
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
