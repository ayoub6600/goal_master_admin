import 'package:dartz/dartz.dart';
import 'package:goal_master_admin/core/components/keys_values.dart';
import 'package:goal_master_admin/core/components/preference_utility.dart';
import 'package:goal_master_admin/core/databases/api/api_consumer.dart';
import 'package:goal_master_admin/core/databases/api/api_consumer_extension.dart';
import 'package:goal_master_admin/core/databases/api/end_points.dart';
import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:goal_master_admin/features/profail/data/model/allowed_amount_response.dart';
import 'package:goal_master_admin/features/profail/data/model/customer_list_response.dart';
import 'package:goal_master_admin/features/profail/data/repo/profile_repo.dart';
import 'package:goal_master_admin/features/auth/data/model/login_model/user.dart';

class ProfileRepoImp extends ProfileRepo {
  final ApiConsumer consumer;

  ProfileRepoImp(this.consumer);

  void _storeSubscriptionPrefs(User? user) {
    if (user == null) return;
    SharedPreferenceUtil.putString(
      PrefKey.subscriptionPlanName,
      user.currentSubscription?.planName ?? '',
    );
    SharedPreferenceUtil.putString(
      PrefKey.subscriptionPlanCode,
      user.currentSubscription?.planCode ?? '',
    );
    SharedPreferenceUtil.putBool(
      PrefKey.subscriptionAllowMonthlyBookings,
      user.canUseMonthlyBookings,
    );
    SharedPreferenceUtil.putBool(
      PrefKey.subscriptionAllowReports,
      user.canUseReports,
    );
    SharedPreferenceUtil.putBool(
      PrefKey.subscriptionAllowWebAccess,
      user.canUseWebAccess,
    );
  }

  @override
  Future<Either<Failure, User>> getProfile() {
    return consumer.handleRequest(
      () => consumer.get(EndPoints.profile),
      (res) {
        var data = res['data']["user"];
        var user = User.fromJson(data);
        _storeSubscriptionPrefs(user);
        return user;
      },
    );
  }

  @override
  Future<Either<Failure, CustomerData>> searchCustomers({
    required String search,
  }) {
    return consumer.handleRequest(
      () => consumer.get(
        "manager/returnCustomers",
        queryParameters: {"search": search},
      ),
      (res) => CustomerData.fromList(res),
    );
  }

  @override
  Future<Either<Failure, CustomerData>> getCustomer(
    int page, {
    String? search,
  }) {
    final query = {
      "page": page,
      if (search != null && search.isNotEmpty) "search": search,
    };

    return consumer.handleRequest(
      () => consumer.get(
        EndPoints.listCustomer,
        queryParameters: query,
      ),
      (res) => CustomerData.fromJson(res['data']),
    );
  }

  @override
  Future<Either<Failure, UserData>> resetPassword({
    required String oldPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) {
    return consumer.handleRequest(
      () => consumer.post(
        EndPoints.changePasswordUser,
        data: {
          'password_confirmation': newPasswordConfirmation,
          'password': newPassword,
          "old_password": oldPassword
        },
        isFormData: false,
      ),
      (data) {
        print("token: ${data["data"]["token"]}");
        return UserData.fromJson(data["data"]);
      },
    );
  }

  @override
  Future<Either<Failure, UserData>> updateProfile({
    required String name,
    required String username,
    required String phone,
  }) {
    return consumer.handleRequest(
      () => consumer.post(
        EndPoints.update,
        isFormData: false,
        data: {'name': name, 'username': username, 'phone_number': phone},
      ),
      (data) {
        print("token: ${data["data"]["token"]}");
        return UserData.fromJson(data["data"]);
      },
    );
  }

  @override
  Future<Either<Failure, AllowedAmountResponse>> getAllowedAmount(
    int page,
  ) {
    return consumer.handleRequest(
      () => consumer.get(EndPoints.getForgivingGenerous(page)),
      (res) {
        return AllowedAmountResponse.fromJson(res);
      },
    );
  }

  @override
  Future<Either<Failure, String>> updateMonthlyBooking(
      {required String serviceDate, required String id}) {
    return consumer.handleRequest(
      () => consumer.post(
        EndPoints.updateMonthlyBooking,
        isFormData: false,
        data: {'service_date': serviceDate, 'id': id},
      ),
      (data) {
        return data["message"];
      },
    );
  }
}
