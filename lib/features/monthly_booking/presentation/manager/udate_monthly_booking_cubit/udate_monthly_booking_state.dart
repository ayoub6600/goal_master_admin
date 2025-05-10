import 'package:equatable/equatable.dart';

abstract class UpdateMonthlyBookingState extends Equatable {
  @override
  List<Object> get props => [];
}

class MonthlyBookingInitial extends UpdateMonthlyBookingState {}

class MonthlyBookingLoading extends UpdateMonthlyBookingState {}

class MonthlyBookingSuccess extends UpdateMonthlyBookingState {
  final String message;

  MonthlyBookingSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class MonthlyBookingFailure extends UpdateMonthlyBookingState {
  final String error;

  MonthlyBookingFailure(this.error);

  @override
  List<Object> get props => [error];
}
