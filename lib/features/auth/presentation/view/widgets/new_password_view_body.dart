import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/button_app.dart'
    show ButtonApp;
import 'package:goal_master_admin/core/components/custom_text_field/custom_app_form_text_field.dart'
    show CustomTextField;
import 'package:goal_master_admin/core/components/page_wrapper.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart' show AppColors;
import 'package:goal_master_admin/core/styles/app_text_styles.dart'
    show AppTextStyles;
import 'package:goal_master_admin/core/styles/spaces.dart';

class NewPasswordViewBody extends StatelessWidget {
  const NewPasswordViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20.0.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              "أنشئ كلمة مرور جديدة",
              style: AppTextStyles.font24Bold.copyWith(color: AppColors.black),
            ),
            HeightSpace(16.h),
            SizedBox(
              width: 250.w,
              child: Text(
                "يُفضّل اختيار كلمة مرور قوية تحتوي على أرقام وحروف لضمان أمان حسابك",
                style: AppTextStyles.font14SemiBold.copyWith(
                  color: AppColors.inactiveText1,
                ),
              ),
            ),
            HeightSpace(32.h),
            Text(
              "كلمة المرور الجديدة",
              style: AppTextStyles.font16Bold.copyWith(color: Colors.black),
            ),
            HeightSpace(8.h),
            CustomTextField(
              hint: "ضع كلمة السر",
              password: true,

              //   controller: cubit.emailController,
              inputType: TextInputType.text,
            ),
            HeightSpace(16.h),
            Text(
              'أعد ادخال كلمة المرور',
              style: AppTextStyles.font16Bold.copyWith(color: Colors.black),
            ),
            HeightSpace(8.h),
            CustomTextField(
              hint: "أعد كلمة السر ",
              password: true,
              inputType: TextInputType.text,
            ),
            HeightSpace(100.h),
            ButtonApp(text: "تحديث كلمة المرور", onTap: () {}),
          ],
        ),
      ),
    );
  }
}
