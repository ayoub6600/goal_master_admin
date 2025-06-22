part of 'add_customer_cubit.dart';

abstract class AddCustomerState extends Equatable {
  const AddCustomerState();

  @override
  List<Object?> get props => [];
}

class AddCustomerInitial extends AddCustomerState {}

class AddCustomerLoading extends AddCustomerState {}

class AddCustomerSuccess extends AddCustomerState {
  final String customerId;

  const AddCustomerSuccess({required this.customerId});

  @override
  List<Object?> get props => [customerId];
}

class AddCustomerFailure extends AddCustomerState {
  final String message;

  const AddCustomerFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
