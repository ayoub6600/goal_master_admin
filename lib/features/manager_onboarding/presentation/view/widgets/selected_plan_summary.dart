import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/manager_onboarding/data/model/subscription_plan_option.dart';

class SelectedPlanSummary extends StatelessWidget {
  const SelectedPlanSummary({
    super.key,
    required this.plan,
    required this.billingCycle,
  });

  final SubscriptionPlanOption plan;
  final String billingCycle;

  @override
  Widget build(BuildContext context) {
    final priceLabel = billingCycle == 'yearly'
        ? plan.yearlyPriceLabel
        : plan.monthlyPriceLabel;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.primaryBlueLight.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الباقة المختارة',
            style: AppTextStyles.font14Bold.copyWith(color: Colors.white),
          ),
          HeightSpace(8.h),
          Text(
            '${plan.name} • $priceLabel',
            style: AppTextStyles.font18Bold.copyWith(color: Colors.white),
          ),
          HeightSpace(6.h),
          Text(
            plan.trialDays > 0
                ? 'سيبدأ الحساب بفترة تجربة ${plan.trialDays} يوم في هذه المرحلة.'
                : 'سيتم إنشاء الحساب على هذه الباقة مباشرة في هذه المرحلة.',
            style: AppTextStyles.font12Regular.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
