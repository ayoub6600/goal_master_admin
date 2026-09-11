import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/custom_success_toast.dart';
import 'package:goal_master_admin/core/components/keys_values.dart';
import 'package:goal_master_admin/core/components/preference_utility.dart'
    show SharedPreferenceUtil;
import 'package:goal_master_admin/core/services/service_locator.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/assets.dart';
import 'package:goal_master_admin/features/booking/data/repo/booking_repo_imp.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/booking_cubit/booking_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/view/booking_view.dart';
import 'package:goal_master_admin/features/home/data/repo/analysis_repo_imp.dart';
import 'package:goal_master_admin/features/home/presentation/manager/analysis_cubit/analysis_cubit.dart';
import 'package:goal_master_admin/features/home/presentation/manager/banner_cubit/banner_cubit.dart';
import 'package:goal_master_admin/features/home/presentation/view/home_view.dart';
import 'package:goal_master_admin/features/layout/presentation/manager/layout_cubit.dart';
import 'package:goal_master_admin/features/layout/presentation/manager/layout_state.dart';
import 'package:goal_master_admin/features/layout/presentation/view/widget/home_bottom_nav_bar.dart';
import 'package:goal_master_admin/features/notification/data/repo/notifaction_repo.dart';
import 'package:goal_master_admin/features/notification/manager/notification_cubit/notification_cubit.dart';
import 'package:goal_master_admin/features/profail/data/repo/profile_repo_imp.dart';
import 'package:goal_master_admin/features/profail/presentation/manager/customer_cubit/customer_cubit.dart';
import 'package:goal_master_admin/features/profail/presentation/view/profile_view.dart';
import 'package:oktoast/oktoast.dart';

class HomeLayoutView extends StatefulWidget {
  const HomeLayoutView({super.key});

  @override
  State<HomeLayoutView> createState() => _HomeLayoutViewState();
}

class _HomeLayoutViewState extends State<HomeLayoutView> {
  late LayoutCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = context.read<LayoutCubit>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<LayoutCubit, LayoutState>(
        builder: (context, state) {
          return Stack(
            children: [
              if (state.activeScreen == NavBarElement.home)
                //HomeView(),
                //BannerCubitCubit/
                // ProfileCubit deliberately NOT provided here — HomeView
                // reads the single root ProfileCubit from main.dart instead.
                // A second, tab-local instance used to exist here, so a
                // venue-setup save (which only ever refreshes the root
                // instance) never reached Home: switching to this tab
                // rebuilt a cubit that fetched once and never again, so the
                // onboarding card stayed stale until a full app restart.
                MultiBlocProvider(
                  providers: [
                    // BlocProvider(
                    //   create: (_) => NotificationCubit(
                    //     notificationRepo: getIt<NotificationRepo>(),
                    //     userId:
                    //         SharedPreferenceUtil.getInt(PrefKey.userId) ?? 0,
                    //     onVisualNotification: (notification) {
                    //       showCustomSuccessToast(notification.data.message);
                    //     },
                    //   ),
                    // ),
                    BlocProvider(
                      create: (context) => BannerCubitCubit(
                        getIt<AnalysisRepoImp>(),
                      )..getBanner(),
                    ),
                    BlocProvider(
                      create: (context) => AnalysisCubit(
                        getIt<AnalysisRepoImp>(),
                      )..getAnalysis(),
                    ),
                  ],
                  child: const HomeView(),
                ),
              if (state.activeScreen == NavBarElement.booking)
                MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create: (context) => BookingCubit(
                        getIt<BookingRepoImp>(),
                      )..filterBooking(),
                    ),
                    //CustomerCubit
                    BlocProvider(
                      create: (context) => CustomerCubit(
                        bookingRepo: getIt<ProfileRepoImp>(),
                      ),
                    ),
                  ],
                  child: BookingView(),
                ),
              if (state.activeScreen == NavBarElement.profile) ProfileView(),
            ],
          );
        },
      ),

      // زر عائم في المنتصف
      floatingActionButton: BlocBuilder<LayoutCubit, LayoutState>(
        builder: (context, state) {
          return SizedBox(
            width: 80.62.w,
            height: 80.62.h,
            child: FloatingActionButton(
              backgroundColor: Color(0xffF4F6F9),
              shape: const CircleBorder(),
              elevation: 5,
              onPressed: () => cubit.changeSelectedNavBar(NavBarElement.home),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    Assets.imagesPngImageHome,
                    color: state.activeScreen == NavBarElement.home
                        ? AppColors.primary
                        : Colors.grey,
                  ),
                  Text(
                    "الرئيسية",
                    style: TextStyle(
                      color: state.activeScreen == NavBarElement.home
                          ? AppColors.primary
                          : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),

      // تحديد موقع الزر العائم
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // شريط التنقل السفلي مع قص الزر العائم
      bottomNavigationBar: BlocBuilder<LayoutCubit, LayoutState>(
        builder: (context, state) {
          return HomeBottomNavBar(
            changeElement: (screen) => cubit.changeSelectedNavBar(screen),
            activeElement: state.activeScreen,
          );
        },
      ),
    );
  }
}
