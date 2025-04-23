// customer_state.dart
part of 'customer_cubit.dart';

abstract class CustomerState {}

class CustomerInitial extends CustomerState {}

class CustomerLoading extends CustomerState {}

class CustomerLoaded extends CustomerState {
  final PagingController<int, Customer> pagingController;

  CustomerLoaded({
    required this.pagingController,
  });
  @override
  List<Object> get props => [pagingController];
}

class CustomerError extends CustomerState {
  final String message;
  CustomerError(this.message);
}
