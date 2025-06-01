import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goal_master_admin/core/components/build_page_with_default_transition.dart';
import 'package:goal_master_admin/core/routing/routes_keys.dart';

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
import 'package:goal_master_admin/features/booking/data/repo/booking_repo_imp.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/%20booking_details_cubit/booking_details_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/add_booking_cubit/add_booking_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/booking_cubit/booking_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/booking_deposit_cubit/booking_deposit_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/calendar_cubit/calendar_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/cancel_booking_cubit/cancel_booking_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/category_cubit/category_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/employee_cubit/employee_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/page_view_cubit/page_view_cubit_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/service_cubit/service_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/update_booking_status_cubit/update_booking_status_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/zone_cubit/zone_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/view/add_booking.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/booking_items_details.dart.dart';
import 'package:goal_master_admin/features/home/data/model/booking_slots_response.dart';
import 'package:goal_master_admin/features/home/data/repo/analysis_repo_imp.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/club_cubit/club_cubit.dart';
import 'package:goal_master_admin/features/home/presentation/manager/analysis_cubit/analysis_cubit.dart';
import 'package:goal_master_admin/features/home/presentation/manager/filter_cubit/filter_cubit.dart';
import 'package:goal_master_admin/features/home/presentation/manager/page_view_new_booking_cubit/page_view_new_booking_cubit.dart';
import 'package:goal_master_admin/features/home/presentation/view/fillter_view.dart';
import 'package:goal_master_admin/features/home/presentation/view/home_view.dart';
import 'package:goal_master_admin/features/home/presentation/view/widgets/booking_item.dart';
import 'package:goal_master_admin/features/home/presentation/view/widgets/show_all_resulat_filtter.dart';
import 'package:goal_master_admin/features/layout/presentation/view/home_layout_view.dart';
import 'package:goal_master_admin/features/monthly_booking/data/repo/monthly_booking_repo_imp.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/manager/monthly_booking_cubit/monthly_booking_cubit.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/manager/udate_monthly_booking_cubit/udate_monthly_booking_cubit.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/view/monthly_booking.dart';
import 'package:goal_master_admin/features/notification/data/repo/notifaction_repo.dart';
import 'package:goal_master_admin/features/notification/manager/notification_cubit/notification_cubit.dart';
import 'package:goal_master_admin/features/notification/presentation/view/notifaction_view.dart';
import 'package:goal_master_admin/features/onbording/presentation/manager/onboarding_cubit.dart';
import 'package:goal_master_admin/features/onbording/presentation/view/onboarding_view.dart';
import 'package:goal_master_admin/features/profail/data/model/customer_list_response.dart';

import 'package:goal_master_admin/features/profail/data/repo/profile_repo_imp.dart';
import 'package:goal_master_admin/features/profail/presentation/manager/allowed_amount_cubit/allowed_amount_cubit.dart';
import 'package:goal_master_admin/features/profail/presentation/manager/customer_cubit/customer_cubit.dart';
import 'package:goal_master_admin/features/profail/presentation/manager/reset_password_cubit/reset_password_cubit.dart';
import 'package:goal_master_admin/features/profail/presentation/manager/update_profile_cubit/update_profile_cubit.dart';
import 'package:goal_master_admin/features/profail/presentation/view/change_password_view.dart';
import 'package:goal_master_admin/features/profail/presentation/view/customer_view.dart';
import 'package:goal_master_admin/features/profail/presentation/view/profile_view.dart';
import 'package:goal_master_admin/features/profail/presentation/view/update_profile_view.dart';
import 'package:goal_master_admin/features/profail/presentation/view/widgets/items_user_call.dart';
import 'package:goal_master_admin/features/profail/presentation/view/widgets/items_user_detains_view.dart';

import '../../features/profail/presentation/view/allowed_amount_view.dart';
import 'app_router.dart';

List<RouteBase> appRoutes = [
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
  GoRoute(
    path: RoutesKeys.kHome,
    builder: (context, state) => const HomeLayoutView(),
  ),
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
  //AllowedAmountView
  GoRoute(
    parentNavigatorKey: parentKey,
    path: RoutesKeys.kAllowedAmount,
    pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
      context: context,
      state: state,
      child: BlocProvider(
        create: (context) => AllowedAmountCubit(
          repo: getIt<ProfileRepoImp>(),
        ),
        child: const AllowedAmountView(),
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
  GoRoute(
    parentNavigatorKey: parentKey,
    path: RoutesKeys.kUpdateProfile,
    pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
      context: context,
      state: state,
      child: BlocProvider(
        create: (context) => UpdateProfileCubit(
          getIt<ProfileRepoImp>(),
        ),
        child: const UpdateProfileView(),
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
  //kItemsUserDetainsView
  GoRoute(
    parentNavigatorKey: parentKey,
    path: RoutesKeys.kItemsUserDetainsView,
    pageBuilder: (context, state) {
      final data = state.extra as Map<String, dynamic>;
      final bookingId = data['bookingId'] as String;
      final customer = data['customer'] as Customer; // النوع اللي انت شغال بيه

      return buildPageWithDefaultTransition<void>(
        context: context,
        state: state,
        child: BlocProvider(
          create: (context) {
            final cubit = BookingCubit(getIt<BookingRepoImp>());
            cubit.updateCustomerId(bookingId);
            cubit.filterBooking();
            return cubit;
          },
          child: ItemsUserDetainsView(
            customer: customer,
          ),
        ),
      );
    },
  ),

  //kBookingItemsDetails
  GoRoute(
    parentNavigatorKey: parentKey,
    path: RoutesKeys.kBookingItemsDetails,
    pageBuilder: (context, state) {
      final bookingId = state.extra as int;

      return buildPageWithDefaultTransition<void>(
        context: context,
        state: state,
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => BookingDetailsCubit(
                getIt<BookingRepoImp>(),
                bookingId,
              )..getBookingInfo(),
            ),
            BlocProvider(
              create: (context) => CancelBookingCubit(
                getIt<BookingRepoImp>(),
              ),
            ),
            //UpdateBookingStatusCubit
            BlocProvider(
              create: (context) => UpdateBookingStatusCubit(
                getIt<BookingRepoImp>(),
              ),
            ),
            //BookingDepositCubit
            BlocProvider(
              create: (context) => BookingDepositCubit(
                bookingRepo: getIt<BookingRepoImp>(),
                bookingId,
              ),
            ),
          ],
          child: BookingItemsDetails(),
        ),
      );
    },
  ),

  // GoRoute(
  //   parentNavigatorKey: parentKey,
  //   path: RoutesKeys.kHome,
  //   pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
  //     context: context,
  //     state: state,
  //     child: const HomeLayoutView(),
  //   ),
  // ),

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
//CustomerView
  GoRoute(
    parentNavigatorKey: parentKey,
    path: RoutesKeys.kCustomerView,
    pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
      context: context,
      state: state,
      child: BlocProvider(
        create: (context) => CustomerCubit(
          bookingRepo: getIt<ProfileRepoImp>(),
        ),
        child: const CustomerView(),
      ),
    ),
  ),
  //NotificationView
  GoRoute(
    parentNavigatorKey: parentKey,
    path: RoutesKeys.kNotification,
    pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
      context: context,
      state: state,
      child: BlocProvider(
        create: (context) => NotificationCubit(
          notificationRepo: getIt<NotificationRepo>(),
        ),
        child: const NotificationView(),
      ),
    ),
  ),
  //ChangePasswordView
  GoRoute(
    parentNavigatorKey: parentKey,
    path: RoutesKeys.kChangePassword,
    pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
      context: context,
      state: state,
      child: BlocProvider(
        create: (context) => ResetPasswordCubit(
          getIt<ProfileRepoImp>(),
        ),
        child: const ChangePasswordView(),
      ),
    ),
  ),
  GoRoute(
    parentNavigatorKey: parentKey,
    path: RoutesKeys.kFilter,
    pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
      context: context,
      state: state,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => ZoneCubitCubit(
              getIt<BookingRepoImp>(),
            )..listZone(),
          ),
          //ClubCubit
          BlocProvider(
              create: (context) => ClubCubit(
                    getIt<BookingRepoImp>(),
                  )),
          //CategoryCubit
          BlocProvider(
              create: (context) => CategoryCubit(
                    getIt<BookingRepoImp>(),
                  )),
          //FilterCubit
          BlocProvider(
            create: (context) => FilterCubit(
              getIt<AnalysisRepoImp>(),
            ),
          ),
        ],
        child: const FilterView(),
      ),
    ),
  ),
  //AddNewBooking
  GoRoute(
    parentNavigatorKey: parentKey,
    path: RoutesKeys.kAddNewBooking,
    pageBuilder: (context, state) {
      final booking = state.extra as BookingSlot;

      return buildPageWithDefaultTransition<void>(
        context: context,
        state: state,
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => EmployeeCubit(getIt<BookingRepoImp>()),
            ),
            BlocProvider(
              create: (context) => AddBookingCubit(getIt<BookingRepoImp>()),
            ),
            BlocProvider(
              create: (context) => PageViewNewBookingCubit(),
            ),
          ],
          child: AddNewBooking(booking: booking), // ✅ pass the booking here
        ),
      );
    },
  ),

  GoRoute(
    parentNavigatorKey: parentKey,
    path: RoutesKeys.kAddBooking,
    pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
      context: context,
      state: state,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => ZoneCubitCubit(
              getIt<BookingRepoImp>(),
            )..listZone(),
          ),
          //ClubCubit
          BlocProvider(
              create: (context) => ClubCubit(
                    getIt<BookingRepoImp>(),
                  )),
          //CategoryCubit
          BlocProvider(
              create: (context) => CategoryCubit(
                    getIt<BookingRepoImp>(),
                  )),
          //ServiceCubit
          BlocProvider(
              create: (context) => ServiceCubit(
                    getIt<BookingRepoImp>(),
                  )),
          //EmployeeCubit
          BlocProvider(
            create: (context) => EmployeeCubit(
              getIt<BookingRepoImp>(),
            ),
          ),
          //AddBookingCubit
          BlocProvider(
            create: (context) => AddBookingCubit(
              getIt<BookingRepoImp>(),
            ),
          ),
          BlocProvider(
            create: (context) => CalendarCubit(
              getIt<BookingRepoImp>(),
            ),
          ),
          BlocProvider(
            create: (context) => PageViewCubit(),
          ),
        ],
        child: const AddBookingView(),
      ),
    ),
  ),

  GoRoute(
    parentNavigatorKey: parentKey,
    path: RoutesKeys.kShowAllResulatFiltter,
    pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
      context: context,
      state: state,
      child: BlocProvider(
        create: (context) => FilterCubit(
          getIt<AnalysisRepoImp>(),
        ),
        child: ShowAllResulatFiltter(),
      ),
    ),
  ),
  //kMonthlyBookingView
  GoRoute(
    parentNavigatorKey: parentKey,
    path: RoutesKeys.kMonthlyBookingView,
    pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
      context: context,
      state: state,
      child: MultiBlocProvider(
        providers: [
          //UpdateMonthlyBooking
          BlocProvider(
            create: (context) => UpdateMonthlyBooking(
              getIt<MonthlyBookingRepoImp>(),
            ),
          ),
          //MonthlyBookingCubit
          BlocProvider(
            create: (context) => MonthlyBookingCubit(
              bookingRepo: getIt<MonthlyBookingRepoImp>(),
            ),
          ),
        ],
        child: const MonthlyBookingView(),
      ),
    ),
  )
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
