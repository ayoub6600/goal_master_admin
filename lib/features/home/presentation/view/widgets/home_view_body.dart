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
import 'package:goal_master_admin/features/home/presentation/view/widgets/top_service_section.dart';

class HomeViewBody extends StatelessWidget {
  const HomeViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      allowBack: false,
      title: "لوحة التحكم",
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
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      //  padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: Colors.black87),
          HeightSpace(8),
          Text(
            value,
            style: AppTextStyles.font16Bold.copyWith(color: Colors.black),
            textAlign: TextAlign.center,
          ),
          HeightSpace(6),
          Text(
            title,
            style: AppTextStyles.font12Medium.copyWith(color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
