import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goal_master_admin/core/components/build_page_with_default_transition.dart';
import 'package:goal_master_admin/core/routing/routes_keys.dart'
    show RoutesKeys;
import 'package:goal_master_admin/core/services/service_locator.dart';
import 'package:goal_master_admin/features/auth/data/repo/auth_repo_imp.dart';
import 'package:goal_master_admin/features/auth/presentation/manager/login_cubit/login_cubit.dart';
import 'package:goal_master_admin/features/auth/presentation/manager/register_cubit/register_cubit.dart';
import 'package:goal_master_admin/features/auth/presentation/manager/verify_email_cubit/verify_email_cubit.dart';
import 'package:goal_master_admin/features/auth/presentation/view/forgot_password_view.dart';
import 'package:goal_master_admin/features/auth/presentation/view/login_view.dart';
import 'package:goal_master_admin/features/auth/presentation/view/new_password_view.dart';
import 'package:goal_master_admin/features/auth/presentation/view/otp_view.dart';
import 'package:goal_master_admin/features/auth/presentation/view/register_view.dart';
import 'package:goal_master_admin/features/home/presentation/view/home_view.dart';
import 'package:goal_master_admin/features/notification/presentation/view/notifaction_view.dart';
import 'package:goal_master_admin/features/onbording/presentation/manager/onboarding_cubit.dart';
import 'package:goal_master_admin/features/onbording/presentation/view/onboarding_view.dart'
    show OnboardingView;
import 'package:goal_master_admin/features/profail/presentation/view/change_password_view.dart';
import 'package:goal_master_admin/features/profail/presentation/view/profile_view.dart';
import 'package:goal_master_admin/features/profail/presentation/view/update_profile_view.dart';

import 'app_router.dart';

List<RouteBase> appRoutes = [
  //DashboardScreen
  GoRoute(
    parentNavigatorKey: parentKey,
    path: RoutesKeys.kHome,
    pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
      context: context,
      state: state,
      child: HomeView(),
    ),
  ),

  // StatefulShellRoute.indexedStack(
  //   builder: (context, state, navigationShell) {
  //     return MainNavigationBar(navigationShell: navigationShell);
  //   },
  //   branches: routesBranches,
  // ),
  // GoRoute(
  //   parentNavigatorKey: parentKey,
  //   path: RoutesKeys.kSplashView,
  //   pageBuilder:
  //       (context, state) => buildPageWithDefaultTransition<void>(
  //         context: context,
  //         state: state,
  //         child: const SplashView(),
  //       ),
  // ),
  GoRoute(
    parentNavigatorKey: parentKey,
    path: RoutesKeys.kOnboarding,
    pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
      context: context,
      state: state,
      child: BlocProvider(
        create: (context) => OnboardingCubit(),
        child: const OnboardingView(),
      ),
    ),
  ),
  // GoRoute(
  //   parentNavigatorKey: parentKey,
  //   path: RoutesKeys.kHome,
  //   pageBuilder:
  //       (context, state) => buildPageWithDefaultTransition<void>(
  //         context: context,
  //         state: state,
  //         child: const HomeView(),
  //       ),
  // ),
  // //kLogin
  GoRoute(
    parentNavigatorKey: parentKey,
    path: RoutesKeys.kLogin,
    pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
      context: context,
      state: state,
      child: BlocProvider(
        create: (context) => LoginCubit(getIt<AuthRepoImpl>()),
        child: const LoginView(),
      ),
    ),
  ),
  // //RegisterView
  GoRoute(
    parentNavigatorKey: parentKey,
    path: RoutesKeys.kRegister,
    pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
      context: context,
      state: state,
      child: BlocProvider(
        create: (context) => RegisterCubit(
          getIt<AuthRepoImpl>(),
        ),
        child: const RegisterView(),
      ),
    ),
  ),
  // //ForgotPasswordView
  GoRoute(
    parentNavigatorKey: parentKey,
    path: RoutesKeys.kForgotPassword,
    pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
      context: context,
      state: state,
      child: BlocProvider(
        create: (context) => VerifyEmailCubit(
          getIt<AuthRepoImpl>(),
          '',
          forget: true,
        ),
        child: const ForgotPasswordView(),
      ),
    ),
  ),
  // //OtpView
  GoRoute(
    parentNavigatorKey: parentKey,
    path: RoutesKeys.kOtp,
    pageBuilder: (context, state) {
      final Map<String, dynamic> extraData =
          state.extra as Map<String, dynamic>;
      final phone = extraData['phone'] as String;
      final forget = extraData['forget'] as bool;

      return buildPageWithDefaultTransition<void>(
        context: context,
        state: state,
        child: BlocProvider(
          create: (context) => VerifyEmailCubit(
            getIt<AuthRepoImpl>(),
            phone,
            forget: forget,
          ),
          child: const OtpView(),
        ),
      );
    },
  ),

  // //NewPasswordView
  GoRoute(
    parentNavigatorKey: parentKey,
    path: RoutesKeys.kNewPassword,
    pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
      context: context,
      state: state,
      child: const NewPasswordView(),
    ),
  ),
  // //ProfileView
  GoRoute(
    parentNavigatorKey: parentKey,
    path: RoutesKeys.kProfile,
    pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
      context: context,
      state: state,
      child: const ProfileView(),
    ),
  ),
  // //UpdateProfileView
  GoRoute(
    parentNavigatorKey: parentKey,
    path: RoutesKeys.kUpdateProfile,
    pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
      context: context,
      state: state,
      child: const UpdateProfileView(),
    ),
  ),
  //NotificationView
  GoRoute(
    parentNavigatorKey: parentKey,
    path: RoutesKeys.kNotification,
    pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
      context: context,
      state: state,
      child: const NotificationView(),
    ),
  ),
  //ChangePasswordView
  GoRoute(
    parentNavigatorKey: parentKey,
    path: RoutesKeys.kChangePassword,
    pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
      context: context,
      state: state,
      child: const ChangePasswordView(),
    ),
  ),
  // //ContactView
  // GoRoute(
  //   parentNavigatorKey: parentKey,
  //   path: RoutesKeys.kContact,
  //   pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
  //     context: context,
  //     state: state,
  //     child: const ContactView(),
  //   ),
  // ),
  // //BookingView
  // GoRoute(
  //   parentNavigatorKey: parentKey,
  //   path: RoutesKeys.kBooking,
  //   pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
  //     context: context,
  //     state: state,
  //     child: const BookingView(),
  //   ),
  // ),
  // GoRoute(
  //   parentNavigatorKey: parentKey,
  //   path: RoutesKeys.kHome,
  //   pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
  //     context: context,
  //     state: state,
  //     child: const HomeLayoutView(),
  //   ),
  // ),
];
