part of 'booking_deposit_cubit.dart';

@immutable
abstract class BookingDepositState {}

class BookingDepositInitial extends BookingDepositState {}

class BookingDepositLoading extends BookingDepositState {}

class BookingDepositSuccess extends BookingDepositState {
  final BookingDetails bookingDetails;

  BookingDepositSuccess(this.bookingDetails);
}

class BookingDepositError extends BookingDepositState {
  final String message;

  BookingDepositError(this.message);
}
