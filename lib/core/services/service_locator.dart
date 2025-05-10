import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

import 'package:goal_master_admin/features/auth/data/repo/auth_repo_imp.dart';
import 'package:goal_master_admin/features/booking/data/repo/booking_repo_imp.dart';
import 'package:goal_master_admin/features/home/data/repo/analysis_repo_imp.dart';
import 'package:goal_master_admin/features/monthly_booking/data/repo/monthly_booking_repo_imp.dart';
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

  // //CardRepoImp
  // getIt.registerSingleton<CardRepoImp>(
  //   CardRepoImp(getIt.get<DioConsumer>()),
  // );
  // //BalanceRepoImp
  // getIt.registerSingleton<BalanceRepoImp>(
  //   BalanceRepoImp(getIt.get<DioConsumer>()),
  // );
}
