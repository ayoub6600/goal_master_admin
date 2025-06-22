import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/button_app.dart';
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
import 'package:goal_master_admin/features/home/presentation/view/widgets/top_service_section.dart';
import 'package:goal_master_admin/features/notification/manager/notification_cubit/notification_cubit.dart';
import 'package:goal_master_admin/features/profail/presentation/manager/profile_cubit/profile_cubit.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:hexcolor/hexcolor.dart';

class HomeViewBody extends StatelessWidget {
  const HomeViewBody({super.key});

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
                        icon: Icon(
                          Icons.menu,
                          color: AppColors.black,
                        )),
                    WidthSpace(8.w),
                    BlocBuilder<ProfileCubit, ProfileState>(
                      builder: (context, state) {
                        print("state: $state");
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
                                style: AppTextStyles.font16SemiBold
                                    .copyWith(color: Color(0xff6D7580)),
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
                            "Error: ${state.error}",
                            style: TextStyle(color: Colors.red),
                          );
                        }
                        return Text("No Data Available");
                      },
                    ),
                    // Text(
                    //   "جوال ماستر",
                    //   textAlign: TextAlign.start,
                    //   style: AppTextStyles.font20Bold,
                    // ),
                    const Spacer(),
                    BlocBuilder<NotificationCubit, NotificationState>(
                      builder: (context, state) {
                        final cubit = context.read<NotificationCubit>();
                        final hasUnread = cubit.hasUnreadNotifications();
                        final unreadCount = cubit.unreadCount;

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
                // Row(
                //   children: [
                //     GestureDetector(
                //       onTap: () => push(RoutesKeys.kFilter, context),
                //       child: Container(
                //         width: 300.w,
                //         height: 40.h,
                //         padding: const EdgeInsets.all(8),
                //         decoration: BoxDecoration(
                //           color: AppColors.white,
                //           borderRadius: BorderRadius.circular(8.r),
                //           border: Border.all(
                //             width: 1,
                //             color: const Color(0xffDADEE3),
                //           ),
                //         ),
                //         child: Row(
                //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //           children: [
                //             Text("ابحث",
                //                 style: AppTextStyles.font14Medium
                //                     .copyWith(color: AppColors.fontColor)),
                //             Image.asset(Assets.imagesPngImageSearchNormal),
                //           ],
                //         ),
                //       ),
                //     ),
                //     WidthSpace(8.w),
                //     GestureDetector(
                //       onTap: () => push(RoutesKeys.kFilter, context),
                //       child: Image.asset(Assets.imagesPngImageFiltter),
                //     ),
                //   ],
                // ),
                // const HeightSpace(20),
                //  BannerCarouselScreen(),
                const HeightSpace(30),
                ButtonApp(
                  text: "اضافة حجز جديد",
                  onTap: () => push(RoutesKeys.kAddBooking, context),
                ),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: BlocBuilder<AnalysisCubit, AnalysisState>(
              builder: (context, state) {
                if (state is AnalysisLoading) {
                  return const ScimagLoading(itemCount: 4, crossAxisCount: 2);
                } else if (state is AnalysisError) {
                  return Center(child: Text('حدث خطأ: ${state.message}'));
                } else if (state is AnalysisLoaded) {
                  final stats = state.analysis.data.incomAndOtherStatistics;
                  final totalForgevin = state.analysis.data.totalForgevin;

                  // الحسابات
                  double totalCash = 0;
                  double totalOnline = 0;
                  for (var p in stats.todayPaidBy) {
                    final paid = double.tryParse(p.paidAmount) ?? 0;
                    if (p.type == 1) totalCash += paid;
                    if (p.type == 2) totalOnline += paid;
                  }

                  double totalPaid = 0;
                  double totalService = 0;
                  for (var item in stats.todayPaidAndDue) {
                    totalPaid += double.tryParse(item.paidAmount) ?? 0;
                    totalService += double.tryParse(item.serviceAmount) ?? 0;
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
                      color: HexColor('#2C5C30'), // أخضر أغمق
                    ),
                    ItemsShowAnalysisNew(
                      title: "إجمالي المدفوع نقدًا",
                      count: totalCash,
                      color: HexColor('#367C82'), // Teal داكن
                    ),
                    ItemsShowAnalysisNew(
                      title: "إجمالي المدفوع عبر الإنترنت",
                      count: totalOnline,
                      color: HexColor('#7A9D54'), // Olive
                    ),
                    ItemsShowAnalysisNew(
                      title: "إجمالي المدفوع اليوم",
                      count: totalPaid,
                      color: Colors.teal,
                    ),
                    ItemsShowAnalysisNew(
                      title: "إجمالي قيمة الخدمات",
                      count: totalService,
                      color: HexColor('#D4AC2B'), // Mustard
                    ),
                  ];

                  if (cards.isEmpty) return const SizedBox.shrink();

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
                        //  const SizedBox(height: 12),
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
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeightSpace(20),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    "إحصائيات الحجوزات حسب الحالة",
                    style: AppTextStyles.font18Bold
                        .copyWith(color: AppColors.black),
                  ),
                ),
                HeightSpace(10),
                AnalysisView(),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: BlocBuilder<AnalysisCubit, AnalysisState>(
              builder: (context, state) {
                if (state is AnalysisLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is AnalysisError) {
                  return Center(child: Text('حدث خطأ: ${state.message}'));
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
