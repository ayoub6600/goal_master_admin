part of 'booking_cubit.dart';

abstract class BookingStateNew extends Equatable {
  const BookingStateNew();

  @override
  List<Object> get props => [];
}

class BookingInitial extends BookingStateNew {}

// class BookingSuccess extends BookingStateNew {
//   final PagingController<int, Booking> pagingController;

//   BookingSuccess({
//     required this.pagingController,
//   });

//   @override
//   List<Object> get props => [pagingController];
// }
final class BookingSuccess extends BookingStateNew {
  final PagingController<int, BookingItemResponce> pagingController;

  const BookingSuccess({
    required this.pagingController,
  });
  @override
  List<Object> get props => [pagingController];
}

class BookingFailure extends BookingStateNew {
  final String message;

  BookingFailure({
    required this.message,
  });

  @override
  List<Object> get props => [message];
}
