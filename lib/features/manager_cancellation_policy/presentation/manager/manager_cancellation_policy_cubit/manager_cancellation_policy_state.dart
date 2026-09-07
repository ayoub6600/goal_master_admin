import 'package:goal_master_admin/features/manager_cancellation_policy/data/model/manager_cancellation_policy_response.dart';

sealed class ManagerCancellationPolicyState {
  const ManagerCancellationPolicyState();
}

class ManagerCancellationPolicyInitial extends ManagerCancellationPolicyState {
  const ManagerCancellationPolicyInitial();
}

class ManagerCancellationPolicyLoading extends ManagerCancellationPolicyState {
  const ManagerCancellationPolicyLoading();
}

class ManagerCancellationPolicyLoaded extends ManagerCancellationPolicyState {
  final ManagerCancellationPolicyData data;

  const ManagerCancellationPolicyLoaded(this.data);
}

class ManagerCancellationPolicyFailure extends ManagerCancellationPolicyState {
  final String message;

  const ManagerCancellationPolicyFailure(this.message);
}
