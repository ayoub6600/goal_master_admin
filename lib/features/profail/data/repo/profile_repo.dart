import 'package:dartz/dartz.dart';

import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:goal_master_admin/features/auth/data/model/login_model/user.dart';
import 'package:goal_master_admin/features/profail/data/model/allowed_amount_response.dart';
import 'package:goal_master_admin/features/profail/data/model/customer_list_response.dart';

abstract class ProfileRepo {
  Future<Either<Failure, User>> getProfile();
  Future<Either<Failure, CustomerData>> getCustomer(
    int page,
  );
  Future<Either<Failure, AllowedAmountResponse>> getAllowedAmount(
    int page,
  );
  Future<Either<Failure, UserData>> resetPassword({
    required String oldPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  });
  Future<Either<Failure, UserData>> updateProfile({
    required String name,
    required String username,
    required String phone,
  });

  ///user/booking/updateMonthlyBooking
  Future<Either<Failure, String>> updateMonthlyBooking({
    required String serviceDate,
    required String id,
  });
}
