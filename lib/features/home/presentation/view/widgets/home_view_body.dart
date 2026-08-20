import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/button_app.dart';
import 'package:goal_master_admin/core/components/error_widgets.dart';
import 'package:goal_master_admin/core/components/keys_values.dart';
import 'package:goal_master_admin/core/components/preference_utility.dart';
import 'package:goal_master_admin/core/routing/route_utils.dart';
import 'package:goal_master_admin/core/routing/routes_keys.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/assets.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/home/presentation/manager/analysis_cubit/analysis_cubit.dart';
import 'package:goal_master_admin/features/home/presentation/view/widgets/analysis_view.dart';
import 'package:goal_master_admin/features/home/presentation/view/widgets/app_drawer.dart';
import 'package:goal_master_admin/features/home/presentation/view/widgets/items_show_analysis_new.dart';
import 'package:goal_master_admin/features/home/presentation/view/widgets/manager_setup_pending_card.dart';
import 'package:goal_master_admin/features/home/presentation/view/widgets/top_service_section.dart';
import 'package:goal_master_admin/features/notification/manager/notification_cubit/notification_cubit.dart';
import 'package:goal_master_admin/features/profail/presentation/manager/profile_cubit/profile_cubit.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:hexcolor/hexcolor.dart';

class HomeViewBody extends StatelessWidget {
  const HomeViewBody({super.key});

  void _showSetupRoadmap(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'خطة تفعيل مدير الملعب',
                style: AppTextStyles.font18Bold,
              ),
              HeightSpace(14.h),
              Text(
                'الحساب تم إنشاؤه بنجاح، لكنه ما زال في مرحلة التأسيس.',
                style: AppTextStyles.font14Medium.copyWith(
                  color: AppColors.fontColor,
                  height: 1.5,
                ),
              ),
              HeightSpace(12.h),
              Text(
                '1. حدّث بيانات الحساب والمدير.',
                style: AppTextStyles.font14Medium,
              ),
              HeightSpace(8.h),
              Text(
                '2. افتح المحفظة وراجع حالة الباقة والتجربة.',
                style: AppTextStyles.font14Medium,
              ),
              HeightSpace(8.h),
              Text(
                '3. ابدأ ببيانات الفرع، ثم الفئة، ثم الخدمة، ثم الموظف.',
                style: AppTextStyles.font14Medium,
              ),
              HeightSpace(20.h),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      drawer: const AppDrawer(),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                HeightSpace(30.h),
                Row(
                  children: [
                    WidthSpace(8.w),
                    IconButton(
                      onPressed: () => scaffoldKey.currentState?.openDrawer(),
                      icon: Icon(Icons.menu, color: AppColors.black),
                    ),
                    WidthSpace(8.w),
                    BlocBuilder<ProfileCubit, ProfileState>(
                      builder: (context, state) {
                        if (state is ProfileLoading) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                SharedPreferenceUtil.getString(
                                    PrefKey.fullName),
                                style: AppTextStyles.font16SemiBold,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              HeightSpace(8.h),
                              Text(
                                SharedPreferenceUtil.getString(PrefKey.phone),
                                style: AppTextStyles.font16SemiBold.copyWith(
                                  color: const Color(0xff6D7580),
                                ),
                              ),
                            ],
                          );
                        } else if (state is ProfileLoaded) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.user.name ?? "No Name",
                                style: AppTextStyles.font18Bold,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          );
                        } else if (state is ProfileError) {
                          return Text(
                            "....",
                            style: const TextStyle(color: Colors.red),
                          );
                        }
                        return const Text("No Data Available");
                      },
                    ),
                    const Spacer(),
                    BlocConsumer<NotificationCubit, NotificationState>(
                      listener: (context, state) {
                        print('[🔔 Listener] Notification state: $state');

                        if (state is NotificationLoadSuccess) {
                          print(
                              '[🔔 Listener] Unread count: ${state.unreadCount}');
                        } else if (state is NotificationUnreadUpdated) {
                          print(
                              '[🔔 Listener] Updated unread count: ${state.unreadCount}');
                        }
                      },
                      builder: (context, state) {
                        print(
                            '[🔁 Builder] Notification state: $state'); // ✅ هيتطبع كل 15 ثانية لما يحصل poll

                        int unreadCount = 0;

                        if (state is NotificationLoadSuccess) {
                          unreadCount = state.unreadCount;
                        } else if (state is NotificationUnreadUpdated) {
                          unreadCount = state.unreadCount;
                        }

                        final hasUnread = unreadCount > 0;

                        return GestureDetector(
                          onTap: () => push(RoutesKeys.kNotification, context),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Image.asset(
                                Assets.imagesPngImageNotification,
                                width: 24.w,
                                height: 24.h,
                              ),
                              if (hasUnread)
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: Container(
                                    padding: EdgeInsets.all(4.r),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: BoxConstraints(
                                      minWidth: 16.w,
                                      minHeight: 16.h,
                                    ),
                                    child: Center(
                                      child: Text(
                                        unreadCount > 9
                                            ? '9+'
                                            : unreadCount.toString(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const HeightSpace(30),
                BlocBuilder<ProfileCubit, ProfileState>(
                  builder: (context, state) {
                    if (state is! ProfileLoaded) {
                      return Column(
                        children: [
                          ButtonApp(
                            text: "اضافة حجز جديد",
                            onTap: () => push(RoutesKeys.kAddBooking, context),
                          ),
                          const HeightSpace(16),
                        ],
                      );
                    }

                    final user = state.user;
                    final needsVenueSetup = user.needsVenueSetup;
                    final planName =
                        user.currentSubscription?.planName?.trim().isNotEmpty ==
                                true
                            ? user.currentSubscription!.planName!
                            : 'بدون باقة محددة';
                    final primaryActionRoute = needsVenueSetup
                        ? (user.needsSubscriptionPaymentNow
                            ? RoutesKeys.kManagerWallet
                            : RoutesKeys.kAddFirstVenue)
                        : RoutesKeys.kAddBooking;
                    final primaryActionLabel = needsVenueSetup
                        ? (user.needsSubscriptionPaymentNow
                            ? 'تفعيل الاشتراك والدفع'
                            : user.nextSetupStepLabel)
                        : 'اضافة حجز جديد';

                    return Column(
                      children: [
                        ButtonApp(
                          text: primaryActionLabel,
                          onTap: () => push(primaryActionRoute, context),
                        ),
                        const HeightSpace(16),
                        if (needsVenueSetup) ...[
                          ManagerSetupPendingCard(
                            user: user,
                            onPrimaryTap: () => push(
                              user.needsSubscriptionPaymentNow
                                  ? RoutesKeys.kManagerWallet
                                  : RoutesKeys.kAddFirstVenue,
                              context,
                            ),
                            onSecondaryTap: () => _showSetupRoadmap(context),
                          ),
                          const HeightSpace(16),
                        ],
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(14.w),
                          decoration: BoxDecoration(
                            color: const Color(0xffF6F9F3),
                            borderRadius: BorderRadius.circular(18.r),
                            border: Border.all(color: const Color(0xffD9E8D2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                needsVenueSetup
                                    ? 'اشتراك المدير الجديد'
                                    : 'إدارة الاشتراك',
                                style: AppTextStyles.font16Bold,
                              ),
                              HeightSpace(8.h),
                              Text(
                                'الباقة الحالية: $planName',
                                style: AppTextStyles.font14Medium.copyWith(
                                  color: AppColors.fontColor,
                                ),
                              ),
                              HeightSpace(8.h),
                              Text(
                                user.canUseReports
                                    ? 'الإحصائيات والتقارير مفعّلة.'
                                    : 'الإحصائيات والتقارير مقفلة حسب الباقة الحالية.',
                                style: AppTextStyles.font14Medium.copyWith(
                                  color: user.canUseReports
                                      ? const Color(0xff2E7D32)
                                      : Colors.redAccent,
                                ),
                              ),
                              HeightSpace(4.h),
                              Text(
                                user.canUseMonthlyBookings
                                    ? 'الحجز الشهري متاح.'
                                    : 'الحجز الشهري غير متاح.',
                                style: AppTextStyles.font14Medium.copyWith(
                                  color: user.canUseMonthlyBookings
                                      ? const Color(0xff2E7D32)
                                      : Colors.redAccent,
                                ),
                              ),
                              HeightSpace(4.h),
                              Text(
                                user.isTrialingSubscription
                                    ? 'الاشتراك في وضع تجريبي الآن.'
                                    : user.needsSubscriptionPaymentNow
                                        ? 'الاشتراك يحتاج دفع أو تفعيل من المحفظة.'
                                        : 'الاشتراك مفعل ومدفوع.',
                                style: AppTextStyles.font14Medium.copyWith(
                                  color: user.isTrialingSubscription
                                      ? const Color(0xff9C640C)
                                      : user.needsSubscriptionPaymentNow
                                          ? Colors.redAccent
                                          : const Color(0xff2E7D32),
                                ),
                              ),
                              if (needsVenueSetup) ...[
                                HeightSpace(4.h),
                                Text(
                                  'المرحلة التالية: ${user.nextSetupStepLabel}',
                                  style: AppTextStyles.font14Medium.copyWith(
                                    color: const Color(0xff8A5A00),
                                  ),
                                ),
                              ],
                              HeightSpace(10.h),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: () => push(
                                    RoutesKeys.kManagerSubscription,
                                    context,
                                  ),
                                  child: Text(
                                    'تجديد الاشتراك',
                                    style: AppTextStyles.font14Bold.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: BlocBuilder<ProfileCubit, ProfileState>(
              builder: (context, profileState) {
                if (profileState is ProfileLoaded &&
                    profileState.user.needsVenueSetup) {
                  return Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
                    child: Container(
                      padding: EdgeInsets.all(18.w),
                      decoration: BoxDecoration(
                        color: const Color(0xffFCFCF6),
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(color: const Color(0xffE8E3C5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'هذه الواجهة الآن مخصصة لتأسيس مدير الملعب',
                            style: AppTextStyles.font16Bold,
                          ),
                          HeightSpace(10.h),
                          Text(
                            'مدير الملعب الجديد لا يملك ملعبًا أو فرعًا بعد، لذلك غيّرنا الصفحة لتكون أوضح ومنطقية أكثر إلى أن نبني تدفق إنشاء الملعب والمحفظة بالكامل.',
                            style: AppTextStyles.font14Medium.copyWith(
                              color: AppColors.fontColor,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (profileState is ProfileLoaded &&
                    !profileState.user.canUseReports) {
                  return const AppErrorView(
                    title: 'التقارير غير متاحة',
                    message:
                        'الباقة الحالية لا تسمح بعرض لوحة الإحصائيات داخل تطبيق مدير الملعب.',
                    icon: Icons.lock_outline,
                  );
                }

                return BlocBuilder<AnalysisCubit, AnalysisState>(
                  builder: (context, state) {
                    if (state is AnalysisLoading) {
                      return const ScimagLoading(
                          itemCount: 4, crossAxisCount: 2);
                    } else if (state is AnalysisError) {
                      return AppErrorView(
                        message: state.message,
                      );
                    } else if (state is AnalysisLoaded) {
                      final stats = state.analysis.data.incomAndOtherStatistics;
                      final totalForgevin = state.analysis.data.totalForgevin;

                      // ✅ بعد التعديل: إجمالي الدخل/المستحق doubles مباشرة من الموديل
                      final double incomeTotal =
                          state.analysis.data.totalIncome;
                      final double dueTotal = state.analysis.data.totalDue;

                      // حسابات الكاش والأونلاين من todayPaidBy
                      double totalCash = 0;
                      double totalOnline = 0;
                      for (var p in stats.todayPaidBy) {
                        final paid = double.tryParse(p.paidAmount) ?? 0;
                        if (p.type == 1) totalCash += paid; // نقدًا
                        if (p.type == 2 || p.type == 4) {
                          totalOnline += paid; // أونلاين
                        }
                      }

                      // إجمالي المدفوع والخدمات من todayPaidAndDue
                      for (var item in stats.todayPaidAndDue) {
                        double.tryParse(item.paidAmount);
                        double.tryParse(item.serviceAmount);
                      }

                      final List<Widget> cards = [
                        ItemsShowAnalysisNew(
                          title: "كمية المسامح كريم اليومية",
                          count: totalForgevin.dailyTotal,
                          color: HexColor('#418946'),
                        ),
                        ItemsShowAnalysisNew(
                          title: "كمية المسامح كريم الشاملة",
                          count: totalForgevin.total,
                          color: HexColor('#2C5C30'),
                        ),
                        ItemsShowAnalysisNew(
                          title: "إجمالي المدفوع نقدًا",
                          count: totalCash,
                          color: HexColor('#367C82'),
                        ),
                        ItemsShowAnalysisNew(
                          title: "إجمالي المدفوع عبر الإنترنت",
                          count: totalOnline,
                          color: HexColor('#7A9D54'),
                        ),
                        ItemsShowAnalysisNew(
                          title: "إجمالي الدخل",
                          count: incomeTotal, // ✅ مباشرة
                          color: HexColor('#9C640C'),
                        ),
                        ItemsShowAnalysisNew(
                          title: "إجمالي المستحق",
                          count: dueTotal, // ✅ مباشرة
                          color: HexColor('#BA4A00'),
                        ),
                      ];

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "الإحصائيات المالية",
                              style: AppTextStyles.font18Bold
                                  .copyWith(color: AppColors.black),
                            ),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: cards.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1.6,
                              ),
                              itemBuilder: (context, index) => cards[index],
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: BlocBuilder<ProfileCubit, ProfileState>(
              builder: (context, profileState) {
                if (profileState is ProfileLoaded &&
                    !profileState.user.canUseReports) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HeightSpace(20),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Text(
                        "إحصائيات الحجوزات حسب الحالة",
                        style: AppTextStyles.font18Bold
                            .copyWith(color: AppColors.black),
                      ),
                    ),
                    HeightSpace(10),
                    const AnalysisView(),
                  ],
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: BlocBuilder<ProfileCubit, ProfileState>(
              builder: (context, profileState) {
                if (profileState is ProfileLoaded &&
                    !profileState.user.canUseReports) {
                  return const SizedBox.shrink();
                }

                return BlocBuilder<AnalysisCubit, AnalysisState>(
                  builder: (context, state) {
                    if (state is AnalysisLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is AnalysisError) {
                      return AppErrorView(
                        message: state.message,
                      );
                    } else if (state is AnalysisLoaded) {
                      final topServices = state.analysis.data.topService;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const HeightSpace(10),
                          TopServiceSection(topServices: topServices),
                          const HeightSpace(100),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DrawerButton extends StatelessWidget {
  final VoidCallback onTap;
  const DrawerButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu),
      onPressed: onTap,
    );
  }
}

class ScimagLoading extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double spacing;
  final double aspectRatio;

  const ScimagLoading({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.spacing = 12,
    this.aspectRatio = 1.2,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.r),
      child: GridView.builder(
        itemCount: itemCount,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing.w,
          mainAxisSpacing: spacing.h,
          childAspectRatio: aspectRatio,
        ),
        itemBuilder: (context, index) => Shimmer(
          duration: const Duration(seconds: 2),
          interval: const Duration(seconds: 0),
          color: Colors.white,
          colorOpacity: 0,
          enabled: true,
          direction: const ShimmerDirection.fromLTRB(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
        ),
      ),
    );
  }
}
