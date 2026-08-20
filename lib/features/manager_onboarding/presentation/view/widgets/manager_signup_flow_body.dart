import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:goal_master_admin/core/components/custom_failure_toast.dart';
import 'package:goal_master_admin/core/components/custom_success_toast.dart';
import 'package:goal_master_admin/core/routing/routes_keys.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/assets.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/manager_onboarding/data/model/subscription_plan_option.dart';
import 'package:goal_master_admin/features/manager_onboarding/presentation/manager/manager_signup_cubit/manager_signup_cubit.dart';
import 'package:goal_master_admin/features/manager_onboarding/presentation/manager/subscription_plans_cubit/subscription_plans_cubit.dart';
import 'package:goal_master_admin/features/manager_onboarding/presentation/view/widgets/manager_signup_form_section.dart';
import 'package:goal_master_admin/features/manager_onboarding/presentation/view/widgets/selected_plan_summary.dart';
import 'package:goal_master_admin/features/manager_onboarding/presentation/view/widgets/subscription_plan_card.dart';

class ManagerSignupFlowBody extends StatefulWidget {
  const ManagerSignupFlowBody({super.key});

  @override
  State<ManagerSignupFlowBody> createState() => _ManagerSignupFlowBodyState();
}

class _ManagerSignupFlowBodyState extends State<ManagerSignupFlowBody> {
  SubscriptionPlanOption? selectedPlan;
  String billingCycle = 'monthly';

  @override
  void initState() {
    super.initState();
    context.read<SubscriptionPlansCubit>().loadPlans();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(Assets.imagesPngImageBackgroundLogin),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: BlocListener<ManagerSignupCubit, ManagerSignupState>(
            listener: (context, state) {
              if (state is ManagerSignupError) {
                showCustomFailureToast(state.message);
              } else if (state is ManagerSignupSuccess) {
                showCustomSuccessToast(
                  'تم إنشاء الحساب بنجاح. جاري إدخالك إلى حسابك.',
                );
                GoRouter.of(context).go(RoutesKeys.kHome);
              }
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: keyboardHeight),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Container(
                      margin: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 24.h),
                      padding: EdgeInsets.all(18.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24.r),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color.fromRGBO(6, 18, 31, 0.92),
                            Color.fromRGBO(20, 57, 35, 0.92),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBackToLoginAction(context),
                          HeightSpace(18.h),
                          Text(
                            'ابدأ إدارة ملعبك مع Goal Master',
                            style: AppTextStyles.font24Bold.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          HeightSpace(10.h),
                          Text(
                            'اختر الباقة المناسبة ثم أنشئ حساب مدير الملعب. تفعيل الدفع والـ OTP سنضيفه في المرحلة التالية فوق نفس الهيكل.',
                            style: AppTextStyles.font14Regular.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                              height: 1.5,
                            ),
                          ),
                          HeightSpace(20.h),
                          _buildCycleToggle(),
                          HeightSpace(18.h),
                          BlocBuilder<SubscriptionPlansCubit,
                              SubscriptionPlansState>(
                            builder: (context, state) {
                              if (state is SubscriptionPlansLoading) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              }

                              if (state is SubscriptionPlansError) {
                                return _buildErrorState(context, state.message);
                              }

                              if (state is SubscriptionPlansLoaded) {
                                if (selectedPlan == null &&
                                    state.plans.isNotEmpty) {
                                  selectedPlan = state.plans.first;
                                }

                                return Column(
                                  children: [
                                    ...state.plans.map(
                                      (plan) => Padding(
                                        padding: EdgeInsets.only(bottom: 12.h),
                                        child: SubscriptionPlanCard(
                                          plan: plan,
                                          billingCycle: billingCycle,
                                          isSelected:
                                              selectedPlan?.id == plan.id,
                                          onTap: () {
                                            setState(() {
                                              selectedPlan = plan;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    HeightSpace(10.h),
                                    if (selectedPlan != null)
                                      SelectedPlanSummary(
                                        plan: selectedPlan!,
                                        billingCycle: billingCycle,
                                      ),
                                    HeightSpace(18.h),
                                    ManagerSignupFormSection(
                                      selectedPlan: selectedPlan,
                                      billingCycle: billingCycle,
                                    ),
                                  ],
                                );
                              }

                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCycleToggle() {
    final isMonthly = billingCycle == 'monthly';

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildCycleChip(
              title: 'شهري',
              isActive: isMonthly,
              onTap: () => setState(() => billingCycle = 'monthly'),
            ),
          ),
          WidthSpace(8.w),
          Expanded(
            child: _buildCycleChip(
              title: 'سنوي',
              isActive: !isMonthly,
              onTap: () => setState(() => billingCycle = 'yearly'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackToLoginAction(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () => GoRouter.of(context).go(RoutesKeys.kLogin),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(99.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 14.sp,
              ),
              WidthSpace(8.w),
              Text(
                'لدي حساب بالفعل',
                style: AppTextStyles.font14Bold.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCycleChip({
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Center(
          child: Text(
            title,
            style: AppTextStyles.font14Bold.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.white, size: 28.sp),
          HeightSpace(12.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.font14Medium.copyWith(color: Colors.white),
          ),
          HeightSpace(12.h),
          OutlinedButton(
            onPressed: () => context.read<SubscriptionPlansCubit>().loadPlans(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white),
            ),
            child: const Text(
              'إعادة تحميل الباقات',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
