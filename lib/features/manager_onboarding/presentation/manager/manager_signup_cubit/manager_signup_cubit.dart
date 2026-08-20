import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:goal_master_admin/core/components/keys_values.dart';
import 'package:goal_master_admin/core/components/preference_utility.dart';
import 'package:goal_master_admin/features/auth/data/model/login_model/user.dart';
import 'package:goal_master_admin/features/manager_onboarding/data/model/manager_signup_request_model.dart';
import 'package:goal_master_admin/features/manager_onboarding/data/model/subscription_plan_option.dart';
import 'package:goal_master_admin/features/manager_onboarding/data/repo/manager_signup_repo.dart';
import 'package:goal_master_admin/utils/input_validator.dart';

part 'manager_signup_state.dart';

class ManagerSignupCubit extends Cubit<ManagerSignupState> {
  ManagerSignupCubit(this._repo) : super(ManagerSignupInitial());

  final ManagerSignupRepo _repo;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  Future<void> register({
    required SubscriptionPlanOption selectedPlan,
    required String billingCycle,
  }) async {
    final validationMessage = _validate();
    if (validationMessage != null) {
      emit(ManagerSignupError(validationMessage));
      return;
    }

    emit(ManagerSignupLoading());

    final request = ManagerSignupRequestModel(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      phoneNumber: phoneController.text.trim(),
      password: passwordController.text.trim(),
      passwordConfirmation: confirmPasswordController.text.trim(),
      subscriptionPlanId: selectedPlan.id,
      billingCycle: billingCycle,
    );

    final result = await _repo.registerManager(request);
    await result.fold(
      (failure) async => emit(ManagerSignupError(failure.errMessage)),
      (userData) async {
        await _saveUserData(userData);
        emit(ManagerSignupSuccess(userData));
      },
    );
  }

  String? _validate() {
    final nameError = InputValidator.validateName(
      nameController.text.trim(),
      minLength: 5,
      fieldName: 'Name',
    );
    if (nameError != null) return nameError;

    final emailError =
        InputValidator.validateEmail(emailController.text.trim());
    if (emailError != null) return emailError;

    final phoneError = InputValidator.validatePhoneNumber(
      phoneController.text.trim(),
    );
    if (phoneError != null) return phoneError;

    final passwordError = InputValidator.validatePassword(
      passwordController.text.trim(),
      minLength: 8,
    );
    if (passwordError != null) return passwordError;

    final confirmPasswordError = InputValidator.validateConfirmPassword(
      passwordController.text.trim(),
      confirmPasswordController.text.trim(),
    );
    if (confirmPasswordError != null) return confirmPasswordError;

    return null;
  }

  Future<void> _saveUserData(UserData userData) async {
    await SharedPreferenceUtil.getInstance();

    await SharedPreferenceUtil.putString(
      PrefKey.refreshToken,
      userData.token ?? '',
    );
    await SharedPreferenceUtil.putInt(PrefKey.userId, userData.user?.id);
    await SharedPreferenceUtil.putString(
      PrefKey.fcmToken,
      userData.token ?? '',
    );
    await SharedPreferenceUtil.putString(
      PrefKey.fullName,
      userData.user?.name ?? '',
    );
    await SharedPreferenceUtil.putString(
      PrefKey.email,
      userData.user?.username ?? '',
    );
    await SharedPreferenceUtil.putString(
      PrefKey.phone,
      userData.user?.phoneNumber ?? '',
    );
    await SharedPreferenceUtil.putString(PrefKey.login, 'true');
    await SharedPreferenceUtil.putInt(
      PrefKey.zoneId,
      userData.user?.zoneId ?? 0,
    );
    await SharedPreferenceUtil.putInt(
      PrefKey.clubId,
      userData.user?.clubId ?? 0,
    );
  }
}
