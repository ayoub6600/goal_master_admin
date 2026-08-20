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
import 'package:goal_master_admin/features/profail/presentation/manager/profile_cubit/profile_cubit.dart';
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
          BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, state) {
              final user = state is ProfileLoaded ? state.user : null;
              final planName =
                  user?.currentSubscription?.planName?.trim().isNotEmpty == true
                      ? user!.currentSubscription!.planName!
                      : 'بدون باقة محددة';

              return Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xffF4F8F2),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: const Color(0xffD8E7D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'الباقة الحالية',
                          style: AppTextStyles.font14Medium.copyWith(
                            color: AppColors.fontColor,
                          ),
                        ),
                        if (user?.currentSubscription?.isTrial == true) ...[
                          WidthSpace(6.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: const Color(0xff1E88E5),
                              borderRadius: BorderRadius.circular(99.r),
                            ),
                            child: Text(
                              'تجربة مجانية',
                              style: AppTextStyles.font12Bold
                                  .copyWith(color: Colors.white),
                            ),
                          ),
                        ],
                      ],
                    ),
                    HeightSpace(6.h),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            planName,
                            style: AppTextStyles.font16Bold.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 4.h),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            push(RoutesKeys.kManagerSubscription, context);
                          },
                          child: Text(
                            'تجديد',
                            style: AppTextStyles.font14Bold.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (user != null) ...[
                      HeightSpace(8.h),
                      Text(
                        user.canUseMonthlyBookings
                            ? 'الحجز الشهري متاح في هذه الباقة'
                            : 'الحجز الشهري غير متاح في هذه الباقة',
                        style: AppTextStyles.font14Medium.copyWith(
                          color: user.canUseMonthlyBookings
                              ? const Color(0xff2E7D32)
                              : Colors.redAccent,
                        ),
                      ),
                    ],
                    if (user?.currentSubscription != null &&
                        (user!.currentSubscription!.isExpiringSoon ||
                            user.currentSubscription!.isExpired)) ...[
                      HeightSpace(8.h),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          push(RoutesKeys.kManagerSubscription, context);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: const Color(0xffFFF4E5),
                            borderRadius: BorderRadius.circular(10.r),
                            border:
                                Border.all(color: const Color(0xffF3C98A)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: const Color(0xffB25E00), size: 16.sp),
                              WidthSpace(6.w),
                              Expanded(
                                child: Text(
                                  user.currentSubscription!.isExpired
                                      ? 'باقتك منتهية. اضغط للتجديد'
                                      : 'باقتك تنتهي خلال ${user.currentSubscription!.daysRemaining} ${user.currentSubscription!.daysRemaining == 1 ? 'يوم' : 'أيام'}. اضغط للتجديد',
                                  style: AppTextStyles.font12Medium.copyWith(
                                    color: const Color(0xff7A3E00),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          HeightSpace(16.h),
          BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, state) {
              final user = state is ProfileLoaded ? state.user : null;
              final needsVenueSetup = user?.needsVenueSetup ?? false;

              if (needsVenueSetup) {
                return Column(
                  children: [
                    ProfileItem(
                      title: "إعداد بيانات الملعب",
                      icon: Assets.imagesPngImageProfile,
                      onTap: () {
                        push(RoutesKeys.kAddFirstVenue, context);
                      },
                    ),
                    Container(
                      width: double.infinity,
                      color: Color(0xffDADEE3),
                      height: 1.h,
                    ),
                    HeightSpace(8.h),
                    ProfileItem(
                      title: "محفظة مدير الملعب",
                      icon: Assets.imagesPngImageProfile,
                      onTap: () {
                        push(RoutesKeys.kManagerWallet, context);
                      },
                    ),
                    Container(
                      width: double.infinity,
                      color: Color(0xffDADEE3),
                      height: 1.h,
                    ),
                    HeightSpace(8.h),
                    ProfileItem(
                      title: "إعدادات الدفع",
                      icon: Assets.imagesPngImageProfile,
                      onTap: () {
                        push(RoutesKeys.kManagerPaymentSettings, context);
                      },
                    ),
                    Container(
                      width: double.infinity,
                      color: Color(0xffDADEE3),
                      height: 1.h,
                    ),
                    HeightSpace(8.h),
                    ProfileItem(
                      title: "فترات الحجز",
                      icon: Assets.imagesPngImageProfile,
                      onTap: () {
                        push(RoutesKeys.kManagerBookingPeriods, context);
                      },
                    ),
                    Container(
                      width: double.infinity,
                      color: Color(0xffDADEE3),
                      height: 1.h,
                    ),
                    HeightSpace(8.h),
                    ProfileItem(
                      title: "الاشتراك",
                      icon: Assets.imagesPngImageProfile,
                      onTap: () {
                        push(RoutesKeys.kManagerSubscription, context);
                      },
                    ),
                    Container(
                      width: double.infinity,
                      color: Color(0xffDADEE3),
                      height: 1.h,
                    ),
                    HeightSpace(8.h),
                  ],
                );
              }

              final canUseMonthlyBookings =
                  state is! ProfileLoaded || state.user.canUseMonthlyBookings;

              return Column(
                children: [
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
                    title: "محفظة مدير الملعب",
                    icon: Assets.imagesPngImageProfile,
                    onTap: () {
                      push(RoutesKeys.kManagerWallet, context);
                    },
                  ),
                  Container(
                    width: double.infinity,
                    color: Color(0xffDADEE3),
                    height: 1.h,
                  ),
                  HeightSpace(8.h),
                  ProfileItem(
                    title: "إعدادات الدفع",
                    icon: Assets.imagesPngImageProfile,
                    onTap: () {
                      push(RoutesKeys.kManagerPaymentSettings, context);
                    },
                  ),
                  Container(
                    width: double.infinity,
                    color: Color(0xffDADEE3),
                    height: 1.h,
                  ),
                  HeightSpace(8.h),
                  ProfileItem(
                    title: "بيانات الملعب",
                    icon: Assets.imagesPngImageProfile,
                    onTap: () {
                      push(RoutesKeys.kAddFirstVenue, context);
                    },
                  ),
                  Container(
                    width: double.infinity,
                    color: Color(0xffDADEE3),
                    height: 1.h,
                  ),
                  HeightSpace(8.h),
                  ProfileItem(
                    title: "فترات الحجز",
                    icon: Assets.imagesPngImageProfile,
                    onTap: () {
                      push(RoutesKeys.kManagerBookingPeriods, context);
                    },
                  ),
                  Container(
                    width: double.infinity,
                    color: Color(0xffDADEE3),
                    height: 1.h,
                  ),
                  HeightSpace(8.h),
                  ProfileItem(
                    title: "الاشتراك",
                    icon: Assets.imagesPngImageProfile,
                    onTap: () {
                      push(RoutesKeys.kManagerSubscription, context);
                    },
                  ),
                  Container(
                    width: double.infinity,
                    color: Color(0xffDADEE3),
                    height: 1.h,
                  ),
                  HeightSpace(8.h),
                  ProfileItem(
                    title: canUseMonthlyBookings
                        ? "الحجز الشهري"
                        : "الحجز الشهري (مقفل)",
                    icon: Assets.imagesPngImageProfile,
                    onTap: () {
                      if (!canUseMonthlyBookings) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'هذه الباقة لا تسمح بإدارة الحجوزات الشهرية.',
                            ),
                          ),
                        );
                        return;
                      }

                      push(RoutesKeys.kMonthlyBookingView, context);
                    },
                  ),
                  Container(
                    width: double.infinity,
                    color: Color(0xffDADEE3),
                    height: 1.h,
                  ),
                  HeightSpace(8.h),
                ],
              );
            },
          ),
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
                            if (context.mounted) {
                              pushReplacement(RoutesKeys.kLogin, context);
                            }
                            SharedPreferenceUtil.putBool(
                                PrefKey.onboardingSeen, true);

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
