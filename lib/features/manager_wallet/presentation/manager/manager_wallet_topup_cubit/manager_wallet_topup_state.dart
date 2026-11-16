import 'package:goal_master_admin/features/manager_wallet/data/model/topup_checkout.dart';

sealed class ManagerWalletTopUpState {
  const ManagerWalletTopUpState();
}

class ManagerWalletTopUpInitial extends ManagerWalletTopUpState {
  const ManagerWalletTopUpInitial();
}

class ManagerWalletTopUpLoading extends ManagerWalletTopUpState {
  const ManagerWalletTopUpLoading();
}

/// The server opened and signed the checkout; the Lightbox can be shown.
class ManagerWalletTopUpReady extends ManagerWalletTopUpState {
  final TopUpCheckout checkout;

  const ManagerWalletTopUpReady(this.checkout);
}

class ManagerWalletTopUpSuccess extends ManagerWalletTopUpState {
  final String message;

  const ManagerWalletTopUpSuccess(this.message);
}

/// Paid, but the bank has not confirmed it yet. The server keeps checking and
/// credits the wallet on its own — the manager must not pay again.
class ManagerWalletTopUpPending extends ManagerWalletTopUpState {
  final String message;

  const ManagerWalletTopUpPending(this.message);
}

class ManagerWalletTopUpFailure extends ManagerWalletTopUpState {
  final String message;

  const ManagerWalletTopUpFailure(this.message);
}
