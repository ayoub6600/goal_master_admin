import 'package:equatable/equatable.dart';
import 'package:goal_master_admin/features/booking/data/model/booking_details.dart';

abstract class BookingDetailsState extends Equatable {
  const BookingDetailsState();

  @override
  List<Object?> get props => [];
}

class BookingDetailsInitial extends BookingDetailsState {}

class BookingDetailsLoading extends BookingDetailsState {}

class BookingDetailsSuccess extends BookingDetailsState {
  final BookingDetails bookingDetails;

  const BookingDetailsSuccess(this.bookingDetails);

  @override
  List<Object?> get props => [bookingDetails];
}

class BookingDetailsError extends BookingDetailsState {
  final String message;

  const BookingDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}
