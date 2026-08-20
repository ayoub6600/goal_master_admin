part of 'manager_wallet_card_cubit.dart';

sealed class ManagerWalletCardState {}

final class ManagerWalletCardInitial extends ManagerWalletCardState {}

final class ManagerWalletCardLoading extends ManagerWalletCardState {}

final class ManagerWalletCardSuccess extends ManagerWalletCardState {
  ManagerWalletCardSuccess(this.message);

  final String message;
}

final class ManagerWalletCardFailure extends ManagerWalletCardState {
  ManagerWalletCardFailure(this.message);

  final String message;
}
