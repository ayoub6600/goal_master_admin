import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:goal_master_admin/core/components/button_app.dart';
import 'package:goal_master_admin/core/components/custom_failure_toast.dart';
import 'package:goal_master_admin/core/components/custom_success_toast.dart';
import 'package:goal_master_admin/core/components/custom_text_field/custom_app_form_text_field.dart';
import 'package:goal_master_admin/core/components/keys_values.dart';
import 'package:goal_master_admin/core/components/preference_utility.dart';
import 'package:goal_master_admin/core/routing/app_router.dart';
import 'package:goal_master_admin/core/routing/route_utils.dart';
import 'package:goal_master_admin/core/routing/routes_keys.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';

import 'package:goal_master_admin/core/styles/assets.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/auth/presentation/manager/login_cubit/login_cubit.dart';

class LoginViewBody extends StatelessWidget {
  const LoginViewBody({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var cubit = context.read<LoginCubit>();
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              Assets.imagesPngImageBackgroundLogin,
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          // width: 336.w,
          // height: 558.h,
          margin: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 100.h,
          ),
          padding: EdgeInsets.fromLTRB(16, 46, 16, 46),
          decoration: BoxDecoration(
            //color: Color(0x1AD9D9D9),
            color: Colors.grey,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(width: 1, color: Colors.transparent),

            gradient: LinearGradient(
              begin: Alignment(0.85, -0.53),
              end: Alignment(-0.85, 0.53),
              colors: [
                Color.fromRGBO(223, 245, 225, 0.05),
                Color.fromRGBO(97, 206, 105, 0.5),
              ],
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: 40.w,
                  ),
                  child: Column(
                    children: [
                      Text(
                        "مرحبًا بعودتك!",
                        style: AppTextStyles.font24Bold.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      HeightSpace(24.h),
                      Text(
                        "للتسجيل في جول ماستر تواصل معنا عبر ",
                        textAlign: TextAlign.center,
                        style: AppTextStyles.font14Bold.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      HeightSpace(8.h),
                      Text(
                        "0916771600",
                        textAlign: TextAlign.center,
                        style: AppTextStyles.font18Bold.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      HeightSpace(48.h),
                    ],
                  ),
                ),
                Text(
                  "الاسم ",
                  style: AppTextStyles.font16Bold.copyWith(
                    color: Colors.white,
                  ),
                ),
                HeightSpace(8.h),
                CustomTextField(
                  hint: "اكتب اسمك",
                  controller: cubit.emailController,
                  inputType: TextInputType.emailAddress,
                ),
                HeightSpace(14.h),
                Text(
                  "كلمة السر",
                  style: AppTextStyles.font16Bold.copyWith(
                    color: Colors.white,
                  ),
                ),
                HeightSpace(8.h),
                CustomTextField(
                  hint: "ضع كلمة السر",
                  password: true,
                  controller: cubit.passwordController,
                ),
                HeightSpace(8.h),
                GestureDetector(
                  onTap: () {
                    push(RoutesKeys.kForgotPassword, context);
                  },
                  child: Text(
                    "هل نسيت كلمة المرور؟",
                    style: AppTextStyles.font14SemiBold.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
                HeightSpace(50.h),
                BlocConsumer<LoginCubit, LoginState>(
                  listener: (context, state) async {
                    if (state is LoginSuccess) {
                      // ✅ حفظ حالة الدخول
                      await SharedPreferenceUtil.putString(
                          PrefKey.login, "true");

                      // ✅ تحديث GoRouter redirect
                      AppRouter.authNotifier.refresh();

                      // ✅ إظهار نجاح والانتقال
                      showCustomSuccessToast("تم تسجيل الدخول بنجاح");
                      GoRouter.of(context).go(RoutesKeys.kHome);
                      // showCustomSuccessToast("تم تسجيل الدخول بنجاح");
                      //pushReplacement(RoutesKeys.kHome, context);
                      // GoRouter.of(context).go(RoutesKeys.kHome);
                    } else if (state is LoginError) {
                      showCustomFailureToast(state.errMessage);
                    } else if (state is LoginLoading) {
                      CircularProgressIndicator();
                    }
                  },
                  builder: (context, state) {
                    if (state is LoginLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return state is! LoginLoading
                        ? ButtonApp(
                            text: "تسجيل الدخول",
                            backGround: AppColors.primary,
                            textColor: Colors.white,
                            onTap: () {
                              cubit.login();
                            },
                          )
                        : const Center(child: CircularProgressIndicator());
                  },
                ),

                HeightSpace(29.h),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   crossAxisAlignment: CrossAxisAlignment.center,
                //   children: [
                //     Text(
                //       "ليس لديك حساب؟",
                //       style: AppTextStyles.font14SemiBold.copyWith(
                //         color: Colors.black,
                //       ),
                //     ),
                //     WidthSpace(5.w),
                //     InkWell(
                //       onTap: () {
                //         push(RoutesKeys.kRegister, context);
                //       },
                //       child: Text(
                //         "انشئ حساب",
                //         style: AppTextStyles.font14SemiBold.copyWith(
                //           color: AppColors.primaryBlueLight,
                //         ),
                //       ),
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
