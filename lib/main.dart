import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/custom_success_toast.dart';
import 'package:goal_master_admin/core/components/keys_values.dart';
import 'package:goal_master_admin/core/components/preference_utility.dart';
import 'package:goal_master_admin/core/routing/app_router.dart';
import 'package:goal_master_admin/core/routing/appstart_state.dart';
import 'package:goal_master_admin/core/routing/routes_keys.dart';
import 'package:goal_master_admin/core/services/service_locator.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/features/booking/data/repo/booking_repo.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/add_customer_cubit/add_customer_cubit.dart';
import 'package:goal_master_admin/features/layout/presentation/manager/layout_cubit.dart';
import 'package:goal_master_admin/features/notification/data/repo/notifaction_repo.dart';
import 'package:goal_master_admin/features/notification/manager/notification_cubit/notification_cubit.dart';
import 'package:goal_master_admin/features/profail/data/repo/profile_repo_imp.dart';
import 'package:goal_master_admin/features/profail/presentation/manager/customer_cubit/customer_cubit.dart';
import 'package:goal_master_admin/features/profail/presentation/manager/profile_cubit/profile_cubit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oktoast/oktoast.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferenceUtil.getInstance();
  setupServiceLocator();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  String _mapStatusToRoute(AppStartStatus status) {
    switch (status) {
      case AppStartStatus.onboarding:
        return RoutesKeys.kOnboarding;
      case AppStartStatus.unauthenticated:
        return RoutesKeys.kLogin;
      case AppStartStatus.authenticated:
        return RoutesKeys.kHome;
      default:
        return RoutesKeys.kHome;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AppStartCubit(),
      child: BlocBuilder<AppStartCubit, AppStartState>(
        builder: (context, state) {
          if (state.status == AppStartStatus.checking) {
            return const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                backgroundColor: Colors.white,
                body: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          final initialRoute = _mapStatusToRoute(state.status);

          return MultiBlocProvider(
            providers: [
              // BlocProvider(
              //   create: (_) => WebSocketCubit('wss://socket.goalmasters.online')
              //     ..connect(),
              // ),
              BlocProvider(
                create: (_) => NotificationCubit(
                  notificationRepo: getIt<NotificationRepo>(),
                  userId: SharedPreferenceUtil.getInt(PrefKey.userId) ?? 0,
                  onVisualNotification: (notification) {
                    showCustomSuccessToast(notification.data.message);
                  },
                ),
              ),
              BlocProvider(
                create: (_) => AddCustomerCubit(getIt<BookingRepo>()),
              ),
              BlocProvider(create: (_) => LayoutCubit()),
              BlocProvider(
                create: (_) =>
                    ProfileCubit(getIt<ProfileRepoImp>())..getProfile(),
              ),
              BlocProvider(
                create: (_) =>
                    CustomerCubit(bookingRepo: getIt<ProfileRepoImp>()),
              ),
            ],
            child: ScreenUtilInit(
              designSize: const Size(390, 844),
              builder: (_, __) => Builder(
                builder: (context) {
                  // ✅ تشغيل WebSocket بعد أول frame
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    context.read<NotificationCubit>().startSocket();
                  });

                  return OKToast(
                    child: MaterialApp.router(
                      title: "Goal Master Admin",
                      theme: ThemeData(
                        colorScheme:
                            ColorScheme.fromSeed(seedColor: AppColors.primary),
                        useMaterial3: true,
                        textTheme: GoogleFonts.tajawalTextTheme(),
                        scaffoldBackgroundColor: Colors.white,
                      ),
                      debugShowCheckedModeBanner: false,
                      locale: const Locale('ar'),
                      supportedLocales: const [Locale('ar')],
                      localizationsDelegates: const [
                        GlobalMaterialLocalizations.delegate,
                        GlobalWidgetsLocalizations.delegate,
                        GlobalCupertinoLocalizations.delegate,
                      ],
                      routerConfig: AppRouter.createRouter(initialRoute),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
