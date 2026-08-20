import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/button_app.dart';
import 'package:goal_master_admin/core/components/custom_text_field/custom_app_form_text_field.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/manager_onboarding/data/model/subscription_plan_option.dart';
import 'package:goal_master_admin/features/manager_onboarding/presentation/manager/manager_signup_cubit/manager_signup_cubit.dart';

class ManagerSignupFormSection extends StatefulWidget {
  const ManagerSignupFormSection({
    super.key,
    required this.selectedPlan,
    required this.billingCycle,
  });

  final SubscriptionPlanOption? selectedPlan;
  final String billingCycle;

  @override
  State<ManagerSignupFormSection> createState() =>
      _ManagerSignupFormSectionState();
}

class _ManagerSignupFormSectionState extends State<ManagerSignupFormSection> {
  late final ManagerSignupCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<ManagerSignupCubit>();
    _cubit.emailController.addListener(_handleEmailChange);
  }

  @override
  void dispose() {
    _cubit.emailController.removeListener(_handleEmailChange);
    super.dispose();
  }

  void _handleEmailChange() {
    if (mounted) {
      setState(() {});
    }
  }

  bool _shouldShowGmailSuggestion(String value) {
    final trimmedValue = value.trim();
    final atIndex = trimmedValue.indexOf('@');
    if (atIndex == -1) {
      return false;
    }

    final localPart = trimmedValue.substring(0, atIndex);
    final domainPart = trimmedValue.substring(atIndex + 1).toLowerCase();

    if (localPart.isEmpty || domainPart == 'gmail.com') {
      return false;
    }

    return domainPart.isEmpty || 'gmail.com'.startsWith(domainPart);
  }

  String _gmailSuggestion(String value) {
    final localPart = value.trim().split('@').first;
    return '$localPart@gmail.com';
  }

  void _applyGmailSuggestion(ManagerSignupCubit cubit) {
    final suggestedEmail = _gmailSuggestion(cubit.emailController.text);
    cubit.emailController.value = TextEditingValue(
      text: suggestedEmail,
      selection: TextSelection.collapsed(offset: suggestedEmail.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit;
    final showGmailSuggestion =
        _shouldShowGmailSuggestion(cubit.emailController.text);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'بيانات مدير الملعب',
            style: AppTextStyles.font18Bold.copyWith(color: Colors.white),
          ),
          HeightSpace(16.h),
          _label('الاسم الكامل'),
          CustomTextField(
            hint: 'اكتب اسم مدير الملعب',
            controller: cubit.nameController,
            inputType: TextInputType.name,
          ),
          HeightSpace(14.h),
          _label('البريد الإلكتروني'),
          CustomTextField(
            hint: 'name@example.com',
            controller: cubit.emailController,
            inputType: TextInputType.emailAddress,
          ),
          if (showGmailSuggestion) ...[
            HeightSpace(10.h),
            GestureDetector(
              onTap: () => _applyGmailSuggestion(cubit),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.alternate_email_rounded,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 18.sp,
                    ),
                    WidthSpace(10.w),
                    Expanded(
                      child: Text(
                        _gmailSuggestion(cubit.emailController.text),
                        style: AppTextStyles.font14Medium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      'Gmail',
                      style: AppTextStyles.font12Medium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          HeightSpace(14.h),
          _label('رقم الهاتف'),
          CustomTextField(
            hint: '0912345678',
            controller: cubit.phoneController,
            inputType: TextInputType.phone,
          ),
          HeightSpace(14.h),
          _label('كلمة المرور'),
          CustomTextField(
            hint: 'أدخل كلمة المرور',
            controller: cubit.passwordController,
            password: true,
          ),
          HeightSpace(14.h),
          _label('تأكيد كلمة المرور'),
          CustomTextField(
            hint: 'أعد إدخال كلمة المرور',
            controller: cubit.confirmPasswordController,
            password: true,
          ),
          HeightSpace(20.h),
          BlocBuilder<ManagerSignupCubit, ManagerSignupState>(
            builder: (context, state) {
              if (state is ManagerSignupLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              return ButtonApp(
                text: 'إنشاء حساب مدير الملعب',
                backGround: AppColors.primary,
                onTap: widget.selectedPlan == null
                    ? null
                    : () => cubit.register(
                          selectedPlan: widget.selectedPlan!,
                          billingCycle: widget.billingCycle,
                        ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        text,
        style: AppTextStyles.font14Bold.copyWith(color: Colors.white),
      ),
    );
  }
}
