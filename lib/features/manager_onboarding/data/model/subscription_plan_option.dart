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

  /// What THIS manager pays, resolved by the server.
  ///
  /// Never worked out on the device: eligibility depends on subscription
  /// history the app cannot see, and a struck-through price shown to somebody
  /// who does not qualify is a lie the app tells on our behalf.
  final PlanPricing? monthlyPricing;
  final PlanPricing? yearlyPricing;

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
    this.monthlyPricing,
    this.yearlyPricing,
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
      monthlyPricing: PlanPricing.maybeFrom(json['pricing']?['monthly']),
      yearlyPricing: PlanPricing.maybeFrom(json['pricing']?['yearly']),
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

  /// Whether the venue appears to customers in the Goal Master app at all.
  /// A management-only plan is a different business model, not a cheaper one.
  final bool allowCustomerMarketplace;

  /// The two rates a manager is really choosing between. Kept separate
  /// because they answer different questions: what Goal Master charges on
  /// money it collects, and on money the customer hands over at the pitch.
  final double prepaidCommissionPercent;
  final double poaCommissionPercent;

  const SubscriptionPlanFeatures({
    required this.allowCustomerMarketplace,
    required this.prepaidCommissionPercent,
    required this.poaCommissionPercent,
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
      allowCustomerMarketplace: _toBool(json['allow_customer_marketplace']),
      prepaidCommissionPercent: _toDouble(json['goal_master_prepaid_commission_percent']),
      poaCommissionPercent: _toDouble(json['goal_master_poa_commission_percent']),
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


/// The server's answer to "what does this manager pay for this plan".
///
/// Rendered, never recomputed. The app's job is to show the offer honestly:
/// the real price struck through, what is actually charged, and — when the
/// discount only lasts a few cycles — for how long and what happens next.
class PlanPricing {
  final double normalPrice;
  final double effectivePrice;
  final double discountAmount;
  final double discountPercent;
  final bool hasPromotion;
  final String? promotionLabel;
  final String? promotionBadge;
  final int? introductoryCyclesTotal;
  final int? introductoryCyclesRemaining;
  final double priceAfterPromotion;

  /// Whether [priceAfterPromotion] is a promise or merely today's list price.
  ///
  /// False means the campaign guaranteed nothing about the future price, and
  /// the number must never be drawn — "ثم 99" would be a commitment nobody
  /// made, and the manager would rightly hold us to it.
  final bool priceAfterPromotionGuaranteed;

  /// The offer's terms, already written, in Arabic.
  ///
  /// Composed by the server rather than assembled here on purpose: the
  /// sentence IS the promise, and a client that builds it from parts will
  /// eventually print a guaranteed figure for a campaign that guaranteed
  /// nothing — on every device at once, with no way to correct it but a
  /// release.
  final String? priceNoteAr;

  const PlanPricing({
    required this.normalPrice,
    required this.effectivePrice,
    required this.discountAmount,
    required this.discountPercent,
    required this.hasPromotion,
    required this.priceAfterPromotion,
    this.priceAfterPromotionGuaranteed = false,
    this.priceNoteAr,
    this.promotionLabel,
    this.promotionBadge,
    this.introductoryCyclesTotal,
    this.introductoryCyclesRemaining,
  });

  static PlanPricing? maybeFrom(dynamic json) {
    if (json is! Map) return null;

    return PlanPricing(
      normalPrice: _toDouble(json['normal_price']),
      effectivePrice: _toDouble(json['effective_price']),
      discountAmount: _toDouble(json['discount_amount']),
      discountPercent: _toDouble(json['discount_percent']),
      hasPromotion: _toBool(json['has_promotion']),
      priceAfterPromotion: _toDouble(json['price_after_promotion']),
      // Absent on an older server: read as NOT guaranteed. The safe default
      // is the one that declines to print a number we cannot stand behind.
      priceAfterPromotionGuaranteed:
          _toBool(json['price_after_promotion_guaranteed']),
      priceNoteAr: json['price_note_ar']?.toString(),
      promotionLabel: json['promotion_label']?.toString(),
      promotionBadge: json['promotion_badge']?.toString(),
      introductoryCyclesTotal: json['introductory_cycles_total'] == null
          ? null
          : _toInt(json['introductory_cycles_total']),
      introductoryCyclesRemaining: json['introductory_cycles_remaining'] == null
          ? null
          : _toInt(json['introductory_cycles_remaining']),
    );
  }

  /// Only true when there is a genuine, currently-available discount to draw.
  ///
  /// The server's own numbers decide. That covers the case where a manager
  /// pays less than the list price with no campaign running at all — a frozen
  /// price kept from an offer they already finished. Requiring [hasPromotion]
  /// here would show them today's higher list price as if it were theirs.
  bool get showsOffer => effectivePrice < normalPrice;

  /// True when the price goes back up later — the manager must be told.
  bool get isIntroductory =>
      showsOffer && hasPromotion && (introductoryCyclesTotal ?? 0) > 0;

  /// The line explaining what happens after the offer.
  ///
  /// Prefers the server's wording. The local fallback exists only for an older
  /// backend, and it too refuses to name a figure unless the guarantee flag
  /// says one was given.
  String? introductoryNote(String currency, String billingCycle) {
    if ((priceNoteAr ?? '').isNotEmpty) return priceNoteAr;
    if (!isIntroductory) return null;

    String money(double v) =>
        v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

    final unit = billingCycle == 'yearly' ? 'سنوات' : 'أشهر';
    final cycleWord = billingCycle == 'yearly' ? 'سنويًا' : 'شهريًا';
    final head =
        '${money(effectivePrice)} $currency لأول $introductoryCyclesTotal $unit';

    return priceAfterPromotionGuaranteed
        ? '$head، ثم ${money(priceAfterPromotion)} $currency $cycleWord'
        : '$head، ثم يعود الاشتراك إلى السعر الأساسي للباقة.';
  }
}
