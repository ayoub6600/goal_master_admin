import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:goal_master_admin/features/booking/data/model/booking_details.dart';
import 'package:goal_master_admin/features/booking/data/repo/booking_repo.dart';
import 'package:meta/meta.dart';

part 'booking_deposit_state.dart';

class BookingDepositCubit extends Cubit<BookingDepositState> {
  final BookingRepo bookingRepo;
  final int bookingId;

  BookingDepositCubit(this.bookingId, {required this.bookingRepo})
      : super(BookingDepositInitial());

  Future<void> depositBookingPayment({
    required String due,
    required String paymentStatus,
    required String extraInput,
  }) async {
    emit(BookingDepositLoading());

    final result = await bookingRepo.depositBookingPayment(
      bookingId,
      due,
      paymentStatus,
      extraInput,
    );

    result.fold(
      (failure) {
        emit(BookingDepositError(failure.errMessage));
      },
      (bookingDetails) {
        emit(BookingDepositSuccess(bookingDetails));
      },
    );
  }
}
