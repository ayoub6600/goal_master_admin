class ManagerSignupRequestModel {
  final String name;
  final String email;
  final String phoneNumber;
  final String password;
  final String passwordConfirmation;
  final int subscriptionPlanId;
  final String billingCycle;

  const ManagerSignupRequestModel({
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.passwordConfirmation,
    required this.subscriptionPlanId,
    required this.billingCycle,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'subscription_plan_id': subscriptionPlanId,
      'billing_cycle': billingCycle,
    };
  }
}
