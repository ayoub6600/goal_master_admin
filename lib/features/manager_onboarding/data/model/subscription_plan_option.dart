class SubscriptionPlanOption {
  final int id;
  final String name;
  final String code;
  final String shortDescription;
  final String description;
  final String badgeLabel;
  final String currencyCode;
  final double monthlyPrice;
  final double yearlyPrice;
  final int trialDays;
  final bool isFeatured;
  final SubscriptionPlanFeatures features;

  const SubscriptionPlanOption({
    required this.id,
    required this.name,
    required this.code,
    required this.shortDescription,
    required this.description,
    required this.badgeLabel,
    required this.currencyCode,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.trialDays,
    required this.isFeatured,
    required this.features,
  });

  factory SubscriptionPlanOption.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanOption(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      shortDescription: json['short_description']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      badgeLabel: json['badge_label']?.toString() ?? '',
      currencyCode: json['currency_code']?.toString() ?? 'LYD',
      monthlyPrice: _toDouble(json['monthly_price']),
      yearlyPrice: _toDouble(json['yearly_price']),
      trialDays: _toInt(json['trial_days']),
      isFeatured: _toBool(json['is_featured']),
      features: SubscriptionPlanFeatures.fromJson(
        json['features'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  String get monthlyPriceLabel =>
      '${monthlyPrice.toStringAsFixed(0)} $currencyCode';
  String get yearlyPriceLabel =>
      '${yearlyPrice.toStringAsFixed(0)} $currencyCode';
}

class SubscriptionPlanFeatures {
  final int maxBranches;
  final int maxFields;
  final int maxStaff;
  final bool allowMonthlyBookings;
  final bool allowReports;
  final bool allowWallet;
  final bool allowOnlinePayments;
  final bool allowLocalPayment;
  final bool allowWebAccess;

  const SubscriptionPlanFeatures({
    required this.maxBranches,
    required this.maxFields,
    required this.maxStaff,
    required this.allowMonthlyBookings,
    required this.allowReports,
    required this.allowWallet,
    required this.allowOnlinePayments,
    required this.allowLocalPayment,
    required this.allowWebAccess,
  });

  factory SubscriptionPlanFeatures.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanFeatures(
      maxBranches: _toInt(json['max_branches']),
      maxFields: _toInt(json['max_fields']),
      maxStaff: _toInt(json['max_staff']),
      allowMonthlyBookings: _toBool(json['allow_monthly_bookings']),
      allowReports: _toBool(json['allow_reports']),
      allowWallet: _toBool(json['allow_wallet']),
      allowOnlinePayments: _toBool(json['allow_online_payments']),
      allowLocalPayment: _toBool(json['allow_local_payment']),
      allowWebAccess: _toBool(json['allow_web_access']),
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value == 1;
  return value?.toString() == '1' || value?.toString().toLowerCase() == 'true';
}
