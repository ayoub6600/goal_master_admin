part of 'monthly_booking_cubit.dart';

abstract class MonthlyBookingState {}

class MonthlyBookingInitial extends MonthlyBookingState {}

class MonthlyBookingLoaded extends MonthlyBookingState {
  final PagingController<int, MonthlyBookingResponse> pagingController;

  MonthlyBookingLoaded({required this.pagingController});
}

class MonthlyBookingError extends MonthlyBookingState {
  final String message;

  MonthlyBookingError(this.message);
}
