part of 'allowed_amount_cubit.dart';

abstract class AllowedAmountState {}

class AllowedAmountInitial extends AllowedAmountState {}

class AllowedAmountLoaded extends AllowedAmountState {
  final PagingController<int, AllowedAmountData> pagingController;

  AllowedAmountLoaded({required this.pagingController});
}

class AllowedAmountError extends AllowedAmountState {
  final String message;

  AllowedAmountError(this.message);
}
