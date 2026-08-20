import 'package:goal_master_admin/features/manager_wallet/data/model/manager_wallet_response.dart';

sealed class ManagerWalletState {
  const ManagerWalletState();
}

class ManagerWalletInitial extends ManagerWalletState {
  const ManagerWalletInitial();
}

class ManagerWalletLoading extends ManagerWalletState {
  const ManagerWalletLoading();
}

class ManagerWalletLoaded extends ManagerWalletState {
  final WalletData data;

  const ManagerWalletLoaded(this.data);
}

class ManagerWalletFailure extends ManagerWalletState {
  final String message;

  const ManagerWalletFailure(this.message);
}
