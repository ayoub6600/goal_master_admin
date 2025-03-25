import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/button_wrapper.dart'
    show ButtonWrapper;
import 'package:goal_master_admin/core/components/keys_values.dart'
    show PrefKey;
import 'package:goal_master_admin/core/components/preference_utility.dart';
import 'package:goal_master_admin/core/routing/route_utils.dart'
    show pushReplacement;
import 'package:goal_master_admin/core/routing/routes_keys.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/features/onbording/data/datasource/onboarding_pages.dart'
    show OnboardingPages;
import 'package:goal_master_admin/features/onbording/presentation/manager/onboarding_cubit.dart'
    show OnboardingCubit, OnboardingState;

class OnboardingSkipPageButton extends StatelessWidget {
  const OnboardingSkipPageButton({super.key});

  @override
  Widget build(BuildContext context) {
    var cubit = context.read<OnboardingCubit>();
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        bool isLastPage =
            state.index == OnboardingPages.getPages(context).length - 1;
        return ButtonWrapper(
          onTap: () {
            bool done = cubit.increment(context);
            if (!done) {
              pushReplacement(RoutesKeys.kRegister, context);
              SharedPreferenceUtil.putString(PrefKey.login, "true");
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              //  color: AppColors.primary,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                width: 1,
                color: isLastPage ? AppColors.black : Colors.white,
              ),
            ),
            child: Text(
              isLastPage ? "انشاء حساب" : "تخطى",
              style: AppTextStyles.font16Regular.copyWith(color: Colors.black),
            ),
          ),
        );
      },
    );
  }
}
