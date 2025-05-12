part of 'update_booking_status_cubit.dart';

abstract class UpdateBookingStatusState extends Equatable {
  const UpdateBookingStatusState();

  @override
  List<Object?> get props => [];
}

class UpdateBookingStatusInitial extends UpdateBookingStatusState {}

class UpdateBookingStatusLoading extends UpdateBookingStatusState {}

class UpdateBookingStatusChanged extends UpdateBookingStatusState {}

class UpdateBookingStatusSuccess extends UpdateBookingStatusState {
  final String message;

  const UpdateBookingStatusSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class UpdateBookingStatusError extends UpdateBookingStatusState {
  final String message;

  const UpdateBookingStatusError(this.message);

  @override
  List<Object?> get props => [message];
}
