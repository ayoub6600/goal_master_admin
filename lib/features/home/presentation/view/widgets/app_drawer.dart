import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/button_app.dart';
import 'package:goal_master_admin/core/components/keys_values.dart';
import 'package:goal_master_admin/core/components/preference_utility.dart';
import 'package:goal_master_admin/core/routing/route_utils.dart';
import 'package:goal_master_admin/core/routing/routes_keys.dart';
import 'package:goal_master_admin/core/services/service_locator.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/assets.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/auth/data/repo/auth_repo_imp.dart';
import 'package:goal_master_admin/features/home/presentation/manager/delete_account/delete_account_cubit.dart';
import 'package:goal_master_admin/features/home/presentation/manager/delete_account/delete_account_state.dart';
import 'package:goal_master_admin/features/profail/presentation/view/widgets/profile_item.dart';
//flutter bloc
import 'package:flutter_bloc/flutter_bloc.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.white,
      child: ListView(
        padding: EdgeInsets.only(
          top: 50.h,
          left: 16.w,
          right: 16.w,
        ),
        children: [
          Container(
            width: 60.w,
            height: 60.h,
            decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                    image: AssetImage(Assets.imagesPngImageLogo),
                    fit: BoxFit.contain)),
          ),
          HeightSpace(20.h),
          ProfileItem(
            title: "العملاء",
            icon: Assets.imagesPngImageProfile,
            onTap: () {
              push(RoutesKeys.kCustomerView, context);
            },
          ),
          Container(
            width: double.infinity,
            color: Color(0xffDADEE3),
            height: 1.h,
          ),
          HeightSpace(8.h),
          ProfileItem(
            title: "المسامح كريم",
            icon: Assets.imagesPngImageProfile,
            onTap: () {
              push(RoutesKeys.kAllowedAmount, context);
            },
          ),
          Container(
            width: double.infinity,
            color: Color(0xffDADEE3),
            height: 1.h,
          ),
          HeightSpace(8.h),
          ProfileItem(
            title: "الحجز الشهري",
            icon: Assets.imagesPngImageProfile,
            onTap: () {
              push(RoutesKeys.kMonthlyBookingView, context);
            },
          ),
          Container(
            width: double.infinity,
            color: Color(0xffDADEE3),
            height: 1.h,
          ),
          HeightSpace(8.h),
          ProfileItem(
            title: "حذف الحساب",
            icon: Assets.imagesPngImageLogout,
            onTap: () async {
              showModalBottomSheet(
                context: context,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: BlocProvider(
                      create: (_) => DeleteAccountCubit(getIt<AuthRepoImpl>()),
                      child:
                          BlocConsumer<DeleteAccountCubit, DeleteAccountState>(
                        listener: (context, state) async {
                          if (state is DeleteAccountSuccess) {
                            await SharedPreferenceUtil.clear();
                            pushReplacement(RoutesKeys.kLogin, context);
                            SharedPreferenceUtil.putString(
                                PrefKey.onboardingSeen, "true");
                            SharedPreferenceUtil.putString(
                                PrefKey.login, "false");
                          } else if (state is DeleteAccountFailure) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(state.message)),
                            );
                          }
                        },
                        builder: (context, state) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "حذف الحساب",
                                style: AppTextStyles.font16Bold,
                              ),
                              HeightSpace(16.h),
                              Text(
                                "هل أنت متأكد من حذف حسابك؟",
                                style: AppTextStyles.font14Medium.copyWith(
                                  color: AppColors.fontColor,
                                ),
                              ),
                              HeightSpace(16.h),
                              Column(
                                children: [
                                  Center(
                                    child: Text(
                                      "سيتم حذف جميع سجلاتك من قاعدة البيانات لدينا.",
                                      textAlign: TextAlign.center,
                                      style:
                                          AppTextStyles.font14Medium.copyWith(
                                        color: AppColors.fontColor,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "نشكرك على وقتك معنا ونتمنى لك كل التوفيق 🌟",
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.font14Medium.copyWith(
                                      color: AppColors.fontColor,
                                    ),
                                  )
                                ],
                              ),
                              HeightSpace(16.h),
                              Row(
                                children: [
                                  Expanded(
                                    child: ButtonApp(
                                      text: state is DeleteAccountLoading
                                          ? "جاري الحذف..."
                                          : "حذف",
                                      onTap: state is DeleteAccountLoading
                                          ? null
                                          : () {
                                              context
                                                  .read<DeleteAccountCubit>()
                                                  .deleteAccount();
                                            },
                                    ),
                                  ),
                                  WidthSpace(16.w),
                                  Expanded(
                                    child: ButtonApp(
                                      textColor: Colors.white,
                                      backGround: Colors.red,
                                      text: "إلغاء",
                                      onTap: () {
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
            child: SizedBox(),
          ),
        ],
      ),
    );
  }
}
