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
            Text(
              priceLabel,
              style: AppTextStyles.font24Bold.copyWith(color: Colors.white),
            ),
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
          ],
        ),
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
