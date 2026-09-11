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
import 'package:goal_master_admin/core/routing/route_utils.dart';
import 'package:goal_master_admin/core/routing/routes_keys.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/assets.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/auth/presentation/manager/login_cubit/login_cubit.dart';

class LoginViewBody extends StatelessWidget {
  const LoginViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LoginCubit>();
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(Assets.imagesPngImageBackgroundLogin),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.only(bottom: keyboardHeight),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Container(
                      margin: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 40.h),
                      padding: const EdgeInsets.fromLTRB(16, 46, 16, 46),
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          begin: Alignment(0.85, -0.53),
                          end: Alignment(-0.85, 0.53),
                          colors: [
                            Color.fromRGBO(223, 245, 225, 0.05),
                            Color.fromRGBO(97, 206, 105, 0.5),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Column(
                              children: [
                                Text("مرحبًا بعودتك!",
                                    style: AppTextStyles.font24Bold
                                        .copyWith(color: Colors.white)),
                                HeightSpace(24.h),
                                Text("للتسجيل في جول ماستر تواصل معنا عبر",
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.font14Bold
                                        .copyWith(color: Colors.white)),
                                HeightSpace(8.h),
                                Text("0916771600",
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.font18Bold
                                        .copyWith(color: Colors.white)),
                                HeightSpace(18.h),
                                GestureDetector(
                                  onTap: () => GoRouter.of(context)
                                      .push(RoutesKeys.kRegister),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 14.w,
                                      vertical: 10.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(99.r),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.28),
                                      ),
                                    ),
                                    child: Text(
                                      "ليس لديك حساب؟ أنشئ حساب مدير ملعب",
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.font14Bold
                                          .copyWith(color: Colors.white),
                                    ),
                                  ),
                                ),
                                HeightSpace(48.h),
                              ],
                            ),
                          ),
                          Text("اسم المستخدم أو رقم الهاتف",
                              style: AppTextStyles.font16Bold
                                  .copyWith(color: Colors.white)),
                          HeightSpace(8.h),
                          CustomTextField(
                            hint: "اكتب اسم المستخدم أو رقم هاتفك",
                            controller: cubit.emailController,
                            inputType: TextInputType.text,
                          ),
                          HeightSpace(14.h),
                          Text("كلمة السر",
                              style: AppTextStyles.font16Bold
                                  .copyWith(color: Colors.white)),
                          HeightSpace(8.h),
                          CustomTextField(
                            hint: "ضع كلمة السر",
                            password: true,
                            controller: cubit.passwordController,
                          ),
                          HeightSpace(8.h),
                          GestureDetector(
                            onTap: () => GoRouter.of(context)
                                .push(RoutesKeys.kForgotPassword),
                            child: Text("هل نسيت كلمة المرور؟",
                                style: AppTextStyles.font14SemiBold
                                    .copyWith(color: Colors.white)),
                          ),
                          HeightSpace(30.h),
                          BlocConsumer<LoginCubit, LoginState>(
                            listener: (context, state) async {
                              if (state is LoginSuccess) {
                                await SharedPreferenceUtil.putString(
                                    PrefKey.login, "true");
                                showCustomSuccessToast("تم تسجيل الدخول بنجاح");
                                go(RoutesKeys.kHome, context);
                              } else if (state is LoginError) {
                                showCustomFailureToast(state.errMessage);
                              }
                            },
                            builder: (context, state) {
                              if (state is LoginLoading) {
                                return const Center(
                                    child: CircularProgressIndicator(
                                        color: Colors.white));
                              }
                              return ButtonApp(
                                text: "تسجيل الدخول",
                                backGround: AppColors.primary,
                                textColor: Colors.white,
                                onTap: () {
                                  FocusScope.of(context).unfocus();
                                  cubit.login();
                                },
                              );
                            },
                          ),
                          HeightSpace(29.h),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
