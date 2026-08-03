import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
import 'package:oktoast/oktoast.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'core/components/no_internet_page.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('🔥 Caught Flutter error: ${details.exception}');
  };

  await SharedPreferenceUtil.getInstance();
  setupServiceLocator();

  // Zone للحماية من الكراش الصامت
  await runZonedGuarded(() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await requestNotificationPermission();
        await _initializeNotifications();
      }
    } catch (e, s) {
      print("🔥 Notification init error: $e\n$s");
    }

    // طباعة البيانات المحفوظة للتحقق (مفيد للاختبار)
    AppStartCubit.debugPrintSavedData();

    runApp(const MyApp());
  }, (e, s) {
    print("🔥 Zone error: $e\n$s");
  });
}

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   await SharedPreferenceUtil.getInstance();
//   setupServiceLocator();
//   await requestNotificationPermission(); // ✅ طلب الصلاحيات
//   await _initializeNotifications(); // ✅ iOS + Android init

//   // طباعة البيانات المحفوظة للتحقق (مفيد للاختبار)
//   AppStartCubit.debugPrintSavedData();

//   runApp(const MyApp());
// }

Future<void> _initializeNotifications() async {
  // ANDROID init
  const AndroidInitializationSettings androidInitSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  // iOS init (Darwin)
  const DarwinInitializationSettings iosInitSettings =
      DarwinInitializationSettings(
    requestAlertPermission: false, // هنطلبها لاحقًا بدالة منفصلة
    requestBadgePermission: false,
    requestSoundPermission: false,
  );

  // لازم تضم الاثنين معًا
  const InitializationSettings initSettings = InitializationSettings(
    android: androidInitSettings,
    iOS: iosInitSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    // مهم لـ iOS عشان لما يضغط على الإشعار نعرف نوجّه
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      final payload = response.payload;
      if (payload == RoutesKeys.kNotification) {
        // افتح صفحة الإشعارات
      }
    },
  );
}

Future<void> requestNotificationPermission() async {
  // Android 13+ إذن الإشعارات
  final status = await Permission.notification.status;
  if (!status.isGranted) {
    await Permission.notification.request();
  }

  // iOS: لازم من خلال البلجن نفسه
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final ValueNotifier<bool> hasInternet = ValueNotifier(true);

  // مراقبة الاتصال بالإنترنت
  static void startConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((result) async {
      if (result == ConnectivityResult.none) {
        hasInternet.value = false;
      } else {
        hasInternet.value = true;
      }
    });
  }

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
    // بدء مراقبة الاتصال
    startConnectivityListener();
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

          return ValueListenableBuilder<bool>(
            valueListenable: MyApp.hasInternet,
            builder: (context, hasInternet, _) {
              if (!hasInternet) {
                return NoInternetPage(
                  onRetry: () async {
                    final result = await Connectivity().checkConnectivity();
                    if (result != ConnectivityResult.none) {
                      MyApp.hasInternet.value = true;
                    }
                  },
                );
              }
              return MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) => NotificationCubit(
                      notificationRepo: getIt<NotificationRepo>(),
                      userId: SharedPreferenceUtil.getInt(PrefKey.userId),
                      onVisualNotification: (notification) async {
                        // ✅ اجعل NotificationDetails تشمل iOS + Android
                        const androidDetails = AndroidNotificationDetails(
                          'goal_channel_id',
                          'Goal Notifications',
                          channelDescription:
                              'Notifications from Goal Master Admin',
                          importance: Importance.max,
                          priority: Priority.high,
                          playSound: true,
                          icon: '@mipmap/ic_launcher',
                          styleInformation: BigPictureStyleInformation(
                            DrawableResourceAndroidBitmap('logo_goal'),
                            largeIcon:
                                DrawableResourceAndroidBitmap('logo_goal'),
                            contentTitle: '📣 مدير الملعب',
                            summaryText: null,
                          ),
                        );

                        const iosDetails = DarwinNotificationDetails(
                          presentAlert: true,
                          presentBadge: true,
                          presentSound: true,
                          threadIdentifier: 'admin_notifications',
                        );

                        const details = NotificationDetails(
                          android: androidDetails,
                          iOS: iosDetails,
                        );

                        await flutterLocalNotificationsPlugin.show(
                          0,
                          '📣 مدير الملعب',
                          notification.data.message,
                          details,
                          payload: RoutesKeys.kNotification,
                        );
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
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        context.read<NotificationCubit>().startSocket();
                      });
                      return OKToast(
                        child: MaterialApp.router(
                          title: "Goal Master Admin",
                          theme: ThemeData(
                            colorScheme: ColorScheme.fromSeed(
                                seedColor: AppColors.primary),
                            useMaterial3: true,
                            textTheme: const TextTheme(),
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
          );
        },
      ),
    );
  }
}
