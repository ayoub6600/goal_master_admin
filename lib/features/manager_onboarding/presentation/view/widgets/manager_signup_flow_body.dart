import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:goal_master_admin/core/components/button_app.dart';
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

  /// Which card is centred, which is not the same thing as which plan is
  /// chosen. Swiping to compare must not quietly change what you are buying,
  /// so the two are tracked separately and only a tap moves [selectedPlan].
  int _viewedIndex = 0;
  PageController? _plansController;
  String billingCycle = 'monthly';

  // Step 0 = choose a plan and confirm; step 1 = create the manager
  // account. Kept as two steps of the same widget (not two separate
  // routes) so `ManagerSignupCubit`'s text controllers, provided once at
  // the route level, survive the transition between them.
  int _step = 0;

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
            child: BlocListener<SubscriptionPlansCubit,
                SubscriptionPlansState>(
              // The default is chosen when the plans land, not while building.
              // Assigning it inside the builder left the pinned footer — a
              // sibling constructed earlier in the same frame — with nothing
              // to show on the first paint.
              listener: (context, state) {
                if (state is SubscriptionPlansLoaded &&
                    selectedPlan == null &&
                    state.plans.isNotEmpty) {
                  setState(() => selectedPlan = state.plans.first);
                }
              },
              child: LayoutBuilder(
              builder: (context, constraints) {
                // On the plan step the footer is pinned: the carousel scrolls
                // beneath it, the decision does not move. The form step keeps
                // the ordinary single scroll.
                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
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
                            _step == 0
                                ? 'اختر الباقة المناسبة لملعبك، ثم تابع لإنشاء حساب المدير.'
                                : 'أدخل بيانات مدير الملعب لإنشاء الحساب. تفعيل الدفع والـ OTP سنضيفه في المرحلة التالية فوق نفس الهيكل.',
                            style: AppTextStyles.font14Regular.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                              height: 1.5,
                            ),
                          ),
                          HeightSpace(20.h),
                          if (_step == 0) ...[
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
                                  return _buildErrorState(
                                      context, state.message);
                                }

                                if (state is SubscriptionPlansLoaded) {
                                  return _buildPlanChooser(state.plans);
                                }

                                return const SizedBox.shrink();
                              },
                            ),
                          ] else if (selectedPlan != null) ...[
                            SelectedPlanSummary(
                              plan: selectedPlan!,
                              billingCycle: billingCycle,
                            ),
                            HeightSpace(8.h),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => setState(() => _step = 0),
                                child: Text(
                                  'تغيير الباقة',
                                  style: AppTextStyles.font14Bold.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            HeightSpace(10.h),
                            ManagerSignupFormSection(
                              selectedPlan: selectedPlan,
                              billingCycle: billingCycle,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                      ),
                    ),
                    if (_step == 0) _buildSelectionFooter(),
                  ],
                );
              },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The plan chooser: a horizontal carousel, a viewed-position indicator, and
  /// a footer that stays put.
  ///
  /// Five plans stacked vertically made the page long enough that comparing
  /// the first with the last meant remembering it, and the Continue button sat
  /// below all of them — so you had to scroll past everything to find out what
  /// you had chosen. Side by side, the choice is a comparison rather than a
  /// list, and the decision stays on screen while you browse.
  @override
  void dispose() {
    _plansController?.dispose();
    super.dispose();
  }

  Widget _buildPlanChooser(List<SubscriptionPlanOption> plans) {
    if (plans.isEmpty) return const SizedBox.shrink();

    _viewedIndex = _viewedIndex.clamp(0, plans.length - 1);

    // Built once the plan count is known, starting on whatever is already
    // selected so returning to this step does not jump back to the first card.
    _plansController ??= PageController(
      viewportFraction: 0.82,
      initialPage: selectedPlan == null
          ? 0
          : plans.indexWhere((p) => p.id == selectedPlan!.id).clamp(0, plans.length - 1),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          // Tall enough for the longest card's features; the carousel scrolls
          // sideways, never the page.
          // Leaves room for the indicator, the summary and the button beneath
          // it on a small phone; taller cards scroll inside their page.
          height: 430.h,
          child: PageView.builder(
            controller: _plansController,
            itemCount: plans.length,
            padEnds: false,
            // Browsing only moves the indicator. Selection is a deliberate tap.
            onPageChanged: (index) => setState(() => _viewedIndex = index),
            itemBuilder: (context, index) {
              final plan = plans[index];

              // Each card scrolls inside its own page. Plans differ in how
              // many feature lines they carry, and the tallest must stay
              // readable on the smallest phone without the carousel resizing
              // itself card by card.
              return Padding(
                padding: EdgeInsets.only(left: 10.w),
                child: SingleChildScrollView(
                  child: SubscriptionPlanCard(
                    plan: plan,
                    billingCycle: billingCycle,
                    isSelected: selectedPlan?.id == plan.id,
                    onTap: () => setState(() => selectedPlan = plan),
                  ),
                ),
              );
            },
          ),
        ),
        HeightSpace(12.h),
        _buildPageIndicator(plans.length),
      ],
    );
  }

  /// The decision, kept on screen.
  ///
  /// This used to sit under all five plan cards, so the only way to find out
  /// what you had chosen was to scroll past everything you were choosing
  /// between. It now sits outside the scrollable region entirely: the carousel
  /// moves, this does not.
  Widget _buildSelectionFooter() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 12.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectedPlan != null)
              SelectedPlanSummary(
                plan: selectedPlan!,
                billingCycle: billingCycle,
              ),
            HeightSpace(12.h),
            ButtonApp(
              text: ' متابعة',
              backGround: AppColors.primary,
              onTap: selectedPlan == null
                  ? null
                  : () => setState(() => _step = 1),
            ),
          ],
        ),
      ),
    );
  }

  /// Where you are in the carousel — the card being looked at, not the plan
  /// chosen. Those are deliberately different things and the dots say so.
  Widget _buildPageIndicator(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = index == _viewedIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: EdgeInsets.symmetric(horizontal: 3.w),
          width: active ? 18.w : 7.w,
          height: 7.w,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: active ? 0.95 : 0.32),
            borderRadius: BorderRadius.circular(99.r),
          ),
        );
      }),
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
