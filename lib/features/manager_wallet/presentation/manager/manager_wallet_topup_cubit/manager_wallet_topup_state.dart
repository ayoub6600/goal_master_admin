sealed class ManagerWalletTopUpState {
  const ManagerWalletTopUpState();
}

class ManagerWalletTopUpInitial extends ManagerWalletTopUpState {
  const ManagerWalletTopUpInitial();
}

class ManagerWalletTopUpLoading extends ManagerWalletTopUpState {
  const ManagerWalletTopUpLoading();
}

class ManagerWalletTopUpSuccess extends ManagerWalletTopUpState {
  final String message;

  const ManagerWalletTopUpSuccess(this.message);
}

class ManagerWalletTopUpFailure extends ManagerWalletTopUpState {
  final String message;

  const ManagerWalletTopUpFailure(this.message);
}
