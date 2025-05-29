import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/button_app.dart';
import 'package:goal_master_admin/core/components/keys_values.dart';
import 'package:goal_master_admin/core/components/page_wrapper.dart';
import 'package:goal_master_admin/core/components/preference_utility.dart';
import 'package:goal_master_admin/core/routing/route_utils.dart';
import 'package:goal_master_admin/core/routing/routes_keys.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/assets.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/profail/presentation/view/widgets/profile_header.dart';
import 'package:goal_master_admin/features/profail/presentation/view/widgets/profile_item.dart';
import 'package:go_router/go_router.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      title: "حسابي",
      allowBack: false,
      child: Column(
        children: [
          ProfileHeader(),
          HeightSpace(16.h),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                //  spacing: 16.h,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        Assets.imagesPngImageSetting2,
                        fit: BoxFit.cover,
                      ),
                      WidthSpace(16.w),
                      Text(
                        "اعدادات عامة",
                        style: AppTextStyles.font16Bold.copyWith(
                          color: AppColors.fontColor,
                        ),
                      ),
                    ],
                  ),
                  HeightSpace(8.h),
                  ProfileItem(
                    title: "تغيير معلوماتك الشخصية",
                    icon: Assets.imagesPngImageMagicpen,
                    onTap: () {
                      GoRouter.of(context).push(RoutesKeys.kUpdateProfile);

                      //     push(RoutesKeys.kUpdateProfile, context);
                    },
                  ),
                  Container(
                    width: double.infinity,
                    color: Color(0xffDADEE3),
                    height: 1.h,
                  ),
                  HeightSpace(8.h),
                  ProfileItem(
                    title: "تغيير كلمة المرور",
                    icon: Assets.imagesPngImageKey,
                    onTap: () {
                      push(RoutesKeys.kChangePassword, context);
                    },
                  ),
                  Container(
                    width: double.infinity,
                    color: Color(0xffDADEE3),
                    height: 1.h,
                  ),
                  HeightSpace(8.h),
                  ProfileItem(
                    title: "خروج",
                    icon: Assets.imagesPngImageLogout,
                    onTap: () async {
                      showModalBottomSheet(
                        context: context,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (context) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "تسجيل الخروج",
                                  style: AppTextStyles.font16Bold,
                                ),
                                HeightSpace(16.h),
                                Text(
                                  "هل أنت متأكد أنك تريد تسجيل الخروج؟",
                                  style: AppTextStyles.font14Medium.copyWith(
                                    color: AppColors.fontColor,
                                  ),
                                ),
                                HeightSpace(16.h),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ButtonApp(
                                          text: "تسجيل الخروج",
                                          onTap: () async {
                                            Navigator.pop(
                                                context); // Close the sheet
                                            await SharedPreferenceUtil.clear();

                                            SharedPreferenceUtil.putString(
                                                PrefKey.login, "false");
                                            SharedPreferenceUtil.putBool(
                                                PrefKey.onboardingSeen, true);
                                            pushReplacement(
                                                RoutesKeys.kLogin, context);
                                          }),
                                    ),
                                    WidthSpace(16.w),
                                    Expanded(
                                      child: ButtonApp(
                                          textColor: Colors.white,
                                          backGround: Colors.red,
                                          text: "الغاء",
                                          onTap: () {
                                            Navigator.pop(
                                                context); // Close the sheet
                                          }),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    child: SizedBox(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
