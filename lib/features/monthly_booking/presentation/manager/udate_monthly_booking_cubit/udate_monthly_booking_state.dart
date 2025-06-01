import 'package:equatable/equatable.dart';

abstract class UpdateMonthlyBookingState extends Equatable {
  @override
  List<Object> get props => [];
}

class UpdateMonthlyBookingInitial extends UpdateMonthlyBookingState {}

class UpdateMonthlyBookingLoading extends UpdateMonthlyBookingState {}

class UpdateMonthlyBookingSuccess extends UpdateMonthlyBookingState {
  final String message;

  UpdateMonthlyBookingSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class UpdateMonthlyBookingFailure extends UpdateMonthlyBookingState {
  final String error;

  UpdateMonthlyBookingFailure(this.error);

  @override
  List<Object> get props => [error];
}
