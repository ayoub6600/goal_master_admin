import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/button_app.dart';
import 'package:goal_master_admin/core/routing/route_utils.dart';
import 'package:goal_master_admin/core/routing/routes_keys.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/assets.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/home/presentation/manager/analysis_cubit/analysis_cubit.dart';
import 'package:goal_master_admin/features/home/presentation/view/widgets/analysis_view.dart';
import 'package:goal_master_admin/features/home/presentation/view/widgets/app_drawer.dart';
import 'package:goal_master_admin/features/home/presentation/view/widgets/top_service_section.dart';

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
                    IconButton(
                        onPressed: () => scaffoldKey.currentState?.openDrawer(),
                        icon: const Icon(Icons.menu)),
                    WidthSpace(8.w),
                    CircleAvatar(
                      radius: 24.r,
                      backgroundImage: const AssetImage(
                        Assets.imagesPngImageLogo,
                      ),
                      backgroundColor: AppColors.primary,
                    ),
                    WidthSpace(8.w),
                    Text(
                      "Goal Master",
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => push(RoutesKeys.kNotification, context),
                      child: Image.asset(
                        Assets.imagesPngImageNotification,
                        width: 24.w,
                        height: 24.h,
                      ),
                    ),
                  ],
                ),
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
                      const HeightSpace(10),
                      TopServiceSection(topServices: topServices),
                      const HeightSpace(2),
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
                      const HeightSpace(10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          "الإحصائيات المالية",
                          style: AppTextStyles.font18Bold
                              .copyWith(color: AppColors.black),
                        ),
                      ),
                      const HeightSpace(8),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          const SliverToBoxAdapter(
            child: AnalysisView(),
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
