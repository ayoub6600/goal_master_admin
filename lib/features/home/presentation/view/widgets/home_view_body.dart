import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/button_app.dart';
import 'package:goal_master_admin/core/components/page_wrapper.dart';
import 'package:goal_master_admin/core/routing/route_utils.dart';
import 'package:goal_master_admin/core/routing/routes_keys.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/assets.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/home/presentation/manager/analysis_cubit/analysis_cubit.dart';
import 'package:goal_master_admin/features/home/presentation/view/widgets/analysis_view.dart';
import 'package:goal_master_admin/features/home/presentation/view/widgets/stat_card.dart';
import 'package:goal_master_admin/features/home/presentation/view/widgets/top_service_section.dart';
import 'package:goal_master_admin/features/profail/presentation/view/widgets/profile_item.dart';

class HomeViewBody extends StatelessWidget {
  const HomeViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      drawer: const AppDrawer(),
      body: PageWrapper(
        allowBack: false,
        title: "لوحة التحكم",
        leading: DrawerButton(onTap: () {
          scaffoldKey.currentState?.openDrawer();
        }),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  HeightSpace(20),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => push(RoutesKeys.kFilter, context),
                        child: Container(
                          width: 300.w,
                          height: 40.h,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              width: 1,
                              color: const Color(0xffDADEE3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("ابحث",
                                  style: AppTextStyles.font14Medium
                                      .copyWith(color: AppColors.fontColor)),
                              Image.asset(Assets.imagesPngImageSearchNormal),
                            ],
                          ),
                        ),
                      ),
                      WidthSpace(8.w),
                      GestureDetector(
                        onTap: () => push(RoutesKeys.kFilter, context),
                        child: Image.asset(Assets.imagesPngImageFiltter),
                      ),
                    ],
                  ),
                  HeightSpace(20),
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
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is AnalysisError) {
                    return Center(child: Text('حدث خطأ: ${state.message}'));
                  } else if (state is AnalysisLoaded) {
                    final topServices = state.analysis.data.topService;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HeightSpace(20),
                        TopServiceSection(topServices: topServices),
                        HeightSpace(2),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
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
                    final incomeStats =
                        state.analysis.data.incomAndOtherStatistics;
                    final totalForgevin = state.analysis.data.totalForgevin;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HeightSpace(20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            "الإحصائيات المالية",
                            style: AppTextStyles.font18Bold
                                .copyWith(color: AppColors.black),
                          ),
                        ),
                        HeightSpace(16),
                        SizedBox(
                          height: 150,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              StatCard(
                                title: "إجمالي اليوم",
                                value:
                                    "${incomeStats.totalAllowedAmountToday} ر.س",
                                icon: Icons.attach_money_rounded,
                                color: Colors.greenAccent.shade100,
                              ),
                              StatCard(
                                title: "غرامات اليوم",
                                value: "${totalForgevin.dailyTotal} ر.س",
                                icon: Icons.warning_amber_rounded,
                                color: Colors.orange.shade100,
                              ),
                              StatCard(
                                title: "إجمالي الغرامات",
                                value: "${totalForgevin.total} ر.س",
                                icon: Icons.account_balance_wallet_outlined,
                                color: Colors.red.shade100,
                              ),
                            ],
                          ),
                        ),
                        HeightSpace(16),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            SliverToBoxAdapter(
              child: AnalysisView(),
            ),
          ],
        ),
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
        ],
      ),
    );
  }
}
