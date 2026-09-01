import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/manager_onboarding/data/model/subscription_plan_option.dart';

class SubscriptionPlanCard extends StatelessWidget {
  const SubscriptionPlanCard({
    super.key,
    required this.plan,
    required this.billingCycle,
    required this.isSelected,
    required this.onTap,
  });

  final SubscriptionPlanOption plan;
  final String billingCycle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final priceLabel = billingCycle == 'yearly'
        ? plan.yearlyPriceLabel
        : plan.monthlyPriceLabel;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlueLight : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    style:
                        AppTextStyles.font18Bold.copyWith(color: Colors.white),
                  ),
                ),
                if (plan.badgeLabel.isNotEmpty)
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(99.r),
                    ),
                    child: Text(
                      plan.badgeLabel,
                      style: AppTextStyles.font12Bold
                          .copyWith(color: Colors.white),
                    ),
                  ),
              ],
            ),
            HeightSpace(10.h),
            _priceBlock(priceLabel),
            HeightSpace(6.h),
            Text(
              plan.shortDescription.isNotEmpty
                  ? plan.shortDescription
                  : plan.description,
              style: AppTextStyles.font14Regular.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.5,
              ),
            ),
            HeightSpace(14.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                _featureChip('ملاعب: ${plan.features.maxFields}'),
                _featureChip('فروع: ${plan.features.maxBranches}'),
                _featureChip('موظفين: ${plan.features.maxStaff}'),
                if (plan.trialDays > 0)
                  _featureChip('تجربة ${plan.trialDays} يوم'),
                if (plan.features.allowReports) _featureChip('تقارير'),
                if (plan.features.allowWallet) _featureChip('محفظة'),
              ],
            ),
            HeightSpace(14.h),
            _termsBlock(),
          ],
        ),
      ),
    );
  }

  /// The price, and honestly what happens to it.
  ///
  /// Only draws a struck-through price when the SERVER says this manager can
  /// actually have the offer — showing one to somebody who does not qualify
  /// would be inventing a discount. And when the offer only covers the first
  /// few cycles, it says so on the card: a manager should never come to
  /// believe 59 is the price and find 99 on their fourth month.
  Widget _priceBlock(String priceLabel) {
    final pricing =
        billingCycle == 'yearly' ? plan.yearlyPricing : plan.monthlyPricing;
    final currency = plan.currencyCode;

    if (pricing == null || !pricing.showsOffer) {
      return Text(
        priceLabel,
        style: AppTextStyles.font24Bold.copyWith(color: Colors.white),
      );
    }

    final note = pricing.introductoryNote(currency, billingCycle);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((pricing.promotionBadge ?? '').isNotEmpty) ...[
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(99.r),
            ),
            child: Text(
              pricing.promotionBadge!,
              style: AppTextStyles.font12Medium.copyWith(color: Colors.amber),
            ),
          ),
          HeightSpace(8.h),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${_money(pricing.normalPrice)} $currency',
              style: AppTextStyles.font14Regular.copyWith(
                color: Colors.white.withValues(alpha: 0.65),
                decoration: TextDecoration.lineThrough,
              ),
            ),
            WidthSpace(8.w),
            Text(
              '${_money(pricing.effectivePrice)} $currency',
              style: AppTextStyles.font24Bold.copyWith(color: Colors.white),
            ),
          ],
        ),
        HeightSpace(4.h),
        Text(
          'وفر ${_money(pricing.discountAmount)} $currency — خصم ${pricing.discountPercent.round()}%',
          style: AppTextStyles.font12Medium.copyWith(color: Colors.amber),
        ),
        // Written by the server, rendered verbatim. The card must not
        // assemble "ثم {price}" itself: a campaign that returns to the plan's
        // standard price promises no future figure, and printing one here
        // would invent a guarantee on every device at once.
        if (note != null) ...[
          HeightSpace(6.h),
          Text(
            note,
            style: AppTextStyles.font12Medium.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  String _money(double value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);

  /// What this plan actually costs the venue, in the terms an owner thinks in.
  ///
  /// The limits above are capacity; this is the commercial decision. Leaving
  /// commission off the card meant a manager could pick the cheapest monthly
  /// fee without seeing what it charges per booking — which is the whole
  /// trade-off the ladder exists to offer.
  Widget _termsBlock() {
    final f = plan.features;

    if (!f.allowCustomerMarketplace) {
      // A different business model, not a cheaper rung. The two marketplace
      // lines are genuine absences and are marked as such; saying "0% عمولة"
      // without them would read as the bargain of the ladder.
      return _panel([
        _line(FeatureTone.available, 'نظام إدارة كامل لملعبك وزبائنك'),
        _line(FeatureTone.available, 'حجوزاتك المباشرة بدون عمولة'),
        _line(FeatureTone.unavailable,
            'ملعبك لا يظهر للزبائن في تطبيق Goal Master'),
        _line(FeatureTone.unavailable,
            'لا تحصل على حجوزات من سوق Goal Master'),
      ]);
    }

    final prepaid = _percent(f.prepaidCommissionPercent);
    final poa = _percent(f.poaCommissionPercent);
    final free = f.prepaidCommissionPercent == 0 && f.poaCommissionPercent == 0;

    return _panel([
      _line(FeatureTone.available, 'ملعبك يظهر للزبائن في تطبيق Goal Master'),
      _line(FeatureTone.available, 'تستقبل حجوزات من Goal Master'),
      // Commission is what the venue agrees to pay, not a capability it has
      // been denied. Marking it with the same icon as a missing feature made a
      // normal commercial term read as a penalty.
      if (free)
        _line(FeatureTone.info, '0% عمولة على كل حجوزات Goal Master')
      else ...[
        _line(FeatureTone.info, 'عمولة الدفع المسبق: $prepaid'),
        if (f.allowLocalPayment)
          _line(FeatureTone.info, 'عمولة الدفع عند الملعب: $poa'),
      ],
      if (f.allowLocalPayment)
        _line(FeatureTone.available, 'الدفع عند الوصول متاح لزبائن Goal Master')
      else
        _line(FeatureTone.unavailable,
            'الدفع عند الوصول غير متاح في هذه الباقة'),
      _line(FeatureTone.available, 'حجوزاتك المباشرة بدون عمولة'),
    ]);
  }

  String _percent(double value) {
    final rounded = value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
    return '$rounded%';
  }

  Widget _panel(List<Widget> lines) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines,
      ),
    );
  }

  /// Three kinds of statement, and they must not look alike.
  ///
  /// A capability the plan HAS, one it does NOT, and a commercial term the
  /// venue accepts. These were previously two: commission shared an icon with
  /// missing features, so agreeing to pay 10% looked like being denied
  /// something.
  Widget _line(FeatureTone tone, String text) {
    final (IconData icon, Color color) = switch (tone) {
      FeatureTone.available => (Icons.check_circle, const Color(0xFF4CD964)),
      FeatureTone.unavailable => (Icons.cancel, const Color(0xFFFF5A5A)),
      FeatureTone.info => (Icons.check_circle, const Color(0xFF4CD964)),
    };

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15.sp, color: color),
          WidthSpace(7.w),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.font12Medium.copyWith(
                color: Colors.white.withValues(
                  alpha: tone == FeatureTone.unavailable ? 0.78 : 0.95,
                ),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99.r),
      ),
      child: Text(
        label,
        style: AppTextStyles.font12Medium.copyWith(color: Colors.white),
      ),
    );
  }
}

/// How a feature line should read.
///
/// Kept as structured data rather than inferred from the Arabic text: the
/// wording is presentation, the meaning is not.
enum FeatureTone {
  /// The plan has this.
  available,

  /// The plan does not. Red, because an absence the manager is choosing
  /// should be unmistakable.
  unavailable,

  /// A commercial term — commission. Shown affirmatively: it is something the
  /// venue agrees to, not a capability withheld.
  info,
}
