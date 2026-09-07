import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

import 'package:goal_master_admin/features/auth/data/repo/auth_repo_imp.dart';
import 'package:goal_master_admin/features/booking/data/repo/booking_repo.dart';
import 'package:goal_master_admin/features/booking/data/repo/booking_repo_imp.dart';
import 'package:goal_master_admin/features/home/data/repo/analysis_repo_imp.dart';
import 'package:goal_master_admin/features/monthly_booking/data/repo/monthly_booking_repo_imp.dart';
import 'package:goal_master_admin/features/manager_onboarding/data/repo/manager_signup_repo_imp.dart';
import 'package:goal_master_admin/features/manager_setup/data/repo/manager_setup_repo_imp.dart';
import 'package:goal_master_admin/features/manager_wallet/data/repo/manager_wallet_repo_imp.dart';
import 'package:goal_master_admin/features/manager_cancellation_policy/data/repo/manager_cancellation_policy_repo_imp.dart';
import 'package:goal_master_admin/features/manager_subscription/data/repo/manager_subscription_repo_imp.dart';
import 'package:goal_master_admin/features/notification/data/repo/notifaction_repo.dart';
import 'package:goal_master_admin/features/notification/data/repo/notifaction_repo_imp.dart';
import 'package:goal_master_admin/features/profail/data/repo/profile_repo_imp.dart';
import '../databases/api/dio_consumer.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerSingleton<Dio>(Dio());
  getIt.registerSingleton<DioConsumer>(DioConsumer(dio: getIt<Dio>()));

  getIt.registerSingleton<AuthRepoImpl>(
    AuthRepoImpl(getIt.get<DioConsumer>()),
  );
  getIt.registerSingleton<ProfileRepoImp>(
    ProfileRepoImp(getIt.get<DioConsumer>()),
  );
  getIt.registerSingleton<BookingRepoImp>(
    BookingRepoImp(getIt.get<DioConsumer>()),
  );
  getIt.registerSingleton<AnalysisRepoImp>(
    AnalysisRepoImp(getIt.get<DioConsumer>()),
  );
  //MonthlyBookingRepoImp
  getIt.registerSingleton<MonthlyBookingRepoImp>(
    MonthlyBookingRepoImp(getIt.get<DioConsumer>()),
  );
  getIt.registerSingleton<ManagerSignupRepoImp>(
    ManagerSignupRepoImp(getIt.get<DioConsumer>()),
  );
  getIt.registerSingleton<ManagerSetupRepoImp>(
    ManagerSetupRepoImp(getIt.get<DioConsumer>()),
  );
  getIt.registerSingleton<ManagerWalletRepoImp>(
    ManagerWalletRepoImp(getIt.get<DioConsumer>()),
  );
  getIt.registerSingleton<ManagerCancellationPolicyRepoImp>(
    ManagerCancellationPolicyRepoImp(getIt.get<DioConsumer>()),
  );
  getIt.registerSingleton<ManagerSubscriptionRepoImp>(
    ManagerSubscriptionRepoImp(getIt.get<DioConsumer>()),
  );
  //NotificationRepo
  getIt.registerSingleton<NotificationRepo>(
    NotificationRepoImp(getIt.get<DioConsumer>()),
  );
  getIt.registerSingleton<BookingRepo>(getIt<BookingRepoImp>());

  // //CardRepoImp
  // getIt.registerSingleton<CardRepoImp>(
  //   CardRepoImp(getIt.get<DioConsumer>()),
  // );
  // //BalanceRepoImp
  // getIt.registerSingleton<BalanceRepoImp>(
  //   BalanceRepoImp(getIt.get<DioConsumer>()),
  // );
}
