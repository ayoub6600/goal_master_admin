import 'package:flutter_test/flutter_test.dart';
import 'package:goal_master_admin/features/manager_onboarding/data/model/subscription_plan_option.dart';

/// What the plan card is allowed to tell a manager about price.
///
/// The rule that matters: a struck-through price may only appear when the
/// SERVER says this manager can actually have the offer. Eligibility depends on
/// subscription history the app cannot see, so anything the app decides for
/// itself here would be an invented discount.
void main() {
  Map<String, dynamic> pricing({
    double normal = 99,
    double effective = 59,
    bool hasPromotion = true,
    int? cycles = 3,
    double? after,
  }) {
    return {
      'normal_price': normal,
      'effective_price': effective,
      'discount_amount': normal - effective,
      'discount_percent': normal == 0 ? 0 : ((normal - effective) / normal) * 100,
      'has_promotion': hasPromotion,
      'price_after_promotion': after ?? normal,
      'promotion_label': 'عرض الانطلاقة',
      'promotion_badge': 'عرض خاص للمدير الجديد',
      'introductory_cycles_total': cycles,
      'introductory_cycles_remaining': cycles,
    };
  }

  group('PlanPricing', () {
    test('reads the server answer as given', () {
      final p = PlanPricing.maybeFrom(pricing())!;

      expect(p.normalPrice, 99);
      expect(p.effectivePrice, 59);
      expect(p.discountAmount, 40);
      expect(p.discountPercent, closeTo(40.40, 0.01));
    });

    test('shows an offer only when there is a real discount', () {
      expect(PlanPricing.maybeFrom(pricing())!.showsOffer, isTrue);
    });

    test('shows nothing when this manager has no promotion', () {
      // The existing-manager case: same plan, no offer for them.
      final p = PlanPricing.maybeFrom(
        pricing(effective: 99, hasPromotion: false, cycles: null),
      )!;

      expect(p.showsOffer, isFalse);
      expect(p.isIntroductory, isFalse);
    });

    test('never draws a discount that is not one', () {
      // Flagged as promotional but priced the same — nothing to strike out.
      final p = PlanPricing.maybeFrom(pricing(effective: 99))!;

      expect(p.showsOffer, isFalse);
    });

    test('knows when the price goes back up', () {
      final p = PlanPricing.maybeFrom(pricing(cycles: 3))!;

      expect(p.isIntroductory, isTrue);
      expect(p.priceAfterPromotion, 99);
      expect(p.introductoryCyclesTotal, 3);
    });

    test('an open-ended offer is not introductory', () {
      // A standing discount with no cycle limit must not claim "for 3 months".
      final p = PlanPricing.maybeFrom(pricing(cycles: null))!;

      expect(p.showsOffer, isTrue);
      expect(p.isIntroductory, isFalse);
    });

    test('missing pricing is absent rather than guessed', () {
      expect(PlanPricing.maybeFrom(null), isNull);
      expect(PlanPricing.maybeFrom('not a map'), isNull);
    });
  });

  group('SubscriptionPlanOption', () {
    test('carries the per-manager pricing and the commercial terms', () {
      final plan = SubscriptionPlanOption.fromJson({
        'id': 1,
        'name': 'انطلاقة',
        'code': 'gm_start',
        'short_description': 'ابدأ بتكلفة شهرية أقل',
        'description': '',
        'badge_label': 'الأقل اشتراكًا',
        'currency_code': 'LYD',
        'monthly_price': 99,
        'yearly_price': 990,
        'trial_days': 30,
        'is_featured': 0,
        'pricing': {'monthly': pricing(), 'yearly': null},
        'features': {
          'max_branches': 1,
          'max_fields': 3,
          'max_staff': 4,
          'allow_local_payment': 1,
          'allow_customer_marketplace': 1,
          'goal_master_prepaid_commission_percent': 10,
          'goal_master_poa_commission_percent': 5,
        },
      });

      expect(plan.monthlyPricing!.effectivePrice, 59);
      // No yearly campaign: monthly and yearly are independent.
      expect(plan.yearlyPricing, isNull);

      expect(plan.features.prepaidCommissionPercent, 10);
      expect(plan.features.poaCommissionPercent, 5);
      expect(plan.features.allowCustomerMarketplace, isTrue);
    });

    test('a management-only plan reports no marketplace', () {
      final plan = SubscriptionPlanOption.fromJson({
        'id': 2,
        'name': 'إدارة',
        'code': 'gm_management',
        'short_description': '',
        'description': '',
        'badge_label': '',
        'currency_code': 'LYD',
        'monthly_price': 149,
        'yearly_price': 1490,
        'trial_days': 30,
        'is_featured': 0,
        'features': {
          'max_branches': 2,
          'allow_customer_marketplace': 0,
          'allow_local_payment': 0,
          'goal_master_prepaid_commission_percent': 0,
          'goal_master_poa_commission_percent': 0,
        },
      });

      expect(plan.features.allowCustomerMarketplace, isFalse);
      expect(plan.monthlyPricing, isNull);
    });
  });

  /// The two post-promotion modes, as the manager reads them.
  ///
  /// The distinction is the whole point: one campaign promises a specific
  /// future price and the other promises nothing. A card that prints "ثم 99"
  /// for the second is not a formatting slip — it is a commitment the business
  /// never made, shown to every manager at once.
  group('post-promotion wording', () {
    PlanPricing parse(Map<String, dynamic> json) => PlanPricing.maybeFrom(json)!;

    Map<String, dynamic> base(Map<String, dynamic> extra) => {
          'normal_price': 99,
          'effective_price': 59,
          'discount_amount': 40,
          'discount_percent': 40.4,
          'has_promotion': true,
          'introductory_cycles_total': 3,
          'introductory_cycles_remaining': 3,
          ...extra,
        };

    test('renders the server sentence verbatim', () {
      final pricing = parse(base({
        'price_after_promotion': 99,
        'price_after_promotion_guaranteed': true,
        'price_note_ar': '59 LYD لأول 3 أشهر، ثم 99 LYD شهريًا',
      }));

      expect(pricing.introductoryNote('LYD', 'monthly'),
          '59 LYD لأول 3 أشهر، ثم 99 LYD شهريًا');
    });

    test('a guaranteed price may be named in the fallback', () {
      final pricing = parse(base({
        'price_after_promotion': 99,
        'price_after_promotion_guaranteed': true,
      }));

      expect(pricing.introductoryNote('LYD', 'monthly'), contains('ثم 99'));
    });

    test('an unguaranteed price is never named', () {
      // The server sent a number — it is the current list price, useful for
      // arithmetic — but said it is not promised. The card must not print it.
      final pricing = parse(base({
        'price_after_promotion': 99,
        'price_after_promotion_guaranteed': false,
      }));

      final note = pricing.introductoryNote('LYD', 'monthly')!;

      expect(note, contains('يعود الاشتراك إلى السعر الأساسي'));
      expect(note, isNot(contains('ثم 99')));
    });

    test('an older server, with no flag at all, promises nothing', () {
      final pricing = parse(base({'price_after_promotion': 99}));

      expect(pricing.priceAfterPromotionGuaranteed, isFalse);
      expect(pricing.introductoryNote('LYD', 'monthly'),
          isNot(contains('ثم 99')));
    });

    test('a price kept from a finished offer still shows as the real price', () {
      // No campaign is running, yet this manager pays less than list because
      // they were promised it. Requiring has_promotion here would show them
      // the higher list price as if it were theirs.
      final pricing = parse({
        'normal_price': 119,
        'effective_price': 99,
        'discount_amount': 20,
        'discount_percent': 16.81,
        'has_promotion': false,
        'price_after_promotion': 99,
        'price_after_promotion_guaranteed': true,
      });

      expect(pricing.showsOffer, isTrue);
      // Not an introductory offer, though — nothing is counting down.
      expect(pricing.isIntroductory, isFalse);
      expect(pricing.introductoryNote('LYD', 'monthly'), isNull);
    });
  });
}
