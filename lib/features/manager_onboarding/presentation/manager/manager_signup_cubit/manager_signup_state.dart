part of 'manager_signup_cubit.dart';

sealed class ManagerSignupState {}

final class ManagerSignupInitial extends ManagerSignupState {}

final class ManagerSignupLoading extends ManagerSignupState {}

final class ManagerSignupSuccess extends ManagerSignupState {
  final UserData userData;

  ManagerSignupSuccess(this.userData);
}

final class ManagerSignupError extends ManagerSignupState {
  final String message;

  ManagerSignupError(this.message);
}
