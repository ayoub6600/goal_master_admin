import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goal_master_admin/core/components/keys_values.dart';
import 'package:goal_master_admin/core/components/preference_utility.dart';
import 'package:goal_master_admin/core/services/push_notification_service.dart';
import 'package:goal_master_admin/features/auth/data/model/login_model/user.dart';
import 'package:goal_master_admin/features/auth/data/repo/auth_repo.dart';
import 'package:goal_master_admin/utils/input_validator.dart';
part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._repo) : super(LoginInitial());

  final AuthRepo _repo;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  Future<void> login() async {
    emit(LoginLoading());
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    var isValid = _validate(email, password);
    if (!isValid) return;

    var result = await _repo.login(email: email, password: password);
    await result.fold(
      (error) async {
        emit(LoginError(error.errMessage));
      },
      (user) async {
        // Role-authoritative — see User.isManager. A dual-role account (a
        // customer also made a manager) keeps userType == 2 (WebsiteUser)
        // forever by design, so checking userType == 1 here rejected every
        // such login even though the backend authenticated it successfully.
        if (user.user?.isManager == true) {
          await _saveUserData(user);
          emit(LoginSuccess());
        } else {
          emit(LoginError(" لا يمكن تسجيل الدخول بتلك البيانات"));
        }
      },
    );
  }

  Future<void> _saveUserData(UserData userData) async {
    print("---->UserData token ${userData.token}");

    try {
      // تأكد من أن SharedPreferences جاهز
      await SharedPreferenceUtil.getInstance();

      await SharedPreferenceUtil.putString(
          PrefKey.refreshToken, userData.token ?? "");
      //userid
      await SharedPreferenceUtil.putInt(PrefKey.userId, userData.user?.id);

      await SharedPreferenceUtil.putString(
          PrefKey.fcmToken, userData.token ?? "");
      await SharedPreferenceUtil.putString(
          PrefKey.fullName, userData.user?.name ?? "");
      await SharedPreferenceUtil.putString(
          PrefKey.email, userData.user?.username ?? "");
      await SharedPreferenceUtil.putString(
          PrefKey.phone, userData.user?.phoneNumber ?? "");

      // حفظ حالة تسجيل الدخول
      await SharedPreferenceUtil.putString(PrefKey.login, "true");
      PushNotificationService.registerTokenIfLoggedIn();

      await SharedPreferenceUtil.putInt(
          PrefKey.zoneId, userData.user?.zoneId ?? 0);
      await SharedPreferenceUtil.putInt(
          PrefKey.clubId, userData.user?.clubId ?? 0);

      print("---->User data saved successfully");
      print("---->userId: ${userData.user?.id}");
      print("---->login: true");
    } catch (e) {
      print("---->Error saving user data: $e");
    }
  }

  bool _validate(String name, String password) {
    String? nameError = InputValidator.validateName(name);
    if (nameError != null) {
      emit(LoginError(nameError));
      return false;
    }
    String? passwordError = InputValidator.validatePassword(password);
    if (passwordError != null) {
      emit(LoginError(passwordError));
      return false;
    }
    return true;
  }
}

Future<void> wait() async {
  await Future.delayed(Duration(seconds: 2));
}
