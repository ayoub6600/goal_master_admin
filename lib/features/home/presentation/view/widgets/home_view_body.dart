import 'package:flutter/material.dart';
import 'package:goal_master_admin/core/components/button_app.dart';
import 'package:goal_master_admin/core/components/custom_drop_down.dart';
import 'package:goal_master_admin/core/components/custom_text_field/custom_app_form_text_field.dart';
import 'package:goal_master_admin/core/components/page_wrapper.dart';
import 'package:goal_master_admin/core/routing/route_utils.dart';
import 'package:goal_master_admin/core/routing/routes_keys.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/assets.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/home/presentation/manager/analysis_cubit/analysis_cubit.dart';
import 'package:goal_master_admin/features/home/presentation/view/home_view.dart';
import 'package:goal_master_admin/features/home/presentation/view/widgets/arabic_bar_chart.dart';
import 'package:goal_master_admin/features/home/presentation/view/widgets/status_tabs_home.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeViewBody extends StatelessWidget {
  const HomeViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      allowBack: false,
      title: "لوحة التحكم",
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeightSpace(20),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      push(RoutesKeys.kFilter, context);
                    },
                    child: Container(
                        width: 300.w,
                        height: 40.h,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              width: 1,
                              color: Color(0xffDADEE3),
                            )),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "ابحث",
                                style: AppTextStyles.font14Medium
                                    .copyWith(color: AppColors.fontColor),
                              ),
                              Image.asset(
                                Assets.imagesPngImageSearchNormal,
                              )
                            ])),
                  ),
                  WidthSpace(8.w),
                  GestureDetector(
                    onTap: () {
                      push(RoutesKeys.kFilter, context);
                    },
                    child: Image.asset(
                      Assets.imagesPngImageFiltter,
                      //   color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              HeightSpace(20),
              ButtonApp(
                  text: "اضافة حجز جديد",
                  onTap: () {
                    push(RoutesKeys.kAddBooking, context);
                  }),
              HeightSpace(20),
              SizedBox(height: 300.h, child: AnalysisView()),
              Text(
                " احصائيات الخدمات حجز اليوم",
                style: AppTextStyles.font18Bold.copyWith(
                  color: AppColors.primary,
                ),
              ),
              HeightSpace(20),
              BlocBuilder<AnalysisCubit, AnalysisState>(
                builder: (context, state) {
                  if (state is AnalysisLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is AnalysisError) {
                    return Center(child: Text('Error: ${state.message}'));
                  } else if (state is AnalysisLoaded) {
                    final data = state.analysis.data;
                    final todayBookings = data.bookingStatus.todayBooking ?? [];
                    final topServices = data?.topService ?? [];
                    final paidBy =
                        data?.incomAndOtherStatistics?.todayPaidBy ?? [];
                    final totalBookings =
                        data?.bookingStatus.totalBooking ?? [];

                    return GestureDetector(
                      onTap: () {
                        print(
                            "------>${todayBookings[0].statusText} ${todayBookings[0].serviceCount} ");
                      },
                      child: Container(
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height * 0.28,
                        decoration: BoxDecoration(
                          color: Color(0xfff0faf1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            StatusTabsHome(
                              todayBooking: todayBookings,
                              totalBookings: totalBookings,
                            ),
                          ],
                        ),
                      ),
                    );

                    // ListView(
                    //   padding: const EdgeInsets.all(16),
                    //   children: [
                    //     const Text('📅 Today\'s Bookings',
                    //         style: TextStyle(
                    //             fontSize: 18, fontWeight: FontWeight.bold)),
                    //     ...todayBookings.map((e) => ListTile(
                    //           title: Text(e.statusText ?? ''),
                    //           trailing: Text(e.serviceCount.toString()),
                    //         )),
                    //     const SizedBox(height: 16),
                    //     const Text('🔥 Top Services',
                    //         style: TextStyle(
                    //             fontSize: 18, fontWeight: FontWeight.bold)),
                    //     ...topServices.map((e) => ListTile(
                    //           title: Text(e.title ?? ''),
                    //           trailing: Text('Count: ${e.serviceCount}'),
                    //         )),
                    //     const SizedBox(height: 16),
                    //     const Text('💰 Payments by Method',
                    //         style: TextStyle(
                    //             fontSize: 18, fontWeight: FontWeight.bold)),
                    //     ...paidBy.map((e) => ListTile(
                    //           title: Text(e.paymentBy ?? ''),
                    //           trailing: Text('${e.paidAmount} ر.س'),
                    //         )),
                    //   ],
                    // );
                  }
                  return const SizedBox.shrink();
                },
              ),
              HeightSpace(20),
              Text(
                "إحصائيات الدخل اليومي والإحصائيات الأخرى",
                style: AppTextStyles.font18Bold.copyWith(
                  color: AppColors.black,
                ),
              ),
              HeightSpace(20),
              ArabicBarChart(),
              HeightSpace(20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                // height: MediaQuery.of(context).size.height * 0.28,
                decoration: BoxDecoration(
                  color: Color(0xfff0faf1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "أفضل خدمات الحجز",
                      style: AppTextStyles.font18Bold.copyWith(
                        color: AppColors.black,
                      ),
                    ),
                    Divider(
                      thickness: 1,
                      color: AppColors.lightGrey,
                    ),
                    HeightSpace(20),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.primary,
                        ),
                        WidthSpace(20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "ملعب سداسي",
                                style: AppTextStyles.font16Medium.copyWith(),
                              ),
                              HeightSpace(4),
                              Text(
                                "أفضل خدماتنا",
                                style: AppTextStyles.font16Medium.copyWith(
                                  color: AppColors.lightGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "7",
                          style: AppTextStyles.font16Medium.copyWith(
                            color: AppColors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              HeightSpace(20),
            ],
          ),
        ),
      ),
    );
  }
}
